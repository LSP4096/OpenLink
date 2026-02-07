//
//  OLIPLocationManager.swift
//  OpenLink
//
//  Created by eleven on 2026/2/7.
//

import Foundation

class OLIPLocationManager {
    static let shared = OLIPLocationManager()

    func warmUp(completion: (() -> Void)? = nil) {
        
        if isLoaded {
            completion?()
            return
        }

        loadGroup.notify(queue: .main) {
            completion?()
        }
    }
    
    private var ipv4Ranges: [IPv4Range] = []
    private var ipv6Ranges: [IPv6Range] = []
    
    private var isLoading = false
    private var isLoaded = false

    struct IPv4Range {
        let start: UInt32
        let end: UInt32
        let countryCode: String
    }
    
    struct IPv6Range {
        let start: UInt128
        let end: UInt128
        let countryCode: String
    }

    struct UInt128: Comparable {
        let high: UInt64
        let low: UInt64
        
        static func < (lhs: UInt128, rhs: UInt128) -> Bool {
            if lhs.high != rhs.high {
                return lhs.high < rhs.high
            }
            return lhs.low < rhs.low
        }
        
        static func == (lhs: UInt128, rhs: UInt128) -> Bool {
            return lhs.high == rhs.high && lhs.low == rhs.low
        }
        
        init(high: UInt64, low: UInt64) {
            self.high = high
            self.low = low
        }

        init?(string: String) {
            var h: UInt64 = 0
            var l: UInt64 = 0
            
            for char in string {
                guard let digit = char.wholeNumberValue else { return nil }

                let (_, hLow) = h.multipliedFullWidth(by: 10)
                let (lHigh, lLow) = l.multipliedFullWidth(by: 10)

                let (lowWithDigit, carry) = lLow.addingReportingOverflow(UInt64(digit))
                l = lowWithDigit

                h = hLow &+ lHigh &+ (carry ? 1 : 0)
            }
            self.high = h
            self.low = l
        }
        
        init(stringLiteral: String) {
             var currentHigh: UInt64 = 0
             var currentLow: UInt64 = 0
             
             for char in stringLiteral {
                 if let digit = char.wholeNumberValue {
                     let (_, hLow) = currentHigh.multipliedFullWidth(by: 10)
                     let (lHigh, lLow) = currentLow.multipliedFullWidth(by: 10)
                     
                     let (lowWithDigit, carry) = lLow.addingReportingOverflow(UInt64(digit))
                     currentLow = lowWithDigit
                     currentHigh = hLow &+ lHigh &+ (carry ? 1 : 0)
                 }
             }
             self.high = currentHigh
             self.low = currentLow
        }
    }
    
    private let loadGroup = DispatchGroup()
    
    private init() {
        loadGroup.enter()
        loadDatabases()
    }
    
    private func loadDatabases() {
        guard !isLoading && !isLoaded else { return }
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            defer { self?.loadGroup.leave() }
            
            guard let self = self else { return }
            self.loadIPv4()
            self.loadIPv6()
            self.isLoaded = true
            self.isLoading = false
            olog("✅ [S7IPLocationManager] Databases loaded.")
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .init("S7IPDatabasesLoaded"), object: nil)
            }
        }
    }

    private func loadIPv4() {
        guard let path = Bundle.main.path(forResource: "IP2LOCATION-LITE-DB1", ofType: "CSV") else {
            olog("❌ [S7IPLocationManager] IPv4 DB not found")
            return
        }
        
        do {
            let content = try String(contentsOfFile: path)
            var ranges: [IPv4Range] = []
            ranges.reserveCapacity(270000)
            
            content.enumerateLines { line, _ in
                let parts = line.components(separatedBy: "\",\"")
                if parts.count >= 3 {
                    let startStr = parts[0].replacingOccurrences(of: "\"", with: "")
                    let endStr = parts[1]
                    let code = parts[2]
                    
                    if let start = UInt32(startStr), let end = UInt32(endStr), code != "-" {
                        ranges.append(IPv4Range(start: start, end: end, countryCode: code))
                    }
                }
            }
            self.ipv4Ranges = ranges
            
        } catch {
            olog("❌ [S7IPLocationManager] Failed to load IPv4 DB: \(error)")
        }
    }
    
    private func loadIPv6() {
        guard let path = Bundle.main.path(forResource: "IP2LOCATION-LITE-DB1.IPV6", ofType: "CSV") else {
             if let p2 = Bundle.main.path(forResource: "IP2LOCATION-LITE-DB1.IPV6", ofType: "CSV") {
                 self.parseIPv6(path: p2)
             } else {
                 olog("❌ [S7IPLocationManager] IPv6 DB not found")
             }
             return
        }
        self.parseIPv6(path: path)
    }
    
    private func parseIPv6(path: String) {
        do {
            let content = try String(contentsOfFile: path)
            var ranges: [IPv6Range] = []
            ranges.reserveCapacity(670000)
            
            content.enumerateLines { line, _ in
                let parts = line.components(separatedBy: "\",\"")
                if parts.count >= 3 {
                    let startStr = parts[0].replacingOccurrences(of: "\"", with: "")
                    let endStr = parts[1]
                    let code = parts[2]
                    
                    if code != "-" {
                        let start = UInt128(stringLiteral: startStr)
                        let end = UInt128(stringLiteral: endStr)
                        ranges.append(IPv6Range(start: start, end: end, countryCode: code))
                    }
                }
            }
            self.ipv6Ranges = ranges
            
        } catch {
             olog("❌ [S7IPLocationManager] Failed to load IPv6 DB: \(error)")
        }
    }
    
    func getCountryCode(for rawIP: String) -> String? {
        
        var ip = rawIP
        if ip.contains("[") {
             if let endBracket = ip.firstIndex(of: "]") {
                 let start = ip.index(after: ip.startIndex)
                 ip = String(ip[start..<endBracket])
             }
        } else {
             
             if let colonIndex = ip.lastIndex(of: ":") {
                 let colons = ip.filter { $0 == ":" }.count

                 if colons > 1 {
                     
                 } else {
                     
                     ip = String(ip[..<colonIndex])
                 }
             }
        }
        ip = ip.trimmingCharacters(in: .whitespacesAndNewlines)

        let ipv4Val = ipv4ToInt(ip)
        let ipv6Val = ipv4Val == nil ? ipv6ToInt(ip) : nil
        
        if ipv4Val == nil && ipv6Val == nil {
            
             olog("ℹ️ [S7IPLocationManager] Invalid IP or Domain: '\(rawIP)' -> Parsed: '\(ip)'. Skipping lookup.")
            return nil
        }

        if !isLoaded {
             let result = loadGroup.wait(timeout: .now() + 5.0)
             if result == .timedOut {
                 olog("⚠️ [S7IPLocationManager] DB Load Timed Out for \(rawIP)")
                 return nil
             }
        }

        let result: String?
        if let v4 = ipv4Val {
            result = getIPv4IsoCode(from: v4)
        } else if let v6 = ipv6Val {
            result = getIPv6IsoCode(from: v6)
        } else {
            result = nil
        }
        
        olog("🔍 [S7IPLocationManager] Lookup: '\(rawIP)' -> Result: \(result ?? "nil")")
        return result
    }

    private func getIPv4IsoCode(from ipInt: UInt32) -> String? {
        var lower = 0
        var upper = ipv4Ranges.count - 1
        
        while lower <= upper {
            let mid = (lower + upper) / 2
            let range = ipv4Ranges[mid]
            if ipInt >= range.start && ipInt <= range.end {
                return range.countryCode
            } else if ipInt < range.start {
                upper = mid - 1
            } else {
                lower = mid + 1
            }
        }
        return nil
    }
    
    private func getIPv6IsoCode(from ipInt: UInt128) -> String? {
         guard !ipv6Ranges.isEmpty else { return nil }
         var lower = 0
         var upper = ipv6Ranges.count - 1
         
         while lower <= upper {
             let mid = (lower + upper) / 2
             let range = ipv6Ranges[mid]
             if ipInt >= range.start && ipInt <= range.end {
                 return range.countryCode
             } else if ipInt < range.start {
                 upper = mid - 1
             } else {
                 lower = mid + 1
             }
         }
         return nil
    }

    private func ipv4ToInt(_ ip: String) -> UInt32? {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return nil }
        
        var result: UInt32 = 0
        for part in parts {
            guard let octet = UInt8(part) else { return nil }
            result = (result << 8) + UInt32(octet)
        }
        return result
    }

    private func ipv6ToInt(_ ip: String) -> UInt128? {
         var addr = in6_addr()
         let result = ip.withCString { ptr in
             return inet_pton(AF_INET6, ptr, &addr)
         }
         
         if result == 1 {
             return withUnsafeBytes(of: addr) { ptr -> UInt128? in
                 guard let base = ptr.baseAddress else { return nil }
                 
                 let high = base.load(fromByteOffset: 0, as: UInt64.self).bigEndian
                 let low = base.load(fromByteOffset: 8, as: UInt64.self).bigEndian
                 return UInt128(high: high, low: low)
             }
         }
         return nil
    }
}
