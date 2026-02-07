//
//  PopupContainer.swift
//  OpenLink
//
//  Created by eleven on 2026/2/7.
//

import SwiftUI

struct PopupContainer: View {
    @ObservedObject var manager: PopupManager
    
    var body: some View {
        ZStack {
            ForEach(manager.activePopups.indices, id: \.self) { index in
                let popup = manager.activePopups[index]
                let zindex = Double(index) * 2.0
                
                // 背景遮罩
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if case .versionUpdate(let model) = popup {
                            if model.isForce { return }
                            model.onDismiss?()
                        }
                        manager.dismiss(popup)
                    }
                    .zIndex(zindex)
                
                // 弹窗内容
                content(for: popup)
                    .transition(transition(for: popup.transition))
                    .zIndex(zindex + 1.0)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: manager.activePopups)
    }

    @ViewBuilder
    private func content(for popup: AppPopup) -> some View {
        switch popup {
        case .vpnPermissionPopupView(let onConfirm):
            VPNPermissionPopupView(
                isShow: Binding(
                    get: { manager.activePopups.contains(where: { $0.id == popup.id }) },
                    set: { if !$0 { manager.dismiss(popup) } }
                ),
                onConfirm: onConfirm
            )
        case .versionUpdate(let model):
            // 这里以后可以添加 VersionUpdateView
            Text("Version Update: \(model.version)")
                .padding()
                .background(Color.white)
                .cornerRadius(10)
        }
    }

    private func transition(for type: PopupTransition) -> AnyTransition {
        switch type {
        case .bottom: return .move(edge: .bottom)
        case .top: return .move(edge: .top)
        case .scale: return .scale.combined(with: .opacity)
        case .fade: return .opacity
        }
    }
}
