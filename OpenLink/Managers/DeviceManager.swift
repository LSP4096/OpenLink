//
//  DeviceManager.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import Foundation
import SwiftUI

// MARK: - DeviceModel

struct DeviceModel: Codable {
    var id: Int
    var user: String
    var token: String
    var is_vip: Int
    var expire_at: Int64
    var account: String
    var is_tourist: Int
    var phone: String?
    var email: String?
    var register_device: String?
    var login_device: String?
    
    // Compatibility fields if needed
    var nickname: String? { user }
    var user_id: Int { id }
}

// MARK: - DeviceManager

class DeviceManager: ObservableObject {
    static let shared = DeviceManager()
    private let fileName = "device.json"
    private let deviceIdKey = "deviceid"
    
    @Published var device: DeviceModel? = nil
    
    private init() {
        self.device = getDeviceInfo()
    }

    // 存储用户信息
    func saveDeviceInfo(_ device: DeviceModel) {
        DispatchQueue.main.async {
            self.device = device
        }
        
        // 存储 Token 供 NetworkHelper 使用
        UserDefaults.standard.set(device.token, forKey: UserDefaultsKeys.imieToken)
        
        let path = getFilePath(fileName)
        if let data = try? JSONEncoder().encode(device) {
            try? data.write(to: path)
        }
    }

    // 读取用户信息
    func getDeviceInfo() -> DeviceModel? {
        let path = getFilePath(fileName)
        if let data = try? Data(contentsOf: path) {
            return try? JSONDecoder().decode(DeviceModel.self, from: data)
        }
        return nil
    }

    // 删除信息
    func deleteDeviceInfo() async {
        await MainActor.run {
            self.device = nil
        }
        let path = getFilePath(fileName)
        try? FileManager.default.removeItem(at: path)
    }

    // 获取路径
    private func getFilePath(_ fileName: String) -> URL {
        return FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        ).first!
        .appendingPathComponent(fileName)
    }
    
    // 设备是否绑定账号
    func isBindAccount() -> Bool {
        guard let device else {
            return false
        }
        
        let noPhone = device.phone?.isEmpty ?? true
        let noEmail = device.email?.isEmpty ?? true
        if noPhone && noEmail {
            return false
        }
        return true
    }
    
    
    // ---------  唯一设备码  ---------
    /// 获取设备唯一 ID
    func getDeviceID() -> String {
        // 先从 Keychain 读取
        if let storedID = KeychainHelper.shared.load(deviceIdKey) {
            return storedID
        }
        
        // 生成唯一 ID
        let newID = generateUniqueID()
        
        // 存入 Keychain
        KeychainHelper.shared.save(deviceIdKey, value: newID)
        
        return newID
    }
    
    /// 生成唯一 ID
    private func generateUniqueID() -> String {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
            return "\(uuid)-\(timestamp)"
        } else {
            return "\(randomString(length: 16))-\(timestamp)"
        }
    }
    
    /// 生成随机字符串（用于无法获取 UUID 的情况）
    private func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
}

// MARK: - Keychain

class KeychainHelper {
    static let shared = KeychainHelper()
    
    private init() {}
    
    /// 保存数据到 Keychain
    func save(_ key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data
        ] as [CFString: Any]
        
        SecItemDelete(query as CFDictionary) // 先删除旧数据
        SecItemAdd(query as CFDictionary, nil)
    }
    
    /// 从 Keychain 读取数据
    func load(_ key: String) -> String? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as [CFString: Any]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        
        if let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
