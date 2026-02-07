//
//  VPNConnectManager.swift
//  OpenLink
//
//  Created by eleven on 2026/2/7.
//

import Foundation
import Library

class VPNConnectManager: ObservableObject {
    static let shared = VPNConnectManager()
    @Published var currentSelectedNode: NodeModel?
    
    func startVPN(_ nodeItem: NodeModel? = nil) async -> Bool {
        
        guard let node = nodeItem ?? currentSelectedNode else {
            olog("节点为空")
            return false
        }
        
        await MainActor.run {
            currentSelectedNode = node
        }
        
        let isConnected = await MainActor.run {
            VPNMonitorManager.shared.tunnelState.onConnected
        }
        if isConnected {
            await stopVPN(reason: "restart")
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }

        do {
            let suc = try await SingboxHelper.shared.startConnect(node)
            return suc
        } catch {
            olog(error.localizedDescription)
            return false
        }
    }
    
    
    func stopVPN(reason: String) async {
        do {
            try await SingboxHelper.shared.stopConnect()
        } catch {
            olog(error.localizedDescription)
        }
    }
}
