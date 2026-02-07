import Foundation
import GRDB

enum RdbXc1 {
    static let w7a2bShared = mkS9d()

    private static func mkS9d() -> any DatabaseWriter {
        do {
            try FileManager.default.createDirectory(at: FilePath.sharedDirectory, withIntermediateDirectories: true)

            let dbPath = FilePath.sharedDirectory
                .appendingPathComponent("settings.db")
                .relativePath

            let dbPool = try DatabasePool(path: dbPath)
            var migrator = DatabaseMigrator().disablingDeferredForeignKeyChecks()

            migrator.registerMigration("initialize") { db in
                try db.create(table: "profiles") { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("name", .text).notNull()
                    t.column("order", .integer).notNull()
                    t.column("type", .integer).notNull().defaults(to: ProfileType.local.rawValue)
                    t.column("path", .text).notNull()
                    t.column("remoteURL", .text)
                    t.column("autoUpdate", .boolean).notNull().defaults(to: false)
                    t.column("lastUpdated", .datetime)
                }

                try db.create(table: "preferences") { t in
                    t.primaryKey("name", .text, onConflict: .replace).notNull()
                    t.column("data", .blob)
                }
            }

            migrator.registerMigration("add_auto_update_interval") { db in
                try db.alter(table: "profiles") { t in
                    t.add(column: "autoUpdateInterval", .integer).notNull().defaults(to: 0)
                }
            }

            try migrator.migrate(dbPool)
            return dbPool
        } catch {
            fatalError("DB_INIT_ERROR: \(error.localizedDescription)")
        }
    }
}
