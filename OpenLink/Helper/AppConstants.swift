//
//  AppConstants.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import Foundation
import UIKit

struct AppConstants {
    
    static var apnsDeviceToken = ""
    
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    
    static let appStoreUrl = "https://apps.apple.com/app/id6757798853"
    
    static func isMac() -> Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if #available(iOS 14.0, *) {
                return ProcessInfo.processInfo.isiOSAppOnMac
            }
        }
        return false
    }
    
    static var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isPadOrMac: Bool {
        return isPad || isMac()
    }
        
    // 用户条款
    static var userTermsUrl: String {
        switch LanguageManager.shared.appLan {
        case "zh-Hans": return "https://cdn.ajiasu.uk/agreement/UserTerms_zh-Hans.html"
        case "zh-HK": return "https://cdn.ajiasu.uk/agreement/UserTerms_zh-Hant.html"
        case "en": return "https://cdn.ajiasu.uk/agreement/UserTerms_en.html"
        default: return "https://cdn.ajiasu.uk/agreement/UserTerms_zh-Hans.html"
        }
    }
    
    // 隐私协议
    static var privacyAgreementUrl: String {
        switch LanguageManager.shared.appLan {
        case "zh-Hans": return "https://cdn.ajiasu.uk/agreement/PrivacyAgreement_zh-Hans.html"
        case "zh-HK": return "https://cdn.ajiasu.uk/agreement/PrivacyAgreement_zh-Hant.html"
        case "en": return "https://cdn.ajiasu.uk/agreement/PrivacyAgreement_en.html"
        default: return "https://cdn.ajiasu.uk/agreement/PrivacyAgreement_zh-Hans.html"
        }
    }

    // 自动续费协议
    static var autoSubscribeUrl: String {
        switch LanguageManager.shared.appLan {
        case "zh-Hans": return "https://cdn.ajiasu.uk/agreement/AutomaticRenewalAgreement_zh-Hans.html"
        case "zh-HK": return "https://cdn.ajiasu.uk/agreement/AutomaticRenewalAgreement_zh-Hant.html"
        case "en": return "https://cdn.ajiasu.uk/agreement/AutomaticRenewalAgreement_en.html"
        default: return "https://cdn.ajiasu.uk/agreement/AutomaticRenewalAgreement_zh-Hans.html"
        }
    }

    // 会员服务协议
    static var subscribeUrl: String {
        switch LanguageManager.shared.appLan {
        case "zh-Hans": return "https://cdn.ajiasu.uk/agreement/MembershipServiceAgreement_zh-Hans.html"
        case "zh-HK": return "https://cdn.ajiasu.uk/agreement/MembershipServiceAgreement_zh-Hant.html"
        case "en": return "https://cdn.ajiasu.uk/agreement/MembershipServiceAgreement_en.html"
        default: return "https://cdn.ajiasu.uk/agreement/MembershipServiceAgreement_zh-Hans.html"
        }
    }
}
