//
//  HomeViewModel.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
    @Published var rotation: Double = 0
    
    // Observed from VPNMonitorManager
    @ObservedObject var vpnManager = VPNMonitorManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Any specific initializations
    }
    
    var statusTitle: String {
        switch vpnManager.tunnelState {
        case .connected: return "网络已加密"
        case .connecting: return "连接中"
        default: return "网络未加密"
        }
    }
    
    var statusIcon: String {
        switch vpnManager.tunnelState {
        case .connected: return "connected"
        case .connecting: return "connecting"
        default: return "lock_open"
        }
    }
    
    var statusColor: Color {
        switch vpnManager.tunnelState {
        case .connected: return Color(hex: "#0AD8B4")
        default: return Color(hex: "#F2D347")
        }
    }
    
    var connectButtonImage: String {
        switch vpnManager.tunnelState {
        case .connected: return "connect_btn_img1"
        default: return "connect_btn_img"
        }
    }
    
    func toggleVPN() {
        // Placeholder for VPN connection logic
        olog("Toggle VPN connection")
        
//        vpnManager.tunnelState = .connecting
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//            self.vpnManager.tunnelState = .connected
//        }
    }
}
