//
//  SingboxHelper.swift
//  OpenLink
//
//  Created by eleven on 2026/2/7.
//

import Libbox
import Library
import NetworkExtension

class SingboxHelper {
    static let shared = SingboxHelper()
    private var expf: ExtensionProfile? = nil
    
    func startConnect(_ node: NodeModel) async throws -> Bool {
//        guard !UserDefaults.standard.bool(forKey: UserDefaultsKeys.VPNPermission) else {
            return try await startConnectNext(node)
//        }
        
        // 等待弹窗用户确认
//        let confirmed = await withCheckedContinuation { continuation in
//            final class State: @unchecked Sendable { var isResumed = false }
//            let state = State()
//            
//            DispatchQueue.main.async {
//                PopupManager.shared.show(
//                    .vpnPermissionPopupView {
//                        // 防止多次点击导致多次 resume
//                        guard !state.isResumed else { return }
//                        state.isResumed = true
//                        
//                        // 用户点击「知道了」时
//                        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.VPNPermission)
//                        PopupManager.shared.dismiss()
//                        continuation.resume(returning: true)
//                    })
//            }
//        }
//
//        if confirmed {
//            return try await startConnectNext(node)
//        } else {
//            return false
//        }
    }
    
    private func startConnectNext(_ node: NodeModel) async throws -> Bool {
        do {
            // VPN配置
            guard let jsonx = try await configData(node) else {
                return false
            }

            try await ExtensionProfile.install()
            try await Profile.save(jsonx: jsonx)
            if expf == nil {
                expf = try await ExtensionProfile.load()
            }
            try await expf?.start()
            return true
        } catch {
            olog(error.localizedDescription)
            return false
        }
    }
    
    func stopConnect() async throws {
        if expf == nil {
            expf = try await ExtensionProfile.load()
        }

        do {
            try await expf?.stop()
        } catch {
            olog(error.localizedDescription)
        }
    }
    
    private func configData(_ node: NodeModel) async throws -> String? {
        do {
            var cfgD = try await Task.detached(priority: .userInitiated) {
                try self.fetchConfig()
            }.value

            guard var outbounds = cfgD["outbounds"] as? [[String: Any]],
                !outbounds.isEmpty
            else {
                throw NSError(domain: "configError", code: 1, userInfo: [NSLocalizedDescriptionKey: "配置格式错误"])
            }
            
            // 根据 node.request_address 获得 server port uuid 及其他参数
            guard let requestAddress = node.requestAddress,
                  let url = URL(string: requestAddress),
                  let uuid = url.user,
                  let host = url.host,
                  let port = url.port else {
                throw NSError(domain: "configError", code: 4, userInfo: [NSLocalizedDescriptionKey: "节点地址无效"])
            }
            
            // 找到 tag 为 "proxy" 的 outbound
            if let proxyIndex = outbounds.firstIndex(where: { $0["tag"] as? String == "proxy" }) {
                var proxy = outbounds[proxyIndex]
                proxy["server"] = host
                proxy["server_port"] = port
                proxy["uuid"] = uuid
                
                // 解析 URL 参数
                if let components = URLComponents(string: requestAddress), let queryItems = components.queryItems {
                    // 构建非可选值的字典
                    var params: [String: String] = [:]
                    for item in queryItems {
                        if let value = item.value {
                            params[item.name] = value
                        }
                    }
                    
                    // 处理 TLS
                    if params["security"] == "tls" {
                        var tlsDict: [String: Any] = ["enabled": true]
                        
                        // server_name (sni)
                        if let sni = params["sni"] ?? params["host"] {
                            tlsDict["server_name"] = sni
                        }
                        
                        // insecure
                        if let insecure = params["insecure"] ?? params["allowInsecure"], insecure == "1" {
                            tlsDict["insecure"] = true
                        }
                        
                        // alpn
                        if let alpnStr = params["alpn"] {
                            tlsDict["alpn"] = alpnStr.split(separator: ",").map { String($0) }
                        }
                        
                        // utls / fingerprint
                        if let fp = params["fp"] {
                            tlsDict["utls"] = [
                                "enabled": true,
                                "fingerprint": fp
                            ]
                        }
                        
                        proxy["tls"] = tlsDict
                    } else {
                        proxy["tls"] = ["enabled": false]
                    }
                    
                    // 处理 Transport (如 xhttp)
                    if let type = params["type"] {
                        var transportDict: [String: Any] = ["type": type]
                        
                        if let host = params["host"] {
                            transportDict["host"] = host
                        }
                        
                        if let path = params["path"] {
                            transportDict["path"] = path.removingPercentEncoding ?? path
                        }
                        
                        if let mode = params["mode"] {
                            transportDict["mode"] = mode
                        }
                        
                        proxy["transport"] = transportDict
                    }
                }
                
                outbounds[proxyIndex] = proxy
            }
            
            cfgD["outbounds"] = outbounds

            // 基础配置已经由 config.json 提供，这里只需进行必要的运行时微调（如果需要）

            let data = try JSONSerialization.data(withJSONObject: cfgD)
            let jsonString = String(data: data, encoding: .utf8)
            olog(jsonString ?? "")
            return jsonString
        } catch {
            throw NSError(domain: "SingboxConfigError", code: 2, userInfo: [NSLocalizedDescriptionKey: "加载配置失败: \(error.localizedDescription)"])
        }
    }
    
    private func fetchConfig() throws -> [String: Any] {
        guard let defaultConfigUrl = Bundle.main.url(forResource: "config", withExtension: "json") else {
            throw NSError(domain: "configError", code: 2, userInfo: [NSLocalizedDescriptionKey: "找不到配置"])
        }

        let data = try Data(contentsOf: defaultConfigUrl)
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return json
        } else {
            throw NSError(
                domain: "configError", code: 3, userInfo: [NSLocalizedDescriptionKey: "配置格式无效"])
        }
    }
    
    // DNS 和 Route 的配置现在主要依赖于 config.json 中的初始定义
    // 如果有特殊的分流需求可以在这里动态添加
}
