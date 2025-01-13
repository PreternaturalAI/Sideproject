//
//  File.swift
//  Sideproject
//
//  Created by Purav Manot on 28/11/24.
//

import Foundation
import CorePersistence
import HuggingFace


public extension ModelStore {
    class HuggingFaceDownloadManager {
        public enum DownloadState: Codable, Hashable, Sendable {
            case notStarted
            case downloading(progress: Double)
            case paused(progress: Double)
            case completed(URL)
            case failed(String)
        }
        
        @FileStorage(
            .appDocuments,
            path: "SideProjectExample/downloads.json",
            coder: .json,
            options: .init(readErrorRecoveryStrategy: .discardAndReset)
        )
        var downloads: [ModelStore.Model.ID: ModelStore.Download]

        func download(
            repo: HuggingFace.Hub.Repo,
            files: [String],
            destination: URL,
            hfToken: String?
        ) -> Download {
            let id = repo.id
            if let existingDownload = downloads[id] {
                return existingDownload
            }
            
            var dictionary: [URL: String] = [:]
            
            for filename in files {
                let url = constructURL(for: filename, repo: repo)
                dictionary[url] = filename
            }
            
            let download = Download(
                name: repo.id,
                sourceURLs: dictionary,
                destination: destination
            )
            
            downloads[id] = download
            return download
        }
        
        @MainActor
        func removeDownload(for repoId: String) {
            downloads[repoId]?.cancel()
            downloads.removeValue(forKey: repoId)
        }
        
        private func constructURL(for filename: String, repo: HuggingFace.Hub.Repo) -> URL {
            var url = URL(string: "https://huggingface.co")!
            
            if repo.type != .models {
                url = url.appending(component: repo.type.rawValue)
            }
            
            url = url.appending(path: repo.id)
                .appending(path: "resolve/main")
                .appending(path: filename)
            
            return url
        }
    }
}

// MARK: - Conformances

extension ModelStore.HuggingFaceDownloadManager.DownloadState: Equatable {
    public static func == (lhs: ModelStore.HuggingFaceDownloadManager.DownloadState, rhs: ModelStore.HuggingFaceDownloadManager.DownloadState) -> Bool {
        switch (lhs, rhs) {
            case (.notStarted, .notStarted): return true
            case (.downloading(let p1), .downloading(let p2)): return p1 == p2
            case (.paused, .paused): return true
            case (.completed(let u1), .completed(let u2)): return u1 == u2
            case (.failed, .failed): return true
            default: return false
        }
    }
}
