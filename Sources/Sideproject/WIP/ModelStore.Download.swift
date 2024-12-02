//
//  File.swift
//  Sideproject
//
//  Created by Purav Manot on 02/12/24.
//

import Foundation
import HuggingFace

extension ModelStore {
    class Download: NSObject, Codable {
        private var session: URLSession?
        private var tasks: [URLSessionDownloadTask] = []
        private var resumeData: [URL: Data] = [:]
        private var completedTasks: Int = 0
        private var progressByTaskID: [Int: Double] = [:]
        public var progress: Double
        
        let repo: HuggingFace.Hub.Repo
        let files: [String]
        let destination: URL
        private let hfToken: String?
        
        private let stateSubject = CurrentValueSubject<ModelDownloadManager.DownloadState, Never>(.notStarted)
        var state: AnyPublisher<ModelDownloadManager.DownloadState, Never> {
            stateSubject.eraseToAnyPublisher()
        }
        
        init(repo: HuggingFace.Hub.Repo, files: [String], destination: URL, hfToken: String?) {
            self.repo = repo
            self.files = files
            self.destination = destination
            self.hfToken = hfToken
            self.progress = 0
            super.init()
            setupSession()
        }
        
        private func setupSession() {
            let identifier = "ai.preternatural.model-downloader-\(destination.absoluteString)"
            let config = URLSessionConfiguration.background(withIdentifier: identifier)
            config.isDiscretionary = false
            config.sessionSendsLaunchEvents = true
            
            session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        }
        
        func start() {
            tasks = files.compactMap { filename in
                createTask(for: filename)
            }
            
            tasks.forEach { $0.resume() }
            stateSubject.value = .downloading(progress: 0)
        }
        
        @MainActor
        func pause() async {
            print("attempting to pause")
            await withTaskGroup(of: Void.self) { group in
                for task in tasks {
                    group.addTask {
                        guard let url = task.originalRequest?.url else { return }
                        guard let data = await task.cancelByProducingResumeData() else { return }
                        
                        self.resumeData[url] = data
                    }
                }
            }
            
            tasks = []
            progressByTaskID = [:]
            
            stateSubject.value = .paused(progress: progress)
            print("paused")
        }
        
        func resume() {
            tasks = []
            progressByTaskID = [:]

            print("attempting to resume")
            for filename in files {
                let url = constructURL(for: filename)
                let task: URLSessionDownloadTask?
                
                if let data = resumeData[url] {
                    task = session?.downloadTask(withResumeData: data)
                } else {
                    task = createTask(for: filename)
                }
                
                guard let task = task else { continue }
                task.resume()
                self.tasks.append(task)
            }
            
            stateSubject.value = .downloading(progress: progress)
        }
        
        func cancel() {
            tasks.forEach { task in
                task.cancel()
            }
            tasks = []
            completedTasks = 0
            progress = 0
            stateSubject.value = .notStarted
        }
        
        private func constructURL(for filename: String) -> URL {
            var url = URL(string: "https://huggingface.co")!
            
            if repo.type != .models {
                url = url.appending(component: repo.type.rawValue)
            }
            
            url = url.appending(path: repo.id)
                .appending(path: "resolve/main")
                .appending(path: filename)
            
            return url
        }
        
        private func createTask(for filename: String) -> URLSessionDownloadTask? {
            let url = constructURL(for: filename)
            var request = URLRequest(url: url)
            if let hfToken = hfToken {
                request.setValue("Bearer \(hfToken)", forHTTPHeaderField: "Authorization")
            }
            
            return session?.downloadTask(with: request)
        }
        
        private func fileDestination(for filename: String) -> URL {
            destination.appending(path: filename)
        }
        
        enum CodingKeys: String, CodingKey {
            case repo, files, destination, hfToken, progress, completedTasks
        }
        
        convenience required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let repo = try container.decode(HuggingFace.Hub.Repo.self, forKey: .repo)
            let files = try container.decode([String].self, forKey: .files)
            let destination = try container.decode(URL.self, forKey: .destination)
            let hfToken = try container.decodeIfPresent(String.self, forKey: .hfToken)
            
            self.init(repo: repo, files: files, destination: destination, hfToken: hfToken)
            
            self.progress = try container.decode(Double.self, forKey: .progress)
            self.completedTasks = try container.decode(Int.self, forKey: .completedTasks)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(repo, forKey: .repo)
            try container.encode(files, forKey: .files)
            try container.encode(destination, forKey: .destination)
            try container.encode(progress, forKey: .progress)
            try container.encode(hfToken, forKey: .hfToken)
            try container.encode(completedTasks, forKey: .completedTasks)
        }
    }
}


extension ModelStore.Download: URLSessionDownloadDelegate {
    func urlSession(
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
        
        self.progress = progressByTaskID.values.reduce(0, +)/Double(progressByTaskID.values.count)
        print(self.progress)
        
        stateSubject.value = .downloading(progress: progress)
    }
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let filename = downloadTask.originalRequest?.url?.lastPathComponent else { return }
        let fileDestination = self.fileDestination(for: filename)
        
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
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error = error {
            stateSubject.value = .failed(error.localizedDescription)
        }
    }
}
