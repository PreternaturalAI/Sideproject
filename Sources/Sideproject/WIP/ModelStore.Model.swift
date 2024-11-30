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
        public var state: DownloadState
        public var lastUsed: Date?
        
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
        
        public var isDownloading: Bool {
            switch state {
                case .downloading: return true
                default: return false
            }
        }
        
        public var isOnDisk: Bool {
            guard let resourceValues: URLResourceValues = (try? url?.resourceValues(forKeys: [.isDirectoryKey])) else { return false }
            return resourceValues.isDirectory ?? false
        }
        
        public var downloadProgess: Double {
            switch state {
                case .downloading(let progress):
                    return progress
                default:
                    return 0.0
            }
        }
        
        public enum DownloadState: Codable, Hashable, Sendable {
            case notDownloaded
            case downloading(progress: Double)
            case downloaded
            case failed(String)
        }
    }
}
