import Foundation
import Libbox
import NetworkExtension

public class ExtensionProfile {
    public static let controlKind = "io.nekohasekai.dejiang.widget.ServiceToggle"

    public let manager: NEVPNManager
    private var connection: NEVPNConnection
    private var observer: Any?

    public var status: NEVPNStatus
    
    static let serverAddress = "AiAcceleration"

    public init(_ manager: NEVPNManager) {
        self.manager = manager
        connection = manager.connection
        status = manager.connection.status
    }

    public func register() {
        observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NEVPNStatusDidChange,
            object: manager.connection,
            queue: .main
        ) { [weak self] notification in
            guard let self else {
                return
            }
            self.connection = notification.object as! NEVPNConnection
            self.status = self.connection.status
        }
    }

    private func unregister() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setOnDemandRules() {
//        let interfaceRule = NEOnDemandRuleConnect()
//        interfaceRule.interfaceTypeMatch = .any
//        let probeRule = NEOnDemandRuleConnect()
//        probeRule.probeURL = URL(string: "http://captive.apple.com")
//        manager.onDemandRules = [interfaceRule, probeRule]
    }

    public func updateAlwaysOn(_ newState: Bool) async throws {
//        manager.isOnDemandEnabled = newState
//        setOnDemandRules()
//        try await manager.saveToPreferences()
    }

    @available(iOS 16.0, macOS 13.0, tvOS 17.0, *)
    public func fetchLastDisconnectError() async throws {
        try await connection.fetchLastDisconnectError()
    }

    public func start() async throws {
//        await fetchProfile()
        manager.isEnabled = true
//        if await SharedPreferences.alwaysOn.get() {
//            manager.isOnDemandEnabled = true
//            setOnDemandRules()
//        }
        #if !os(tvOS)
            if let protocolConfiguration = manager.protocolConfiguration {
                let includeAllNetworks = await SharedPreferences.includeAllNetworks.get()
                protocolConfiguration.includeAllNetworks = includeAllNetworks
                if #available(iOS 16.4, macOS 13.3, *) {
                    protocolConfiguration.excludeCellularServices = !includeAllNetworks
                }
            }
        #endif
        try await manager.saveToPreferences()
        #if os(macOS)
            if Variant.useSystemExtension {
                try manager.connection.startVPNTunnel(options: [
                    "username": NSString(string: NSUserName()),
                ])
                return
            }
        #endif
        try manager.connection.startVPNTunnel()
    }

//    public func fetchProfile() async {
//        do {
//            if let profile = try await ProfileManager.get(Int64(SharedPreferences.selectedProfileID.get())) {
//                if profile.type == .icloud {
//                    _ = try profile.read()
//                }
//            }
//        } catch {}
//    }

    public func stop() async throws {
//        if manager.isOnDemandEnabled {
//            manager.isOnDemandEnabled = false
//            try await manager.saveToPreferences()
//        }
        do {
            try LibboxNewStandaloneCommandClient()!.serviceClose()
        } catch {}
        manager.connection.stopVPNTunnel()
        // 3. 获取 session
//        guard let session = manager.connection as? NETunnelProviderSession else {
//            return
//        }
//        
//        if [.connected, .connecting, .reasserting].contains(session.status) {
//            await awaitSessionDisconnected(session)
//        }
    }
    
    private func awaitSessionDisconnected(_ session: NETunnelProviderSession) async {
        // 发起断开（立即返回，不阻塞）
        session.stopTunnel()

        // 监听状态变更通知，直到真正断开
        for await _ in NotificationCenter
            .default
            .notifications(named: .NEVPNStatusDidChange, object: nil)
        {
            // 直接读取 session.status，即可判断当前状态
            if session.status == .disconnected {
                break
            }
        }
    }
    

    public static func load() async throws -> ExtensionProfile? {
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        if managers.isEmpty {
            return nil
        }
        // 查找匹配serverAddress的配置
        if let matchedManager = managers.first(where: {
            guard let proto = $0.protocolConfiguration as? NETunnelProviderProtocol else { return false }
            return proto.serverAddress == serverAddress
        }) {
            return ExtensionProfile(matchedManager)
        } else {
            return ExtensionProfile(managers[0])
        }
    }

//    public static func install(port: String) async throws {
//        let manager = NETunnelProviderManager()
//        manager.localizedDescription = Variant.applicationName
//        let tunnelProtocol = NETunnelProviderProtocol()
//        tunnelProtocol.providerBundleIdentifier = "\(FilePath.packageName).network-extension"
//        tunnelProtocol.serverAddress = port
//        manager.protocolConfiguration = tunnelProtocol
//        manager.isEnabled = true
//        try await manager.saveToPreferences()
//    }

//    public static func install(port: String) async throws {
//        // 1. 加载所有现有的 VPN 配置
//        let existingManagers = try await NETunnelProviderManager.loadAllFromPreferences()
//
//        // 2. 检查是否已有相同端口的配置
//        if existingManagers.first(where: {
//            ($0.protocolConfiguration as? NETunnelProviderProtocol)?.serverAddress == port
//        }) != nil {
//            DebugTools.log("✅ 配置已存在，无需重新安装。")
//            return
//        }
//
//        // 3. 移除旧的同类配置（可按描述名或 bundle ID 判断）
//        for manager in existingManagers {
//            if manager.localizedDescription == Variant.applicationName {
//                try await manager.removeFromPreferences()
//            }
//        }
//
//        // 4. 创建新的配置
//        let manager = NETunnelProviderManager()
//        manager.localizedDescription = Variant.applicationName
//
//        let tunnelProtocol = NETunnelProviderProtocol()
//        tunnelProtocol.providerBundleIdentifier = "\(FilePath.packageName).network-extension"
//        tunnelProtocol.serverAddress = port
//        manager.protocolConfiguration = tunnelProtocol
//        manager.isEnabled = true
//        
//        // 5. 保存
//        try await manager.saveToPreferences()
//    }
    
    public static func install() async throws {
        // 1. 加载本app所有现有的 VPN 配置
        let existingManagers = try await NETunnelProviderManager.loadAllFromPreferences()

        // 2. 如果已经有相同 serverAddress 的配置，则跳过安装
        if existingManagers.contains(where: {
            guard let proto = $0.protocolConfiguration as? NETunnelProviderProtocol else { return false }
            return proto.serverAddress == serverAddress
        }) {
            return
        }

        // 4. 创建新的配置
        let manager = NETunnelProviderManager()
//        manager.localizedDescription = Variant.applicationName
        let tunnelProtocol = NETunnelProviderProtocol()
        tunnelProtocol.providerBundleIdentifier = "\(FilePath.packageName).network-extension-ios"
        tunnelProtocol.serverAddress = serverAddress
        manager.protocolConfiguration = tunnelProtocol
        manager.isEnabled = true

        // 5. 保存
        try await manager.saveToPreferences()
    }
}






func runBlocking<T>(_ block: @escaping () async -> T) -> T {
    let semaphore = DispatchSemaphore(value: 0)
    let box = resultBox<T>()
    Task.detached {
        let value = await block()
        box.result0 = value
        semaphore.signal()
    }
    semaphore.wait()
    return box.result0
}

func runBlocking<T>(_ tBlock: @escaping () async throws -> T) throws -> T {
    let semaphore = DispatchSemaphore(value: 0)
    let box = resultBox<T>()
    Task.detached {
        do {
            let value = try await tBlock()
            box.result = .success(value)
        } catch {
            box.result = .failure(error)
        }
        semaphore.signal()
    }
    semaphore.wait()
    return try box.result.get()
}

private class resultBox<T> {
    var result: Result<T, Error>!
    var result0: T!
}
