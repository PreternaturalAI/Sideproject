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
    class ModelDownloadManager {
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
        var downloads: [String: ModelStore.Download]

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
            
            let download = Download(
                repo: repo,
                files: files,
                destination: destination,
                hfToken: hfToken
            )
            downloads[id] = download
            return download
        }
        
        func removeDownload(for repoId: String) {
            downloads.removeValue(forKey: repoId)
        }
    }
}

// MARK: - Conformances

extension ModelStore.ModelDownloadManager.DownloadState: Equatable {
    public static func == (lhs: ModelStore.ModelDownloadManager.DownloadState, rhs: ModelStore.ModelDownloadManager.DownloadState) -> Bool {
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

/*
extension HuggingFace {
    class Downloader: NSObject {
        private(set) var destination: URL
        
        enum DownloadState {
            case notStarted
            case paused(Data)
            case downloading(Double)
            case completed(URL)
            case failed(Error)
        }
        
        enum DownloadError: Error {
            case invalidDownloadLocation
            case unexpectedError
        }
        
        private(set) lazy var downloadState: CurrentValueSubject<DownloadState, Never> = CurrentValueSubject(.notStarted)
        private var stateSubscriber: Cancellable?
        
        private var urlSession: URLSession? = nil
        
        init(from url: URL, to destination: URL, using authToken: String? = nil, inBackground: Bool = false) {
            self.destination = destination
            super.init()
            let sessionIdentifier = "swift-transformers.hub.downloader"
            
            var config = URLSessionConfiguration.default
            if inBackground {
                config = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
                config.isDiscretionary = false
                config.sessionSendsLaunchEvents = true
            }
            
            self.urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
            
            setupDownload(from: url, with: authToken)
        }
        
        private func setupDownload(from url: URL, with authToken: String?) {
            downloadState.value = .downloading(0)
            
            urlSession?.getAllTasks { tasks in
                // If there's an existing pending background task with the same URL, let it proceed.
                if let existing = tasks.filter({ $0.originalRequest?.url == url }).first {
                    switch existing.state {
                        case .running:
                            // print("Already downloading \(url)")
                            return
                        case .suspended:
                            // print("Resuming suspended download task for \(url)")
                            existing.resume()
                            return
                        case .canceling:
                            // print("Starting new download task for \(url), previous was canceling")
                            break
                        case .completed:
                            // print("Starting new download task for \(url), previous is complete but the file is no longer present (I think it's cached)")
                            break
                        @unknown default:
                            // print("Unknown state for running task; cancelling and creating a new one")
                            existing.cancel()
                    }
                }
                var request = URLRequest(url: url)
                if let authToken = authToken {
                    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
                }
                
                self.urlSession?.downloadTask(with: request).resume()
            }
        }
        
        @discardableResult
        func waitUntilDone() throws -> URL {
            // It's either this, or stream the bytes ourselves (add to a buffer, save to disk, etc; boring and finicky)
            let semaphore = DispatchSemaphore(value: 0)
            stateSubscriber = downloadState.sink { state in
                switch state {
                    case .completed:
                        semaphore.signal()
                    case .failed:
                        semaphore.signal()
                    default:
                        break
                }
            }
            semaphore.wait()
            
            switch downloadState.value {
                case .completed(let url):
                    return url
                case .failed(let error):
                    throw error
                default:
                    throw DownloadError.unexpectedError
            }
        }
        
        func cancel() {
            urlSession?.invalidateAndCancel()
        }
    }
}

extension HuggingFace.Downloader: URLSessionDownloadDelegate {
    func urlSession(
        _: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData _: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        downloadState.value = .downloading(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
    }
    
    func urlSession(
        _: URLSession,
        downloadTask _: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        do {
            // If the downloaded file already exists on the filesystem, overwrite it
            try FileManager.default.moveDownloadedFile(from: location, to: self.destination)
            downloadState.value = .completed(destination)
        } catch {
            downloadState.value = .failed(error)
        }
    }
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error = error {
            downloadState.value = .failed(error)
            //        } else if let response = task.response as? HTTPURLResponse {
            //            print("HTTP response status code: \(response.statusCode)")
            //            let headers = response.allHeaderFields
            //            print("HTTP response headers: \(headers)")
        }
    }
}

extension FileManager {
    func moveDownloadedFile(from srcURL: URL, to dstURL: URL) throws {
        if fileExists(atPath: dstURL.path) {
            try removeItem(at: dstURL)
        }
        try moveItem(at: srcURL, to: dstURL)
    }
}
*/
