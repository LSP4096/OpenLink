//
//  NetworkMonitor.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import Foundation
import Network

final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published private(set) var isConnected: Bool = false
    @Published private(set) var networkType: NWInterface.InterfaceType = .wifi

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
                var currentType = "other"
                if path.usesInterfaceType(.wifi) {
                    self.networkType = .wifi
                    currentType = "wifi"
                } else if path.usesInterfaceType(.cellular) {
                    self.networkType = .cellular
                    currentType = "cellular"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.networkType = .wiredEthernet
                    currentType = "wired"
                } else {
                    self.networkType = .other
                }
                
//                StatisticsManager.shared.log(event: .networkChanged, params: [
//                    "isConnected": self.isConnected,
//                    "type": currentType
//                ])
            }
        }
        monitor.start(queue: queue)
    }
}
