//
//  SettingsView.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import SwiftUI

// MARK: - 常量定义
private enum LayoutConstants {
    static let leadingPadding: CGFloat = 12
    static let trailingPadding: CGFloat = 13
    static let itemHeight: CGFloat = 49
    static let iconSize: CGFloat = 27
    static let iconTextSpacing: CGFloat = 12
    static let vipCardHeight: CGFloat = 100
    static let avatarSize: CGFloat = 60
    static let sectionSpacing: CGFloat = 20
    static let groupSeparatorHeight: CGFloat = 8
}

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        ZStack {
            Color.mainBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: LayoutConstants.sectionSpacing) {
                    // 用户信息区
                    ProfileHeaderView(viewModel: viewModel)
                    
                    // VIP 卡片
                    VIPCardView(isVip: viewModel.isLoggedIn)
                    
                    // 菜单列表
                    MenuListView(items: viewModel.menuItems)
                }
                .padding(.leading, LayoutConstants.leadingPadding)
                .padding(.trailing, LayoutConstants.trailingPadding)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - 用户信息头部
struct ProfileHeaderView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // 头像
            Image(viewModel.isLoggedIn ? (viewModel.userInfo?.avatar ?? "avatar_default") : "avatar_default")
                .resizable()
                .scaledToFill()
                .frame(width: LayoutConstants.avatarSize, height: LayoutConstants.avatarSize)
                .background(Circle().fill(Color.white.opacity(0.1)))
                .clipShape(Circle())
            
            // 用户名和ID
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.isLoggedIn ? (viewModel.userInfo?.name ?? "未登录") : "未登录")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8) // 允许文字缩小以适应空间
                
                Text("ID: \(viewModel.isLoggedIn ? (viewModel.userInfo?.id ?? "--") : "--")")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(4)
            }
            .layoutPriority(1) // 优先分配空间给用户名区域
            
            Spacer()
            
            // 登录/个人主页 按钮
            Button(action: {
                if !viewModel.isLoggedIn {
                    viewModel.login()
                }
            }) {
                Text(viewModel.isLoggedIn ? "个人主页" : "登录/注册")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#0AD8B4"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Image(viewModel.isLoggedIn ? "btn_bg_white" : "btn_bg_cyan")
                            .resizable()
                            .scaledToFill()
                    )
                    .clipShape(Capsule()) // 胶囊形状裁剪，保持背景图比例
            }
        }
        .padding(.top, 10)
        // 边距由父容器统一控制
    }
}

// MARK: - VIP 卡片
struct VIPCardView: View {
    var isVip: Bool
    
    var body: some View {
        ZStack {
            // 背景图
            Image("vip_card_bg")
                .resizable()
            
            // 内容
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        // 皇冠图标 - 使用 SF Symbol 作为后备
                        Image("icon_crown")
                            .resizable()
                            .frame(width: 29, height: 20)
                            .foregroundColor(isVip ? Color(hex: "#0AD8B4") : .white.opacity(0.5))
                        
                        Text(isVip ? "高级会员" : "未开通会员")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(isVip ? Color(hex: "#0AD8B4") : .white)
                    }
                    
                    Text(isVip ? "到期时间: 2026-12-20 24:59:59" : "极速专线，让等待成为过去。")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image("icon_arrow_right_circle")
                    .resizable()
                    .frame(width: 32, height: 32)
            }
            .padding(20)
        }
        .frame(minHeight: LayoutConstants.vipCardHeight)
        .cornerRadius(20)
        // 边距由父容器统一控制
    }
}

// MARK: - 菜单列表
struct MenuListView: View {
    let items: [MenuItem]
    
    // 定义分组：前7项为第一组，后2项为第二组
    private var firstGroup: [MenuItem] {
        Array(items.prefix(7))
    }
    
    private var secondGroup: [MenuItem] {
        Array(items.suffix(2))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 第一组菜单
            ForEach(firstGroup.indices, id: \.self) { index in
                MenuItemRow(item: firstGroup[index])
                
                if index < firstGroup.count - 1 {
                    MenuDivider()
                }
            }
            
            // 分组间隔 - 需要全宽显示，抵消父容器的边距
            Rectangle()
                .fill(Color.black.opacity(0.2))
                .frame(height: LayoutConstants.groupSeparatorHeight)
                .padding(.leading, -LayoutConstants.leadingPadding)
                .padding(.trailing, -LayoutConstants.trailingPadding)
            
            // 第二组菜单
            ForEach(secondGroup.indices, id: \.self) { index in
                MenuItemRow(item: secondGroup[index])
                
                if index < secondGroup.count - 1 {
                    MenuDivider()
                }
            }
        }
        // 边距由父容器统一控制
    }
}

// MARK: - 菜单项行
struct MenuItemRow: View {
    let item: MenuItem
    
    var body: some View {
        Button(action: item.action) {
            HStack(spacing: LayoutConstants.iconTextSpacing) {
                Image(item.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: LayoutConstants.iconSize, height: LayoutConstants.iconSize)
                
                Text(item.title)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Image("icon_arrow_right")
                    .resizable()
                    .frame(width: 8, height: 13)
            }
            .frame(height: LayoutConstants.itemHeight)
            .contentShape(Rectangle()) // 确保整行可点击
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 分割线
struct MenuDivider: View {
    var body: some View {
        Divider()
            .background(Color.white.opacity(0.05))
            .padding(.leading, LayoutConstants.iconSize + LayoutConstants.iconTextSpacing)
    }
}

#Preview {
    SettingsView()
}
