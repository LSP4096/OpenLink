//
//  LanguageManager.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @AppStorage(UserDefaultsKeys.language) var appLan: String = "zh-Hans" {
        didSet {
            Bundle.setLanguage(appLan)
            objectWillChange.send()
        }
    }

    var locale: Locale {
        return Locale(identifier: appLan)
    }

    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: UserDefaultsKeys.language) {
            appLan = savedLanguage
        } else {
            // Detect system language
            let preferredLang = Locale.preferredLanguages.first ?? "zh-Hans"
            if preferredLang.hasPrefix("en") {
                appLan = "en"
            } else if preferredLang.hasPrefix("zh-Hant") || preferredLang.hasPrefix("zh-HK") || preferredLang.hasPrefix("zh-TW") {
                appLan = "zh-HK"
            } else {
                appLan = "zh-Hans"
            }
        }
        Bundle.setLanguage(appLan)
    }

    var currentLanName: String {
        return nameFor(lan: appLan)
    }

    func nameFor(lan: String) -> String {
        switch lan {
        case "zh-Hans": return "简体中文"
        case "zh-HK": return "繁体中文"
        case "en": return "English"
        default: return "简体中文"
        }
    }
}

private var bundleKey: UInt8 = 0

extension Bundle {
    class func setLanguage(_ language: String) {
        defer { object_setClass(Bundle.main, PrivateBundle.self) }
        objc_setAssociatedObject(
            Bundle.main, &bundleKey, language,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private class PrivateBundle: Bundle, @unchecked Sendable {
        override func localizedString(
            forKey key: String,
            value: String?,
            table tableName: String?
        ) -> String {
            guard let language =
                objc_getAssociatedObject(self, &bundleKey) as? String,
                let path = self.path(forResource: language, ofType: "lproj"),
                let bundle = Bundle(path: path) else {
                return super.localizedString(
                    forKey: key, value: value, table: tableName)
            }
            return bundle.localizedString(
                forKey: key, value: value, table: tableName)
        }
    }
}

extension String {
    func localized(_ args: CVarArg...) -> String {
        let language = LanguageManager.shared.appLan
        let format: String
        if let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            format = bundle.localizedString(forKey: self, value: self, table: nil)
        } else {
            format = NSLocalizedString(self, comment: "")
        }

        if args.isEmpty {
            return format
        }
        return String(format: format, arguments: args)
    }
}
