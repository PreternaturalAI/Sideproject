//
//  File.swift
//  Sideproject
//
//  Created by Purav Manot on 02/12/24.
//

import Foundation
import HuggingFace

extension ModelStore {
    public class Download: NSObject, Codable {
        private var session: URLSession!
        private var tasks: [URLSessionDownloadTask] = []
        private var resumeData: [URL: Data] = [:]
        private var completedTasks: Int = 0
        private var progressByTaskID: [Int: Double] = [:]
    
        private let destination: URL
        private let sourceURLs: [URL]
        private let stateSubject = CurrentValueSubject<HuggingFaceDownloadManager.DownloadState, Never>(.notStarted)
        
        public var progress: Double
        
        public var statePublisher: AnyPublisher<HuggingFaceDownloadManager.DownloadState, Never> {
            stateSubject.eraseToAnyPublisher()
        }
        
        public var state: HuggingFaceDownloadManager.DownloadState {
            stateSubject.value
        }
        
        public var isPaused: Bool {
            switch self.state {
                case .paused:
                    return true
                default:
                    return false
            }
        }
        
        public init(sourceURLs: [URL], destination: URL) {
            self.sourceURLs = sourceURLs
            self.destination = destination
            
            self.progress = 0
            super.init()
            
            setupSession()
        }
        
        private func setupSession() {
            let identifier = "ai.preternatural.model-downloader-\(destination.absoluteString)"
            let config = URLSessionConfiguration.background(withIdentifier: identifier)
            config.isDiscretionary = false
            config.sessionSendsLaunchEvents = true
            
            self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        }
        
        @MainActor
        public func startOrResume(with hfToken: String?) async {
            let allTasks: [URLSessionDownloadTask] = await session.allTasks.compactMap { (task: URLSessionTask) in
                guard let url = task.originalRequest?.url else { return nil }
                guard task.state != .canceling else { return nil }
                
                return sourceURLs.contains(url) ? task as? URLSessionDownloadTask : nil
            }
            
            for url in sourceURLs {
                if let task = allTasks.first(where: { $0.originalRequest?.url == url }) {
                    self.tasks.append(task)
                } else {
                    let task: URLSessionDownloadTask
                    
                    if let data: Data = resumeData[url] {
                        task = session.downloadTask(withResumeData: data)
                    } else {
                        task = createTask(for: url, hfToken: hfToken)
                    }
                    
                    self.tasks.append(task)
                }
                
                continue
            }
            
            tasks.forEach { $0.resume() }
            stateSubject.value = .downloading(progress: 0)
        }
        
        @MainActor
        public func pause() async {
            print("attempting to pause")
            await withTaskGroup(of: Void.self) { group in
                for task in tasks {
                    group.addTask {
                        guard let url: URL = task.originalRequest?.url else { return }
                        guard self.sourceURLs.contains(url) else { return }
                        guard let data: Data = await task.cancelByProducingResumeData() else { return }
                        
                        self.resumeData[url] = data
                    }
                }
            }
            
            tasks = []
            progressByTaskID = [:]
            
            stateSubject.value = .paused(progress: progress)
        }
        
        @MainActor
        public func cancel() {
            session.invalidateAndCancel()
            
            tasks = []
            completedTasks = 0
            progress = 0
            stateSubject.value = .notStarted
        }
        
        private func createTask(for url: URL, hfToken: String?) -> URLSessionDownloadTask {
            var request: URLRequest = URLRequest(url: url)
            
            if let hfToken: String = hfToken {
                request.setValue("Bearer \(hfToken)", forHTTPHeaderField: "Authorization")
            }
            
            return session.downloadTask(with: request)
        }
                
        enum CodingKeys: String, CodingKey {
            case sourceURLs, destination, progress, completedTasks
        }
        
        public convenience required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let sourceURLs = try container.decode([URL].self, forKey: .sourceURLs)
            let destination = try container.decode(URL.self, forKey: .destination)
            
            self.init(sourceURLs: sourceURLs, destination: destination)
            
            self.progress = try container.decode(Double.self, forKey: .progress)
            self.completedTasks = try container.decode(Int.self, forKey: .completedTasks)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(sourceURLs, forKey: .sourceURLs)
            try container.encode(destination, forKey: .destination)
            try container.encode(progress, forKey: .progress)
            try container.encode(completedTasks, forKey: .completedTasks)
        }
    }
}

// MARK: Conformances

extension ModelStore.Download: URLSessionDownloadDelegate {
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite != 0 else {
            self.progressByTaskID[downloadTask.taskIdentifier] = 0
            stateSubject.value = .downloading(progress: .zero)
            
            return
        }
        
        self.progressByTaskID[downloadTask.taskIdentifier] = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        self.progress = progressByTaskID.values.reduce(0, +)/Double(sourceURLs.count)
        
        stateSubject.value = .downloading(progress: progress)
    }
    
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let filename = downloadTask.originalRequest?.url?.lastPathComponent else { return }
        let fileDestination = destination.appending(path: filename)
        
        do {
            try FileManager.default.createDirectory(
                at: fileDestination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if FileManager.default.fileExists(atPath: fileDestination.path) {
                try FileManager.default.removeItem(at: fileDestination)
            }
            try FileManager.default.moveItem(at: location, to: fileDestination)
            
            completedTasks += 1
            if completedTasks == tasks.count {
                stateSubject.value = .completed(destination)
            }
        } catch {
            stateSubject.value = .failed(error.localizedDescription)
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let url = task.originalRequest?.url, self.resumeData[url] != nil {
            return
        } else {
            if let error = error {
                stateSubject.value = .failed(error.localizedDescription)
            }
        }
    }
}
