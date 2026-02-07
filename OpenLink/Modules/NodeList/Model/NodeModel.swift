//
//  NodeModel.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import Foundation
import SwiftyJSON
import GRDB

struct NodeTag: Codable, Hashable, FetchableRecord, PersistableRecord {
    var dictLabel: String
    var dictValue: String

    enum CodingKeys: String, CodingKey {
        case dictLabel = "dict_label"
        case dictValue = "dict_value"
    }
}

struct NodeModel: Codable, Identifiable, Hashable, FetchableRecord, PersistableRecord {
    var id: Int
    var nameInput: String?
    var chineseSimplified: String?
    var chineseTraditional: String?
    var english: String?
    
    var city: String?
    var country: String?
    var version: String?
    var type: String?
    var mode: String?
    var path: String?
    var domainName: String?
    var requestAddress: String?
    var tagIds: String?
    var flag: String?
    
    var tags: [NodeTag]?
    var children: [NodeModel]?
    
    // UI logic properties (non-codable or computed)
    var ms: Int? = nil // Mocked or logic-calculated latency
    var sortIndex: Int? = 0 // Used for database ordering
    
    var name: String {
        return chineseSimplified ?? nameInput ?? country ?? "Unknown Node"
    }

    var isGroup: Bool {
        return !(children?.isEmpty ?? true)
    }

    var countryCode: String? {
        guard let address = requestAddress else { return nil }
        // Extract IP/host from vless URL: vless://uuid@host:port?...
        if let hostRange = address.range(of: "@"), 
           let portColonRange = address.range(of: ":", range: hostRange.upperBound..<address.endIndex) {
            let host = String(address[hostRange.upperBound..<portColonRange.lowerBound])
            
            let afterColon = address[portColonRange.upperBound...]
            let endOfPort = afterColon.range(of: "?")?.lowerBound ?? afterColon.endIndex
            let port = String(afterColon[..<endOfPort])
            
            return OLIPLocationManager.shared.getCountryCode(for: "\(host):\(port)")
        }
        return nil
    }

    var flagImageName: String {
        if flag == "auto" { return "auto" } // Special case for UI handled in NodeListView
        
        // 1. Try Country field from API
        if let code = OLCountryMapper.shared.getIsoCode(from: country) {
            return code.uppercased()
        }
        
        // 2. Try Name field (local display name)
        if let code = OLCountryMapper.shared.getIsoCode(from: name) {
            return code.uppercased()
        }
        
        // 3. Try IP-based lookup
        if let code = countryCode {
            return code.uppercased()
        }
        
        return "UN"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case nameInput = "name_input"
        case chineseSimplified = "chinese_simplified"
        case chineseTraditional = "chinese_traditional"
        case english
        case city
        case country
        case version
        case type
        case mode
        case path
        case domainName = "domain_name"
        case requestAddress = "request_address"
        case tagIds = "tag_ids"
        case flag
        case tags
        case children
    }
    
    // GRDB Database table configuration
    static let databaseTableName = "node_list"
    
    // Define columns for easier querying if needed
    enum Columns: String, ColumnExpression {
        case id
        case nameInput = "name_input"
        case chineseSimplified = "chinese_simplified"
        case chineseTraditional = "chinese_traditional"
        case english
        case city
        case country
        case version
        case type
        case mode
        case path
        case domainName = "domain_name"
        case requestAddress = "request_address"
        case tagIds = "tag_ids"
        case flag, tags, children
        case sortIndex = "sort_index"
    }
}

// MARK: - GRDB Persistence

extension NodeModel {
    public func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.nameInput] = nameInput
        container[Columns.chineseSimplified] = chineseSimplified
        container[Columns.chineseTraditional] = chineseTraditional
        container[Columns.english] = english
        container[Columns.city] = city
        container[Columns.country] = country
        container[Columns.version] = version
        container[Columns.type] = type
        container[Columns.mode] = mode
        container[Columns.path] = path
        container[Columns.domainName] = domainName
        container[Columns.requestAddress] = requestAddress
        container[Columns.tagIds] = tagIds
        container[Columns.flag] = flag
        container[Columns.sortIndex] = sortIndex
        
        // Manual JSON encoding for arrays
        if let tags = tags, let data = try? JSONEncoder().encode(tags) {
            container[Columns.tags] = data
        } else {
            container[Columns.tags] = nil
        }
        
        if let children = children, let data = try? JSONEncoder().encode(children) {
            container[Columns.children] = data
        } else {
            container[Columns.children] = nil
        }
    }
}

extension NodeModel {
    public init(row: Row) {
        id = row[Columns.id]
        nameInput = row[Columns.nameInput]
        chineseSimplified = row[Columns.chineseSimplified]
        chineseTraditional = row[Columns.chineseTraditional]
        english = row[Columns.english]
        city = row[Columns.city]
        country = row[Columns.country]
        version = row[Columns.version]
        type = row[Columns.type]
        mode = row[Columns.mode]
        path = row[Columns.path]
        domainName = row[Columns.domainName]
        requestAddress = row[Columns.requestAddress]
        tagIds = row[Columns.tagIds]
        flag = row[Columns.flag]
        sortIndex = row[Columns.sortIndex]
        
        // Manual JSON decoding for arrays
        if let data: Data = row[Columns.tags] {
            tags = try? JSONDecoder().decode([NodeTag].self, from: data)
        }
        
        if let data: Data = row[Columns.children] {
            children = try? JSONDecoder().decode([NodeModel].self, from: data)
        }
    }
}
