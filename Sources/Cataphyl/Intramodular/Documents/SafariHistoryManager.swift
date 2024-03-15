//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow
import SQLite3

public struct SafariHistoryRecord: Codable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let timestamp: Date
    public let url: String
    public let title: String?
    public let visitCount: Int?
    public let lastVisitTime: Date?
}

public final class SafariHistoryManager {
    private let fileManager = FileManager.default
    private let historyURL: URL?

    public init(
        historyURL: URL? = nil
    ) {
        self.historyURL = historyURL
    }
    
    public func fetchHistory() async throws -> [SafariHistoryRecord] {
        let databaseURL = self.historyURL ?? URL.homeDirectory.appending("Library/Safari")
        let result = try FileManager.default.withUserGrantedAccess(
            to: databaseURL,
            scope: .directory
        ) { url in
            try fileManager.withTemporaryCopy(of: url) { url in
                try querySafariHistory(fromSafariDirectoryCopy: url)
            }
        }
        
        return result
    }
    
    private func querySafariHistory(
        fromSafariDirectoryCopy safariDirectory: URL
    ) throws -> [SafariHistoryRecord] {
        let databaseURL = safariDirectory.appending(.file("History.db"))
        
        assert(fileManager.fileExists(at: databaseURL) && fileManager.isReadable(at: databaseURL))
        assert(databaseURL.lastPathComponent.hasSuffix("History.db"))
        
        var database: OpaquePointer?
        
        guard sqlite3_open_v2(databaseURL.path, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            throw SafariHistoryManagerError.failedToOpenDatabase
        }
        
        defer {
            sqlite3_close(database)
        }
        
        let query = """
            SELECT i.id, datetime(h.visit_time + 978307200, 'unixepoch', 'localtime') AS timestamp, i.url, h.title, i.visit_count, datetime(h.visit_time + 978307200, 'unixepoch', 'localtime') AS lastVisitTime
            FROM history_visits h
            INNER JOIN history_items i ON h.history_item = i.id;
            """

        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else {
            throw SafariHistoryManagerError.failedToQueryDatabase
        }
        
        var records: [SafariHistoryRecord] = []
        
        defer {
            sqlite3_finalize(statement)
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(statement, 0))
            let timestamp = String(cString: sqlite3_column_text(statement, 1)).toDate()
            let url = String(cString: sqlite3_column_text(statement, 2))
            let title = sqlite3_column_text(statement, 3).flatMap { String(cString: $0) }
            let visitCount = Int(sqlite3_column_int(statement, 4))
            let lastVisitTime = String(cString: sqlite3_column_text(statement, 5)).toDate()

            records.append(
                SafariHistoryRecord(
                    id: id,
                    timestamp: timestamp,
                    url: url,
                    title: title,
                    visitCount: visitCount,
                    lastVisitTime: lastVisitTime
                )
            )
        }
        
        return records
    }
    
    private func fetchSystemUsers() throws -> [SystemUser] {
        let usersDirectory = URL(fileURLWithPath: "/Users")
        let userDirectories = try fileManager.contentsOfDirectory(atPath: usersDirectory.path)
        
        return userDirectories
            .filter({ $0 != "Shared" })
            .map {
                SystemUser(
                    username: $0,
                    homeDirectory: usersDirectory.appendingPathComponent($0).path
                )
            }
    }
}

// MARK: - Auxiliary

public enum SafariHistoryManagerError: Error {
    case failedToOpenDatabase
    case failedToQueryDatabase
}

extension SafariHistoryManager {
    private struct SystemUser {
        let username: String
        let homeDirectory: String
    }
}

extension String {
    fileprivate func toDate() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: self) ?? Date()
    }
}
