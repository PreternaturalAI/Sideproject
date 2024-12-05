//
//  File.swift
//  Sideproject
//
//  Created by Purav Manot on 29/11/24.
//

import Foundation

extension ModelStore {
    public struct Model: Codable, Hashable, Identifiable, Sendable {
        public typealias ID = String
        
        public var name: String
        public var url: URL?
        public var lastUsed: Date?
        public var expectedFilenames: [String]?
        
        public var id: ID {
            name
        }
        
        public var displayName: String {
            url?.lastPathComponent ?? name
        }
        
        public var size: Int64? {
            guard let url = url else { return nil }
            
            return FileManager.default.directorySize(url: url)
        }
        
        public var sizeDescription: String {
            guard let size = size else { return "--" }
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useGB, .useMB]
            formatter.countStyle = .file
            let string = formatter.string(fromByteCount: size)
            
            return "\(string) on disk"
        }
        
        public var isOnDisk: Bool {
            guard let expectedFilenames = expectedFilenames else { return false }
            guard let url = url else { return false }
            guard let resourceValues: URLResourceValues = (try? url.resourceValues(forKeys: [.isDirectoryKey])) else { return false }
            guard (resourceValues.isDirectory ?? false) else { return false }
            
            guard let contents = try? FileManager.default.contentsOfDirectory(atPath: url.path()) else { return false }
            
            return Set(contents) == Set(expectedFilenames) || Set(contents).isSuperset(of: Set(expectedFilenames))
        }
    }
}
