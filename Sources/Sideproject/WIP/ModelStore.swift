//
// Copyright (c) Vatsal Manot
//

import Foundation
import HuggingFace
import CorePersistence
import SwiftUIX

public final class ModelStore: ObservableObject {
    @FileStorage(
        .appDocuments,
        path: "SideProjectExample/models.json",
        coder: .json,
        options: .init(readErrorRecoveryStrategy: .discardAndReset)
    ) public var models: [Model]
    
    public var downloadedModels: [Model] {
        models.filter(\.isOnDisk)
    }
    
    public var activeDownloads: [Model.ID: Download] {
        downloadManager.downloads
    }
    
    public var activeDownloadKeys: [Model.ID] {
        Array(downloadManager.downloads.keys)
    }
            
    private var hub: HuggingFace.Hub.Client?
    private let downloadManager = HuggingFaceDownloadManager()
    private var cancellables: [String: AnyCancellable] = [:]
    
    private let fileManager = FileManager.default
    
    @MainActor
    public init() {
        if !FileManager.default.isReadable(at: documentsDirectory) {
            fatalError("Cannot read downloads folder")
        }
        
        if !FileManager.default.fileExists(atPath: documentsDirectory.path) {
            _ = try? FileManager.default.createDirectory(
                at: documentsDirectory,
                withIntermediateDirectories: true
            )
        }
        
        if models.isEmpty {
            debugPrint("initialized with hardcoded models")
            models = ModelStore.exampleModelNames.map { Model(name: $0) }
        }
        
        models.enumerated().forEach { models[$0].lastUsed = $1.isOnDisk ? $1.lastUsed : nil }
    }
    
    @MainActor
    init(hfToken: String) {
        self.hub = .init(hfToken: hfToken)
        
        if !FileManager.default.fileExists(atPath: documentsDirectory.path) {
            _ = try? FileManager.default.createDirectory(
                at: documentsDirectory,
                withIntermediateDirectories: true
            )
        }
    }
    
    private var documentsDirectory: URL {
        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        return documentsDirectory
            .appending(component: "huggingface")
            .appending(component: "models")
    }
    
    private let replacementTokenizers = [
        "CodeLlamaTokenizer": "LlamaTokenizer",
        "GemmaTokenizer": "PreTrainedTokenizer",
    ]
    
    public func binding(for id: Model.ID) -> Binding<Model>? {
        guard let model = models.first (where: { $0.id == id }) else {
            return nil
        }
            
        return Binding {
            return self.models.first (where: { $0.id == id }) ?? model
        } set: { newValue in
            if let index = self.models.firstIndex (where: { $0.id == id }) {
                self.models[index] = newValue
            }
        }
        
    }
    
    @MainActor
    public func download(
        modelNamed name: String,
        using accountStore: Sideproject.ExternalAccountStore
    ) async throws -> URL {
        let account = try Sideproject.ExternalAccountStore.shared.accounts(for: .huggingFace).first.unwrap()
        self.hub = try .init(from: account)
        
        var model: Model
        let repo = HuggingFace.Hub.Repo(id: name)

        let filenames = try await hub.unwrap().getFilenames(from: repo, matching: [])
        
        if let existingModelIndex = models.firstIndex(where: { $0.name == name }) {
            models[existingModelIndex].expectedFilenames = filenames
            model = models[existingModelIndex]
        } else {
            assert(!models.contains(where: { $0.id == name }))
            model = Model(
                name: name,
                url: nil
            )
            
            model.expectedFilenames = filenames
            
            self.models.append(model)
        }
        
        let modelDownload = downloadManager.download(
            repo: repo,
            files: filenames,
            destination: documentsDirectory.appending(component: repo.id),
            hfToken: hub?.hfToken
        )
        
        cancellables[name] = modelDownload.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self,
                      let index = self.models.firstIndex(where: { $0.id == name }) else { return }
                                
                switch state {
                    case .completed(let url):
                        self.models[index].url = url
                    default:
                        return
                }
            }
        
        await modelDownload.startOrResume(with: hub?.hfToken)
        return documentsDirectory.appending(component: repo.id)
    }
    
    @MainActor
    public func pauseDownload(for model: Model) async {
        guard let modelDownload = downloadManager.downloads[model.id] else { return }
        await modelDownload.pause()
    }
    
    @MainActor
    public func resumeDownload(for model: Model) async {
        guard let download = downloadManager.downloads[model.id] else { return }
        await download.startOrResume(with: hub?.hfToken)
    }
    
    @MainActor
    public func cancelDownload(for model: Model) {
        guard let download = downloadManager.downloads[model.id] else { return }
        
        download.cancel()
        
        downloadManager.removeDownload(for: model.id)
        cancellables.removeValue(forKey: model.id)
    }
}

@MainActor
extension ModelStore {
    public func containsModel(named name: String) -> Bool {
        models.contains(where: { $0.name == name })
    }
    
    public subscript(
        _model modelID: Model.ID
    ) -> Model {
        get {
            self.models.first(where: { $0.id == modelID })!
        } set {
            let index = self.models.firstIndex(where: { $0.id == modelID })!
            
            self.models[index] = newValue
        }
    }
    
    public subscript(
        _modelWithName name: String
    ) -> Model {
        get {
            self.models.first(where: { $0.name == name })!
        } set {
            let index = self.models.firstIndex(where: { $0.name == name })!
            
            self.models[index] = newValue
        }
    }
    
    public func delete(
        _ model: Model.ID
    ) {
        guard let index = models.firstIndex(where: { $0.id == model }) else {
            return
        }
        
        let model = models[index]
        
        do {
            cancelDownload(for: model)

            if let modelURL = model.url {
                print(modelURL)
                try fileManager.removeItem(at: modelURL)
            }
            
            models[index].url = nil
        } catch {
            assertionFailure(String(describing: error))
        }
    }
}

extension ModelStore {
    private func discardUnhandledMerges(
        tokenizerData: HuggingFace.Config
    ) -> HuggingFace.Config {
        if let model = tokenizerData.model {
            if let merges = model.dictionary["merges"] as? [String] {
                let newMerges =
                merges
                    .filter {
                        $0.split(separator: " ").count == 2
                    }
                if newMerges.count != merges.count {
                    var newModel = model.dictionary
                    newModel["merges"] = newMerges
                    var newTokenizerData = tokenizerData.dictionary
                    newTokenizerData["model"] = newModel
                    return HuggingFace.Config(newTokenizerData)
                }
            }
        }
        return tokenizerData
    }
}

extension ModelStore {
    struct Error: Swift.Error {
        let message: String
    }
}

extension ModelStore {
    public static let exampleModelNames: [String] = [
        "BAAI/bge-small-en-v1.5",
        "openai/whisper-large-v3",
        "openai/whisper-tiny",
        "openai/whisper-base",
        "openai/whisper-small",
        "qwq",
        "qwen2.5-coder",
        "llama3.2-vision",
        "llama3.2",
        "llama3.1",
        "llama3",
        "mistral",
        "nomic-embed-text",
        "gemma",
        "qwen",
        "qwen2",
        "phi3",
        "llama2",
        "qwen2.5",
        "gemma2",
        "llava",
        "codellama",
        "mistral-nemo",
        "mxbai-embed-large",
        "mixtral",
        "dolphin-mixtral",
        "starcoder2",
        "tinyllama",
        "codegemma",
        "deepseek-coder-v2",
        "phi",
        "deepseek-coder",
        "llama2-uncensored",
        "dolphin-mistral",
        "wizardlm2",
        "snowflake-arctic-embed",
        "yi",
        "dolphin-llama3",
        "command-r",
        "orca-mini",
        "zephyr",
        "llava-llama3",
        "phi3.5",
        "all-minilm",
        "starcoder",
        "codestral",
        "vicuna",
        "mistral-openorca",
        "granite-code",
        "smollm",
        "wizard-vicuna-uncensored",
        "llama2-chinese",
        "codegeex4",
        "openchat",
        "aya",
        "bge-m3",
        "nous-hermes2",
        "codeqwen",
        "wizardcoder",
        "tinydolphin",
        "stable-code",
        "command-r-plus",
        "openhermes",
        "mistral-large",
        "qwen2-math",
        "glm4",
        "stablelm2",
        "bakllava",
        "reflection",
        "deepseek-llm",
        "llama3-gradient",
        "wizard-math",
        "neural-chat",
        "moondream",
        "xwinlm",
        "llama3-chatqa",
        "sqlcoder",
        "nous-hermes",
        "phind-codellama",
        "yarn-llama2",
        "dolphincoder",
        "wizardlm",
        "deepseek-v2",
        "starling-lm",
        "samantha-mistral",
        "solar",
        "falcon",
        "yi-coder",
        "internlm2",
        "hermes3",
        "orca2",
        "stable-beluga",
        "llava-phi3",
        "dolphin-phi",
        "mistral-small",
        "wizardlm-uncensored",
        "minicpm-v",
        "yarn-mistral",
        "llama-pro",
        "nemotron-mini",
        "medllama2",
        "meditron",
        "nexusraven",
        "llama3-groq-tool-use",
        "nous-hermes2-mixtral",
        "nemotron",
        "codeup",
        "everythinglm",
        "magicoder",
        "stablelm-zephyr",
        "codebooga",
        "falcon2",
        "wizard-vicuna",
        "mistrallite",
        "duckdb-nsql",
        "granite3-dense",
        "mathstral",
        "megadolphin",
        "notux",
        "solar-pro",
        "notus",
        "open-orca-platypus2",
        "goliath",
        "smollm2",
        "reader-lm",
        "nuextract",
        "dbrx",
        "granite3-moe",
        "firefunction-v2",
        "aya-expanse",
        "bge-large",
        "alfred",
        "deepseek-v2.5",
        "bespoke-minicheck",
        "shieldgemma",
        "llama-guard3",
        "paraphrase-multilingual",
        "opencoder",
        "marco-o1",
        "tulu3",
        "athene-v2",
        "granite3-guardian"
    ]
}
