//
//  AppPopup.swift
//  OpenLink
//
//  Created by eleven on 2026/2/7.
//


import Foundation

// 弹窗弹出动画效果
enum PopupTransition {
    case bottom
    case top
    case scale
    case fade
}

struct VersionUpdateModel: Equatable {
    let version: String
    let content: String
    let isForce: Bool
    var onDismiss: (() -> Void)? = nil
    
    static func == (lhs: VersionUpdateModel, rhs: VersionUpdateModel) -> Bool {
        lhs.version == rhs.version && lhs.isForce == rhs.isForce
    }
}

// 弹窗
enum AppPopup: Identifiable, Equatable {
    case vpnPermissionPopupView(()->Void) // vpn首次连接权限弹窗
    case versionUpdate(VersionUpdateModel) // 版本更新弹窗

    static func == (lhs: AppPopup, rhs: AppPopup) -> Bool {
        lhs.id == rhs.id // ✅ 按 ID 判断即可，不比较闭包
    }
    
    var id: String {
        switch self {
        case .vpnPermissionPopupView: return "vpnPermissionPopupView"
        case .versionUpdate: return "versionUpdate"
        }
    }
    
    var transition: PopupTransition {
        switch self {
        case .vpnPermissionPopupView:
            return .fade
        case .versionUpdate:
            return .scale
        }
    }
}
