//
//  NodeListView.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import SwiftUI

struct NodeListView: View {
    @StateObject private var viewModel = NodeListViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#1C2F2C").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                ZStack {
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .padding(12)
                        }
                        Spacer()
                    }
                    
                    Text("选择国家")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(height: 56)
                
                // Mode Tabs
                HStack(spacing: 12) {
                    ModeButton(title: "智能模式", isSelected: viewModel.selectedMode == 0) {
                        viewModel.selectedMode = 0
                    }
                    
                    ModeButton(title: "全局模式", isSelected: viewModel.selectedMode == 1) {
                        viewModel.selectedMode = 1
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                
                // Node List
                ScrollView {
                    VStack(spacing: 0) {
                        if viewModel.isLoading && viewModel.nodes.isEmpty {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.top, 40)
                        } else {
                            ForEach(viewModel.nodes) { node in
                                NodeListRow(node: node, 
                                           isExpanded: viewModel.expandedGroupIds.contains(node.id),
                                           isSelected: viewModel.selectedNodeId == node.id) {
                                    if node.isGroup {
                                        viewModel.toggleGroup(node.id)
                                    } else {
                                        viewModel.selectNode(node)
                                    }
                                } selectChild: { child in
                                    viewModel.selectNode(child)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Subviews

struct ModeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? Color(hex: "#0AD8B4") : .white.opacity(0.6))
                .frame(width: 110, height: 38)
                .background(isSelected ? Color(hex: "#0AD8B4").opacity(0.15) : Color.white.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color(hex: "#0AD8B4").opacity(0.3) : Color.clear, lineWidth: 1)
                )
        }
    }
}

struct NodeListRow: View {
    let node: NodeModel
    let isExpanded: Bool
    let isSelected: Bool
    let action: () -> Void
    let selectChild: (NodeModel) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 12) {
                    if node.flag == "auto" {
                        ZStack {
                            Circle().fill(Color(hex: "#0AD8B4").opacity(0.2)).frame(width: 32, height: 32)
                            Image(systemName: "bolt.fill")
                                .foregroundColor(Color(hex: "#0AD8B4"))
                                .font(.system(size: 14))
                        }
                    } else {
                        Image(node.flagImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(node.country ?? "")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            if let tags = node.tags {
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag.dictLabel)
                                        .font(.system(size: 10))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(tagColor(tag.dictLabel).opacity(0.2))
                                        .foregroundColor(tagColor(tag.dictLabel))
                                        .cornerRadius(4)
                                }
                            }
                        }
                        
                        if let city = node.city, !city.isEmpty {
                            Text(city)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                        } else if node.isGroup, let childCount = node.children?.count {
                            Text("\(childCount)个城市")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    // Latency
                    if let ms = node.ms {
                        HStack(spacing: 4) {
                            Circle().fill(latencyColor(ms)).frame(width: 6, height: 6)
                            Text("\(ms)ms")
                                .font(.system(size: 11))
                                .foregroundColor(latencyColor(ms))
                        }
                        .padding(.trailing, 10)
                    }
                    
                    // Radio Button or Chevron
                    if node.isGroup {
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .foregroundColor(.white.opacity(0.3))
                    } else {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? Color(hex: "#0AD8B4") : .white.opacity(0.2))
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 64)
            }
            
            // Divider
            Divider().background(Color.white.opacity(0.05)).padding(.leading, 60)
            
            // Children
            if node.isGroup && isExpanded, let children = node.children {
                ForEach(children) { child in
                    Button(action: { selectChild(child) }) {
                        HStack(spacing: 12) {
                            Spacer().frame(width: 44) // Indent
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(child.city ?? "")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.white)
                                    
                                    if let tags = child.tags {
                                        ForEach(tags, id: \.self) { tag in
                                            Text(tag.dictLabel)
                                                .font(.system(size: 9))
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(tagColor(tag.dictLabel).opacity(0.2))
                                                .foregroundColor(tagColor(tag.dictLabel))
                                                .cornerRadius(3)
                                        }
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            if let ms = child.ms {
                                HStack(spacing: 4) {
                                    Circle().fill(latencyColor(ms)).frame(width: 6, height: 6)
                                    Text("\(ms)ms")
                                        .font(.system(size: 11))
                                        .foregroundColor(latencyColor(ms))
                                }
                                .padding(.trailing, 10)
                            }
                            
                            Image(systemName: "circle") // Should handle selection properly for children too
                                .foregroundColor(.white.opacity(0.2))
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 54)
                    }
                    Divider().background(Color.white.opacity(0.05)).padding(.leading, 60)
                }
            }
        }
        .contentShape(Rectangle())
    }
    
    private func tagColor(_ tag: String) -> Color {
        let t = tag.lowercased()
        if t.contains("直播") || t.contains("live") { return Color(hex: "#F2D347") }
        if t.contains("流媒体") || t.contains("streaming") { return Color(hex: "#E0507B") }
        if t.contains("ai") { return Color(hex: "#20D1AF") }
        if t.contains("big data") { return Color(hex: "#4796F2") }
        return .blue
    }
    
    private func latencyColor(_ ms: Int) -> Color {
        if ms < 50 { return Color(hex: "#0AD8B4") }
        if ms < 200 { return Color(hex: "#4796F2") }
        if ms < 1000 { return Color(hex: "#F2D347") }
        return Color(hex: "#E0507B")
    }
}

#Preview {
    NodeListView()
}
