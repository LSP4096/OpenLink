//
//  OpenLinkApp.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import SwiftUI
import AlertToast

@main
struct OpenLinkApp: App {
    @UIApplicationDelegateAdaptor private var delegate: OpenLinkAppDelegate
    @ObservedObject private var lanManager = LanguageManager.shared
    @ObservedObject private var packageInfo = PackageInfoManager.shared
    @StateObject private var toast = Toast.shared
    @StateObject private var popupManager = PopupManager.shared
    @State private var showSplash = true

    init() {
        Task {
            await LaunchNetworkPer().requestData()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .animation(.easeInOut, value: popupManager.activePopups)
                .toast(isPresenting: $toast.showToast) {
                    toast.toast ?? AlertToast(type: .regular)
                }
        }
    }
}
