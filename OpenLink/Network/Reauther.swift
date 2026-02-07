//
//  Reauther.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import Foundation

actor Reauther {
    private var isReauthenticating = false
    private var lastAuthTime: Date?

    func startIfNeeded(action: @escaping @Sendable () async -> Void) async {
        let now = Date()

        // 若刚刚执行过 5 秒内的登录，不再重复触发
        if let last = lastAuthTime, now.timeIntervalSince(last) < 5 {
            return
        }

        guard !isReauthenticating else {
            return
        }

        isReauthenticating = true
        lastAuthTime = now


        Task(priority: .high) {
            defer {
                Task { self.finish() }
            }
            await action()
        }
    }

    private func finish() {
        isReauthenticating = false
    }
}
