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
            guard let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey]),
                  resourceValues.isDirectory == true else { return false }
            
            for expectedFilename in expectedFilenames {
                let fileURL = url.appendingPathComponent(expectedFilename)
                if !FileManager.default.fileExists(atPath: fileURL.path) {
                    return false
                }
            }
            
            return true
        }
    }
}

extension FileManager {
    func getAllFilePaths(atPath path: String) -> [String] {
        var filePaths: [String] = []
        
        do {
            let contents = try self.contentsOfDirectory(atPath: path)
            for content in contents {
                let fullPath = (path as NSString).appendingPathComponent(content)
                var isDirectory: ObjCBool = false
                
                if self.fileExists(atPath: fullPath, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        // Recursively fetch contents of the directory
                        let subdirectoryPaths = getAllFilePaths(atPath: fullPath)
                        filePaths.append(contentsOf: subdirectoryPaths.map { "\(content)/\($0)" })
                    } else {
                        // Add file path relative to the given path
                        filePaths.append(content)
                    }
                }
            }
        } catch {
            print("Error reading contents of directory: \(error.localizedDescription)")
        }
        
        return filePaths
    }
}
