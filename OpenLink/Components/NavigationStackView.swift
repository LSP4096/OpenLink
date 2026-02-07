//
//  NavigationStackView.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import SwiftUI

// 自定义导航器（类似系统 NavigationStack ios16+）
struct NavigationStackView<Content: View>: View {
    @Binding var path: [Route]
    @ViewBuilder var content: () -> Content

    var body: some View {
        NavigationView {
            ZStack {
                content()

                // 递归导航链接
                NavigationLink(
                    isActive: Binding(
                        get: { !path.isEmpty },
                        set: { if !$0 && !path.isEmpty { path.removeLast() } }
                    ),
                    destination: {
                        RouterView(path: $path)
                    },
                    label: { EmptyView() }
                )
            }
        }
        .navigationViewStyle(.stack)
        .accentColor(Color(hex: "#1C2F2C"))
    }
}

struct RouterView: View {
    @Binding var path: [Route]

    var body: some View {
        if let route = path.first {
            // 获取当前路由对应的视图
            RouterView.destinationView(for: route)
                .background(
                    // 递归链接：如果还有下一个路径
                    NavigationLink(
                        isActive: Binding(
                            get: { path.count > 1 },
                            set: { isPresenting in
                                if !isPresenting && path.count > 1 {
                                    path.removeLast()
                                }
                            }
                        ),
                        destination: {
                            RouterView(
                                path: Binding(
                                    get: { Array(path.dropFirst()) },
                                    set: { newPath in
                                        if path.count > 1 {
                                            path = [path[0]] + newPath
                                        }
                                    }
                                ))
                        },
                        label: { EmptyView() }
                    )
                )
        }
    }

    @ViewBuilder
    static func destinationView(for route: Route) -> some View {
        Group {
            switch route {
            case .home:
                HomeView()
            case .shunt:
                ShuntView()
            case .adblock:
                AdBlockView()
            case .settings:
                SettingsView()
            case .nodeList:
                NodeListView()
            }
        }
        .background(Color(hex: "#1C2F2C"))
        .navigationBarTitleDisplayMode(.inline)
    }

}

enum Route: Hashable {
    case home
    case shunt
    case adblock
    case settings
    case nodeList

    /// 服务器 ID 映射，参数类型不固定的用占位说明
    static let serverMap: [Int: (String?) -> Route] = [
        1: { _ in .home }
    ]

    /// 根据服务器 ID + 可选参数生成路由
    static func fromServer(id: Int, param: String? = nil) -> Route? {
        guard let creator = serverMap[id] else { return nil }
        return creator(param)
    }
}

class AppRouter: ObservableObject {
    static let shared = AppRouter()

    @Published var path: [Route] = []
    @Published var selectedTab: Int = 0

    // 跳转
    func push(_ route: Route) {
        if path.last == route { return }
        DispatchQueue.main.async {
            self.path.append(route)
        }
    }

    // 返回上一级
    func pop() {
        guard !path.isEmpty else { return }
        DispatchQueue.main.async {
            self.path.removeLast()
        }
    }

    // 返回根
    func popToRoot() {
        DispatchQueue.main.async {
            self.path.removeAll()
        }
    }
}
