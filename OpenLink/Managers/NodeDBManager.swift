//
//  NodeDBManager.swift
//  OpenLink
//
//  Created by eleven on 2026/2/7.
//

import Foundation
import GRDB

class NodeDBManager {
    static let shared = NodeDBManager()
    
    private var dbQueue: DatabaseQueue?
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            let fileManager = FileManager.default
            let dbFolder = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("database", isDirectory: true)
            
            if !fileManager.fileExists(atPath: dbFolder.path) {
                try fileManager.createDirectory(at: dbFolder, withIntermediateDirectories: true)
            }
            
            let dbPath = dbFolder.appendingPathComponent("nodes.sqlite").path
            dbQueue = try DatabaseQueue(path: dbPath)
            
            try dbQueue?.write { db in
                try db.create(table: NodeModel.databaseTableName, ifNotExists: true) { t in
                    t.column("id", .integer).primaryKey()
                    t.column("name_input", .text)
                    t.column("chinese_simplified", .text)
                    t.column("chinese_traditional", .text)
                    t.column("english", .text)
                    t.column("city", .text)
                    t.column("country", .text)
                    t.column("version", .text)
                    t.column("type", .text)
                    t.column("mode", .text)
                    t.column("path", .text)
                    t.column("domain_name", .text)
                    t.column("request_address", .text)
                    t.column("tag_ids", .text)
                    t.column("flag", .text)
                    t.column("tags", .blob) // Stored as JSON blob/text
                    t.column("children", .blob) // Stored as JSON blob/text
                    t.column("sort_index", .integer) // New column for ordering
                }
                
                // Safety migration: add column if it doesn't exist for existing users
                if try !db.tableExists(NodeModel.databaseTableName) || !db.columns(in: NodeModel.databaseTableName).contains(where: { $0.name == "sort_index" }) {
                    try db.alter(table: NodeModel.databaseTableName) { t in
                        t.add(column: "sort_index", .integer).defaults(to: 0)
                    }
                }
            }
            olog("📁 Database setup successful at: \(dbPath)")
        } catch {
            olog("❌ Database setup failed: \(error)")
        }
    }
    
    // MARK: - Operations
    
    func saveNodes(_ nodes: [NodeModel]) {
        guard let dbQueue = dbQueue else { return }
        
        do {
            try dbQueue.write { db in
                // Clear existing nodes for full replacement
                try NodeModel.deleteAll(db)
                
                for (index, var node) in nodes.enumerated() {
                    node.sortIndex = index // Assign server order
                    try node.insert(db)
                }
            }
            olog("✅ Saved \(nodes.count) nodes to database with server order.")
        } catch {
            olog("❌ Save nodes to DB failed: \(error)")
        }
    }
    
    func getAllNodes() -> [NodeModel] {
        guard let dbQueue = dbQueue else { return [] }
        
        do {
            let nodes = try dbQueue.read { db in
                // Order by sortIndex to maintain server order
                try NodeModel.order(NodeModel.Columns.sortIndex).fetchAll(db)
            }
            return nodes
        } catch {
            olog("❌ Fetch nodes from DB failed: \(error)")
            return []
        }
    }
    
    func deleteAllNodes() {
        guard let dbQueue = dbQueue else { return }
        do {
            _ = try dbQueue.write { db in
                try NodeModel.deleteAll(db)
            }
        } catch {
            olog("❌ Delete nodes from DB failed: \(error)")
        }
    }
}
