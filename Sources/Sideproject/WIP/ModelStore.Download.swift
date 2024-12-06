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
        private let sourceURLsByFilenames: [URL: String]
        private let stateSubject = CurrentValueSubject<HuggingFaceDownloadManager.DownloadState, Never>(.notStarted)
        
        public let name: String
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
        
        public init(name: String, sourceURLs: [URL: String], destination: URL) {
            self.name = name
            self.sourceURLsByFilenames = sourceURLs
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
                
                return sourceURLsByFilenames.keys.contains(url) ? task as? URLSessionDownloadTask : nil
            }
            
            print(sourceURLsByFilenames)

            for url in sourceURLsByFilenames.keys {
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
            
            print("\(tasks.count) tasks")
            print("\(sourceURLsByFilenames.keys.count) urls")
            
            stateSubject.value = .downloading(progress: 0)
        }
        
        @MainActor
        public func pause() async {
            print("attempting to pause")
            await withTaskGroup(of: Void.self) { group in
                for task in tasks {
                    group.addTask {
                        guard let url: URL = task.originalRequest?.url else { return }
                        guard self.sourceURLsByFilenames.keys.contains(url) else { return }
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
            case name, sourceURLsByFilenames, destination, progress, completedTasks
        }
        
        public convenience required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            let sourceURLsByFilenames = try container.decode([URL: String].self, forKey: .sourceURLsByFilenames)
            let destination = try container.decode(URL.self, forKey: .destination)
            
            let name = try container.decode(String.self, forKey: .name)
            
            self.init(name: name, sourceURLs: sourceURLsByFilenames, destination: destination)
            
            self.progress = try container.decode(Double.self, forKey: .progress)
            self.completedTasks = try container.decode(Int.self, forKey: .completedTasks)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(sourceURLsByFilenames, forKey: .sourceURLsByFilenames)
            try container.encode(destination, forKey: .destination)
            try container.encode(name, forKey: .name)
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
        
        self.progress = progressByTaskID.values.reduce(0, +)/Double(sourceURLsByFilenames.values.count)
        
        print("\(name): \(progress)")
        stateSubject.value = .downloading(progress: progress)
    }
    
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let url: URL = downloadTask.originalRequest?.url else { return }
        guard let path: String = sourceURLsByFilenames[url] else { return }
        
        let fileDestination: URL = destination.appending(path: path)

        print("COMPLETED FOR \(path)")
        do {
            try FileManager.default.createDirectory(
                at: fileDestination,
                withIntermediateDirectories: true
            )
            if FileManager.default.fileExists(atPath: fileDestination.path) {
                try FileManager.default.removeItem(at: fileDestination)
            }
            try FileManager.default.moveItem(at: location, to: fileDestination)
            
            completedTasks += 1
            if completedTasks == tasks.count {
                print("completed for \(name)")
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
                print("ERROR: \(error)")
            }
        }
    }
}
