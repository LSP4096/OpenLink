//
//  PopupManager.swift
//  OpenLink
//
//  Created by eleven on 2026/2/7.
//

import Foundation

final class PopupManager: ObservableObject {
    static let shared = PopupManager()
    
    @Published var activePopups: [AppPopup] = []
    @Published var disappearingPopups: [AppPopup] = [] // ✅ 新增

    func show(_ popup: AppPopup) {
        if !activePopups.contains(popup) {
            DispatchQueue.main.async {
                self.activePopups.append(popup)
            }
        }
    }
    
    func dismiss(_ popup: AppPopup? = nil) {
        guard !activePopups.isEmpty else { return }

        if let popup = popup {
            removeWithAnimation(popup)
        } else if let last = activePopups.last {
            removeWithAnimation(last)
        }
    }
    
    func dismissTop() {
        if let last = activePopups.last {
            removeWithAnimation(last)
        }
    }

    private func removeWithAnimation(_ popup: AppPopup) {
        guard let index = activePopups.firstIndex(of: popup) else { return }
        activePopups.remove(at: index)
        disappearingPopups.append(popup)

        // ✅ 延迟清除，给 transition 动画时间
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.disappearingPopups.removeAll { $0 == popup }
        }
    }
}
