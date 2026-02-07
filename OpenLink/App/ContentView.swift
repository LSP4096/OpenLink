//
//  ContentView.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var router = AppRouter.shared
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: "#131E1C")
        
        // Unselected Item Appearance
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(hex: "#728783"),
            .font: UIFont.systemFont(ofSize: 11)
        ]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        
        // Selected Item Appearance
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(hex: "#0AD8B4"),
            .font: UIFont.systemFont(ofSize: 11)
        ]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    var body: some View {
        NavigationStackView(path: $router.path) {
            TabView(selection: $router.selectedTab) {
                // Tab 1: Home
                HomeView()
                    .tabItem {
                        VStack {
                            Image(router.selectedTab == 0 ? "tab1_sel" : "tab1")
                            Text("连接")
                        }
                    }
                    .tag(0)
                
                // Tab 2: Shunt
                ShuntView()
                    .tabItem {
                        VStack {
                            Image(router.selectedTab == 1 ? "tab2_sel" : "tab2")
                            Text("应用分流")
                        }
                    }
                    .tag(1)
                
                // Tab 3: AdBlock
                AdBlockView()
                    .tabItem {
                        VStack {
                            Image(router.selectedTab == 2 ? "tab3_sel" : "tab3")
                            Text("广告拦截")
                        }
                    }
                    .tag(2)
                
                // Tab 4: Settings
                SettingsView()
                    .tabItem {
                        VStack {
                            Image(router.selectedTab == 3 ? "tab4_sel" : "tab4")
                            Text("设置")
                        }
                    }
                    .tag(3)
            }
            .tint(Color(hex: "#0AD8B4"))
        }
    }
}

#Preview {
    ContentView()
}
