//
//  SettingsViewModel.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import SwiftUI

struct MenuItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let action: () -> Void
}

class SettingsViewModel: ObservableObject {
    
    @Published var isLoggedIn: Bool = false
    @Published var userInfo: UserInfo?
    @Published var menuItems: [MenuItem] = []
    
    struct UserInfo {
        var name: String
        var id: String
        var avatar: String
    }
    
    init() {
        setupMockData()
        setupMenuItems()
    }
    
    private func setupMockData() {
        // 模拟未登录状态
        isLoggedIn = false
        // 模拟登录后数据
        // isLoggedIn = true
        // userInfo = UserInfo(name: "ZS1FF363634", id: "46879823", avatar: "avatar_placeholder")
    }
    
    private func setupMenuItems() {
        menuItems = [
            MenuItem(icon: "icon_tunnel", title: "隧道拆分", action: { print("Tapped 隧道拆分") }),
            MenuItem(icon: "icon_service", title: "在线客服", action: { print("Tapped 在线客服") }),
            MenuItem(icon: "icon_feedback", title: "问题反馈", action: { print("Tapped 问题反馈") }),
            MenuItem(icon: "icon_share", title: "分享好友", action: { print("Tapped 分享好友") }),
            MenuItem(icon: "icon_download", title: "下载IO或PC", action: { print("Tapped 下载IO或PC") }),
            MenuItem(icon: "icon_apps", title: "热门应用", action: { print("Tapped 热门应用") }),
            MenuItem(icon: "icon_password", title: "修改密码", action: { print("Tapped 修改密码") }),
            // 分割线
            MenuItem(icon: "icon_about", title: "关于我们", action: { print("Tapped 关于我们") }),
            MenuItem(icon: "icon_settings", title: "设置", action: { print("Tapped 设置") })
        ]
    }
    
    func login() {
        isLoggedIn = true
        userInfo = UserInfo(name: "ZS1FF363634", id: "46879823", avatar: "avatar_placeholder")
    }
}
