//
//  NodeListViewModel.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import SwiftUI
import Combine

class NodeListViewModel: ObservableObject {
    @Published var nodes: [NodeModel] = []
    @Published var isLoading: Bool = false
    @Published var selectedMode: Int = 0 // 0: 智能模式, 1: 全局模式
    @Published var selectedNodeId: Int? = nil // To track current selection
    
    // Grouped structure for the UI
    @Published var displayNodes: [NodeModel] = []
    
    // Set to track expanded groups
    @Published var expandedGroupIds: Set<Int> = []
    
    private var currentPage: Int = 1
    private var pageSize: Int = 100

    init() {
        if let node = VPNConnectManager.shared.currentSelectedNode {
            selectedNodeId = node.id
        }
        loadFromCache()
        loadNodes()
    }
    
    // 从缓存加载
    func loadFromCache() {
        let cached = NodeDBManager.shared.getAllNodes()
        if !cached.isEmpty {
            updateDisplayList(with: cached)
        }
    }
    
    // 从网络加载
    func loadNodes() {
        isLoading = true
        Task {
            do {
                let list = try await NetworkService.shared.requestNodeList(page: currentPage, pageSize: pageSize)
                
                // 缓存到本地
                NodeDBManager.shared.saveNodes(list)
                
                await MainActor.run {
                    self.updateDisplayList(with: list)
                    self.isLoading = false
                }
            } catch {
                olog("❌ Load nodes failed: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    // 统一更新列表逻辑
    private func updateDisplayList(with list: [NodeModel]) {
        var allNodes: [NodeModel] = []
        // 手动添加自动选择最优节点
        let autoNode = NodeModel(id: -1, country: "自动选择最优节点", flag: "auto")
        allNodes.append(autoNode)
        allNodes.append(contentsOf: list)
        self.nodes = allNodes
        
        // 默认选择第一个节点（不包括自动选择最优节点，即从服务器下发的列表中选第一个）
        if VPNConnectManager.shared.currentSelectedNode == nil {
            Task {
                await MainActor.run {
                    if let firstRealNode = list.first {
                        VPNConnectManager.shared.currentSelectedNode = firstRealNode
                    } else {
                        VPNConnectManager.shared.currentSelectedNode = autoNode
                    }
                }
            }
        }
    }
    
    func toggleGroup(_ nodeId: Int) {
        if expandedGroupIds.contains(nodeId) {
            expandedGroupIds.remove(nodeId)
        } else {
            expandedGroupIds.insert(nodeId)
        }
    }
    
    func selectNode(_ node: NodeModel) {
        selectedNodeId = node.id
        Task {
            await VPNConnectManager.shared.startVPN(node)
        }
    }
}
