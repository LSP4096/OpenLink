//
//  Color+Extensions.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import SwiftUI
import UIKit

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:  // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    static let mainBackground = Color(hex: "#1C2F2C")
}

extension UIColor {

    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // 处理 "#"
        if hexSanitized.hasPrefix("#") {
            hexSanitized.remove(at: hexSanitized.startIndex)
        }

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            self.init(white: 1.0, alpha: 1.0)  // 默认白色
            return
        }

        let length = hexSanitized.count
        switch length {
        case 6:  // #RRGGBB
            let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(rgb & 0x0000FF) / 255.0
            self.init(red: r, green: g, blue: b, alpha: alpha)
        case 8:  // #AARRGGBB
            let a = CGFloat((rgb & 0xFF00_0000) >> 24) / 255.0
            let r = CGFloat((rgb & 0x00FF_0000) >> 16) / 255.0
            let g = CGFloat((rgb & 0x0000_FF00) >> 8) / 255.0
            let b = CGFloat(rgb & 0x0000_00FF) / 255.0
            self.init(red: r, green: g, blue: b, alpha: a)
        default:
            self.init(white: 1.0, alpha: 1.0)  // 默认白色
        }
    }

}
