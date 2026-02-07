//
//  OpenLinkAppDelegate.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import Foundation
import Libbox
import Library
import Network
import UIKit
import UserNotifications

class OpenLinkAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private var profileServer: ProfileServer?
    
    func application(_: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        initSB()
        return true
    }
    
    // MARK: - func
    
    private func initSB() {
        let options = LibboxSetupOptions()
        options.basePath = FilePath.sharedDirectory.relativePath
        options.workingPath = FilePath.workingDirectory.relativePath
        options.tempPath = FilePath.cacheDirectory.relativePath
        var error: NSError?
        LibboxSetup(options, &error)
        LibboxSetLocale(Locale.current.identifier)
        LibboxSetMemoryLimit(true)
        
        
        Task {
            if UIDevice.current.userInterfaceIdiom == .phone {
                await requestNetworkPermission()
            }
            await setupBackground()
        }
    }
    
    private nonisolated func setupBackground() async {
        if #available(iOS 16.0, *) {
            do {
                let profileServer = try ProfileServer()
                profileServer.start()
                await MainActor.run {
                    self.profileServer = profileServer
                }
                olog("started profile server")
            } catch {
                olog("setup profile server error: \(error.localizedDescription)")
            }
        }
    }

    private nonisolated func requestNetworkPermission() async {
        if await SharedPreferences.networkPermissionRequested.get() {
            return
        }

        URLSession.shared.dataTask(with: URL(string: "http://captive.apple.com")!) { _, response, _ in
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    Task {
                        await SharedPreferences.networkPermissionRequested.set(true)
                    }
                }
            }
        }.resume()
    }
}
