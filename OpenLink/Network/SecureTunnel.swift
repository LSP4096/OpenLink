
import Foundation
import CryptoKit
import CommonCrypto

class SecureTunnel {

    private static let key = "sdgyuwgrikabdg@2@"

    static func generatePath(unixWithNoMillis: String) -> String {
        let str = key + unixWithNoMillis
        let hashData = SHA256.hash(data: Data(str.utf8))
        let hashBytes = Array(hashData)
        let hashHex = hashBytes.map { String(format: "%02x", $0) }.joined()
        
        var num = Int(hashBytes[0] % 4)
        if num == 0 { num = 4 }
        
        var parts: [String] = []
        for i in 1...num {
            var k = Int(hashBytes[i] % 5)
            if k == 0 { k = 5 }
            
            let start = i * 10
            let end = start + k

            if end <= hashHex.count {
                let startIdx = hashHex.index(hashHex.startIndex, offsetBy: start)
                let endIdx = hashHex.index(hashHex.startIndex, offsetBy: end)
                let v = String(hashHex[startIdx..<endIdx])
                parts.append(v)
            }
        }
        
        return "/" + parts.joined(separator: "/")
    }

    static func confusePath(path: String) -> String {
        let segments = path.split(separator: "/")
        var newSegments: [String] = []
        
        for v in segments {
            let s = String(v)
            if s.isEmpty { continue }
            
            let len = Double(s.count)
            let leftLen = Int(round(len / 2.0))
            let rightLen = s.count - leftLen
            
            let leftRand = randomString(length: leftLen)
            let rightRand = randomString(length: rightLen)
            
            newSegments.append(leftRand + s + rightRand)
        }
        
        return "/" + newSegments.joined(separator: "/")
    }

    static func removeConfusePath(path: String) -> String {
        let segments = path.split(separator: "/")
        var newSegments: [String] = []
        
        for v in segments {
            let s = String(v)
            if s.isEmpty || s.count % 2 != 0 { continue }
            
            let oLen = s.count / 2
            let leftLen = Int(round(Double(oLen) / 2.0))
            let rightLen = oLen - leftLen

            let startIndex = s.index(s.startIndex, offsetBy: leftLen)
            let endIndex = s.index(s.endIndex, offsetBy: -rightLen)
            
            if startIndex <= endIndex {
                let realSeg = String(s[startIndex..<endIndex])
                newSegments.append(realSeg)
            }
        }
        
        return "/" + newSegments.joined(separator: "/")
    }

    static func encrypt(text: String, unix: String) -> String? {
        
        let keyMaterial = key + unix
        let keyHash = SHA256.hash(data: Data(keyMaterial.utf8))
        let symmetricKey = SymmetricKey(data: keyHash)

        guard let plainData = text.data(using: .utf8) else { return nil }
        
        do {

            let sealedBox = try AES.GCM.seal(plainData, using: symmetricKey)
            
            if let combined = sealedBox.combined {
                return combined.base64EncodedString()
            }
        } catch {
            print("Encryption Error: \(error)")
        }
        return nil
    }

    static func decrypt(base64Str: String, unix: String) -> String? {
        
        let keyMaterial = key + unix
        let keyHash = SHA256.hash(data: Data(keyMaterial.utf8))
        let symmetricKey = SymmetricKey(data: keyHash) 

        guard let data = Data(base64Encoded: base64Str) else {
            
            return nil
        }

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            
            return nil
        }
    }

    static func tryDecryptResponse(_ text: String, currentUnix: String) -> (String, String)? {
        let windows = getMinuteWindow(currentUnix: currentUnix)

        var candidate = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !looksLikeBase64(candidate) {
            if let extracted = pickCipherFromJSON(text) {
                candidate = extracted
            }
        }
        
        if !looksLikeBase64(candidate) {
            return nil 
        }

        for unix in windows {
            if let plain = decrypt(base64Str: candidate, unix: unix) {
                return (plain, unix)
            }
        }
        
        return nil
    }

    static var timeOffset: TimeInterval = 0

    static func getUtcMinuteString() -> String {
        let date = Date().addingTimeInterval(timeOffset)
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:00'Z'" 
        return formatter.string(from: date)
    }

    static func probeServerTimeOffset(encryptedResponse: String) -> TimeInterval? {
        let current = Date()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:00'Z'"

        let likelyOffsets: [Int] = [0, 480, -480] 
        for minOffset in likelyOffsets {
            if let result = checkOffset(minutes: minOffset, current: current, formatter: formatter, encrypted: encryptedResponse) {
                return result
            }
        }

        let rangeMinutes = 720
        
        for i in -rangeMinutes...rangeMinutes {
            if likelyOffsets.contains(i) { continue }
            if let result = checkOffset(minutes: i, current: current, formatter: formatter, encrypted: encryptedResponse) {
                return result
            }
        }
        
        return nil
    }
    
    private static func checkOffset(minutes: Int, current: Date, formatter: DateFormatter, encrypted: String) -> TimeInterval? {
        let offset = TimeInterval(minutes * 60)
        let probeDate = current.addingTimeInterval(offset)
        let probeUnix = formatter.string(from: probeDate)
        
        if let _ = decrypt(base64Str: encrypted, unix: probeUnix) {
            print("✅ [SecureTunnel] Auto-detected server time offset: \(minutes) minutes (\(offset)s)")
            return offset
        }
        return nil
    }
    
    static func getMinuteWindow(currentUnix: String) -> [String] {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:00'Z'"
        
        guard let date = formatter.date(from: currentUnix) else {
            return [currentUnix]
        }
        
        let prev = date.addingTimeInterval(-60)
        let next = date.addingTimeInterval(60)
        
        return [
            currentUnix,
            formatter.string(from: prev),
            formatter.string(from: next)
        ]
    }
    
    private static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    private static func looksLikeBase64(_ s: String) -> Bool {
        if s.count < 16 { return false }
        
        let base64Chars = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=_-\n\r")
        return s.unicodeScalars.allSatisfy { base64Chars.contains($0) }
    }
    
    private static func pickCipherFromJSON(_ jsonStr: String) -> String? {
        guard let data = jsonStr.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        
        let candidates = ["cipher", "ciphertext", "data", "result", "payload"]

        for key in candidates {
            if let val = json[key] as? String, !val.isEmpty { return val }
        }

        if let nestedData = json["data"] as? [String: Any] {
            for key in candidates {
                if let val = nestedData[key] as? String, !val.isEmpty { return val }
            }
        }
        
        return nil
    }
}

struct RewriteParam: Codable {
    let method: String
    let url: String
    let param: [String: AnyCodable]? 
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Int.self) { value = x }
        else if let x = try? container.decode(Double.self) { value = x }
        else if let x = try? container.decode(String.self) { value = x }
        else if let x = try? container.decode(Bool.self) { value = x }
        else if let x = try? container.decode([AnyCodable].self) { value = x.map { $0.value } }
        else if let x = try? container.decode([String: AnyCodable].self) { value = x.mapValues { $0.value } }
        else {
             value = "" 
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let x = value as? Int { try container.encode(x) }
        else if let x = value as? String { try container.encode(x) }
        else if let x = value as? Bool { try container.encode(x) }
        else if let x = value as? Double { try container.encode(x) }
        else if let x = value as? [Any] {
            try container.encode(x.map { AnyCodable($0) })
        }
        else if let x = value as? [String: Any] {
            try container.encode(x.mapValues { AnyCodable($0) })
        }
        else {
            let stringVal = "\(value)"
            try container.encode(stringVal)
        }
    }
}
