//
//  NetworkService.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import Foundation
import SwiftyJSON

class NetworkService {
    static let shared = NetworkService()
    
    func requestImieLogin() async -> Bool {
        guard DeviceManager.shared.device == nil else {
            return true
        }
        
        var retryCount = 0
        let maxRetry = 5
        while retryCount < maxRetry {
            let params: [String: Any] = [
                "device_code": DeviceManager.shared.getDeviceID(),
                "login_device": "ios"
            ]
            do {
                olog("🔑 Starting guest login...")
                let deviceModel: DeviceModel = try await NetworkHelper.shared.requestModel(
                    api_imie_login,
                    method: .post,
                    parameters: params
                )
                
                if !deviceModel.token.isEmpty {
                    olog("✅ Guest login successful. Token: \(deviceModel.token)")
                    DeviceManager.shared.saveDeviceInfo(deviceModel)
                    return true
                } else {
                    olog("❌ Guest login failed: No token found")
                    return false
                }
            } catch {
                olog("❌ Guest login error: \(error)")
            }
            
            retryCount += 1
            try? await Task.sleep(nanoseconds: 3_000_000_000)
        }
        
        return false
    }
    
    /// 获取节点列表
    func requestNodeList(page: Int = 1, pageSize: Int = 100) async throws -> [NodeModel] {
        let params: [String: Any] = [
            "type": "ios",
            "page": page,
            "page_size": pageSize
        ]
        let json = try await NetworkHelper.shared.request(api_node_list, method: .post, parameters: params)
        
        // 使用 SwiftyJSON 解析 data 内部的 list 数组
        guard let listData = try? json["data"]["list"].rawData() else {
            return []
        }
        
        // 使用 JSONDecoder 直接解码到模型数组，无需手动 init(json:)
        let list = try JSONDecoder().decode([NodeModel].self, from: listData)
        return list
    }
}


