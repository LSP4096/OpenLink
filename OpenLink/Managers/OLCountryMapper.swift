//
//  OLCountryMapper.swift
//  OpenLink
//
//  Created by eleven on 2026/2/7.
//

import Foundation

class OLCountryMapper {
    static let shared = OLCountryMapper()
    
    private let countryCodeMap: [String: String] = [
        "United States": "US", "USA": "US", "美国": "US",
        "United Kingdom": "GB", "UK": "GB", "英国": "GB",
        "China": "CN", "中国": "CN",
        "Hong Kong": "HK", "HK": "HK", "香港": "HK",
        "Taiwan": "TW", "TW": "TW", "台湾": "TW",
        "Japan": "JP", "日本": "JP",
        "Singapore": "SG", "新加坡": "SG",
        "Korea": "KR", "South Korea": "KR", "韩国": "KR",
        "Germany": "DE", "德国": "DE",
        "France": "FR", "法国": "FR",
        "Canada": "CA", "加拿大": "CA",
        "Australia": "AU", "澳大利亚": "AU", "澳洲": "AU",
        "Russia": "RU", "俄罗斯": "RU",
        "India": "IN", "印度": "IN",
        "Brazil": "BR", "巴西": "BR",
        "Netherlands": "NL", "荷兰": "NL",
        "Italy": "IT", "意大利": "IT",
        "Spain": "ES", "西班牙": "ES",
        "Turkey": "TR", "土耳其": "TR",
        "Vietnam": "VN", "越南": "VN",
        "Thailand": "TH", "泰国": "TH",
        "Indonesia": "ID", "印尼": "ID", "印度尼西亚": "ID",
        "Malaysia": "MY", "马来西亚": "MY",
        "Philippines": "PH", "菲律宾": "PH",
        "Switzerland": "CH", "瑞士": "CH",
        "Sweden": "SE", "瑞典": "SE",
        "Norway": "NO", "挪威": "NO",
        "Denmark": "DK", "丹麦": "DK",
        "Finland": "FI", "芬兰": "FI",
        "Poland": "PL", "波兰": "PL",
        "Austria": "AT", "奥地利": "AT",
        "Belgium": "BE", "比利时": "BE",
        "Ireland": "IE", "爱尔兰": "IE",
        "Portugal": "PT", "葡萄牙": "PT",
        "Greece": "GR", "希腊": "GR",
        "Ukraine": "UA", "乌克兰": "UA",
        "South Africa": "ZA", "南非": "ZA",
        "Israel": "IL", "以色列": "IL",
        "United Arab Emirates": "AE", "UAE": "AE", "阿联酋": "AE",
        "Saudi Arabia": "SA", "沙特阿拉伯": "SA",
        "Argentina": "AR", "阿根廷": "AR",
        "Mexico": "MX", "墨西哥": "MX",
        "New Zealand": "NZ", "新西兰": "NZ"
    ]
    
    func getIsoCode(from countryName: String?) -> String? {
        guard let name = countryName, !name.isEmpty else { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Direct match
        if let code = countryCodeMap[trimmed] {
            return code
        }
        
        // Exact case match
        for (key, code) in countryCodeMap {
            if trimmed.localizedCaseInsensitiveContains(key) {
                return code
            }
        }
        
        return nil
    }
}
