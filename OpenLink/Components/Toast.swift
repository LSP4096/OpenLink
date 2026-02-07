//
//  Toast.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import SwiftUI
import UIKit
import AlertToast

class Toast: ObservableObject {
    static let shared = Toast()
    
    @Published var showToast: Bool = false
    @Published var toast: AlertToast? = nil
    @Published var isLoading: Bool = false
    private var loadingCount: Int = 0
    
    func show(_ msg: String) {
        show(toast: AlertToast(type: .regular, title: msg, style: .style(backgroundColor: Color(hex: "#474751"), titleColor: .white)))
    }
    
    func showLoading(duration: Double = 2.0) {
        loadingCount += 1
        show(toast: AlertToast(displayMode: .alert, type: .loading), duration: duration)
    }
    
    private func show(toast: AlertToast, duration: Double = 2.0, autoDismiss: Bool = true) {
        DispatchQueue.main.async {
            self.toast = toast
            self.showToast = true
            self.isLoading = toast.type == .loading
            if autoDismiss {
                self.hideAfter(duration: duration)
            }
        }
    }
    
    /// 隐藏 Toast
    func hide() {
        DispatchQueue.main.async {
            if self.loadingCount > 0 {
                self.loadingCount -= 1
            }
            
            // 只有当没有正在进行的loading时才真正隐藏
            if self.loadingCount == 0 {
                self.showToast = false
                self.toast = nil
                self.isLoading = false
            }
        }
    }
    
    private func hideAfter(duration: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.hide()
        }
    }
}
