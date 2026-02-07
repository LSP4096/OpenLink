//
//  VPNMonitorManager.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import Combine
import Foundation
import NetworkExtension
import SwiftUI

@MainActor
final class VPNMonitorManager: ObservableObject {
    static let shared = VPNMonitorManager()

    // MARK: - Published Properties (Renamed)
    @Published  var tunnelState: NEVPNStatus = .invalid
    @Published private(set) var sessionStartTime: Date? = nil
    @Published private(set) var sessionDuration: String = "00:00:00"
    
    // MARK: - Internal Properties
    private let priorityStatuses: [NEVPNStatus] = [
        .connected, .disconnecting, .reasserting, .connecting, .disconnected,
    ]
    private let targetServerAddress = "OpenLink"
    private var activeManager: NETunnelProviderManager?
    private var isMonitoring = false
    private var timerSubscription: AnyCancellable?

    private init() {
        startMonitoring()
        
        // Timer for duration updates
        timerSubscription =
            Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshDuration()
            }
        
        // Listen for configuration changes (e.g., first install)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configChanged),
            name: .NEVPNConfigurationChange,
            object: nil
        )
    }

    // MARK: - Public Methods
    func startMonitoring() {
         Task {
             await reloadConfiguration()
         }
//        startSimulation()
    }
    
    private func startSimulation() {
        let statuses: [NEVPNStatus] = [.disconnected, .connecting, .connected]
        var currentIndex = 0
        
        Task {
            while !Task.isCancelled {
                // Sleep for 5 seconds
                try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
                
                self.tunnelState = statuses[currentIndex]
                
                if self.tunnelState == .connected {
                    self.sessionStartTime = Date()
                } else {
                    self.sessionStartTime = nil
                }
                
                currentIndex = (currentIndex + 1) % statuses.count
            }
        }
    }

    func resetMonitor() {
        activeManager = nil
        tunnelState = .invalid
        sessionStartTime = nil
    }

    // MARK: - Private Methods
    private func reloadConfiguration() async {
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            
            // Find matching config based on priority and server address
            let matched = priorityStatuses.compactMap { status in
                managers.first(where: {
                    $0.connection.status == status &&
                    ($0.protocolConfiguration as? NETunnelProviderProtocol)?.serverAddress == self.targetServerAddress
                })
            }.first ?? managers.first(where: {
                ($0.protocolConfiguration as? NETunnelProviderProtocol)?.serverAddress == self.targetServerAddress
            })
            
            guard let finalMatched = matched else {
                olog("No matching VPN configuration found yet.")
                tunnelState = .invalid
                sessionStartTime = nil
                activeManager = nil
                return
            }
            
            // If manager changed or wasn't set, update observers
            if finalMatched !== activeManager {
                if let oldManager = activeManager {
                    NotificationCenter.default.removeObserver(self, name: .NEVPNStatusDidChange, object: oldManager.connection)
                }
                
                activeManager = finalMatched
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(vpnStatusChanged),
                    name: .NEVPNStatusDidChange,
                    object: finalMatched.connection
                )
                isMonitoring = true
                olog("VPNMonitorManager: Bound to manager \(finalMatched.localizedDescription ?? "unknown")")
            }
            
            tunnelState = finalMatched.connection.status
            sessionStartTime = finalMatched.connection.connectedDate

            // Cleanup other configurations
            for manager in managers {
                if manager !== finalMatched && (manager.protocolConfiguration as? NETunnelProviderProtocol)?.serverAddress == self.targetServerAddress {
                    try? await manager.removeFromPreferences()
                    olog("Removed redundant config: \(manager.localizedDescription ?? "<unnamed>")")
                }
            }

        } catch {
            olog("Failed to load configs: \(error)")
            resetMonitor()
        }
    }

    @objc private func configChanged() {
        olog("VPN configuration changed, reloading...")
        Task {
            await reloadConfiguration()
        }
    }

    @objc private func vpnStatusChanged() {
        guard let manager = activeManager else { return }
        
        let previousState = tunnelState
        tunnelState = manager.connection.status
        sessionStartTime = manager.connection.connectedDate
        
        // Detect transition from connected to disconnected
        if previousState == .disconnecting && tunnelState == .disconnected {
            olog("VPN disconnection detected")
            
            // Trigger reconnection logic
//            Task { @MainActor in
//                ReconnectionManager.shared.handleDisconnection()
//            }
        }
    }
    
    private func refreshDuration() {
        guard let sessionStartTime else {
            sessionDuration = "00:00:00"
            return
        }
        let seconds = Int(Date().timeIntervalSince(sessionStartTime))
        sessionDuration = formatTimeSeconds(seconds)
    }
    
    private func formatTimeSeconds(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}


extension NEVPNStatus: @retroactive CustomStringConvertible {
    /// 判断是否是连接相关状态（连接中、已连接、正在断开）
    var onConnected: Bool {
        return [.connected, .disconnecting, .reasserting].contains(self)
    }

    public var description: String {
        switch self {
        case .invalid: return "invalid"
        case .disconnected: return "disconnected"
        case .connecting: return "connecting"
        case .connected: return "connected"
        case .reasserting: return "reasserting"
        case .disconnecting: return "disconnecting"
        @unknown default: return "unknown"
        }
    }
}
