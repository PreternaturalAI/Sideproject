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
        models.filter { $0.state == .downloaded && $0.url.isNotNil }
    }
    
    public var activeDownloads: [Model] {
        models.filter { $0.isDownloading }
    }
            
    private var hub: HuggingFace.Hub.Client?
    
    private let fileManager = FileManager.default
    
    @MainActor
    public init() {
        if !FileManager.default.isReadable(at: downloadsURL) {
            fatalError("Cannot read downloads folder")
        }
        
        if !FileManager.default.fileExists(atPath: downloadsURL.path) {
            _ = try? FileManager.default.createDirectory(
                at: downloadsURL,
                withIntermediateDirectories: true
            )
        }
        
        if models.isEmpty {
            models = ModelStore.exampleModelNames.map { Model(name: $0, state: .notDownloaded) }
        }
        
        refreshFromDisk()
    }
    
    @MainActor
    init(hfToken: String) {
        self.hub = .init(hfToken: hfToken)
        
        if !FileManager.default.fileExists(atPath: downloadsURL.path) {
            _ = try? FileManager.default.createDirectory(
                at: downloadsURL,
                withIntermediateDirectories: true
            )
        }
        
        refreshFromDisk()
    }
    
    private var downloadsURL: URL {
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
    
    @discardableResult
    @MainActor
    public func download(
        modelNamed name: String,
        using accountStore: Sideproject.ExternalAccountStore
    ) async throws -> URL {
        let account = try Sideproject.ExternalAccountStore.shared.accounts(for: .huggingFace).first.unwrap()
        self.hub = try .init(from: account)
        
        let model: Model

        
        if let existingModel = models.first(where: { $0.name == name }) {
            model = existingModel
        } else {
            assert(!models.contains(where: { $0.id == name }))
            
            model = Model(
                name: name,
                url: nil,
                state: .downloading(progress: 0)
            )
            
            self.models.append(model)
        }
        
        
        let repo = HuggingFace.Hub.Repo(id: name)
        let modelFiles: [String] = [
            "config.json",
            "*.safetensors"
        ]
        
        let modelDirectory: URL = try await hub.unwrap().snapshot(
            from: repo,
            matching: modelFiles,
            outputHandler: { progress in
                Task { @MainActor in
                    if let index = self.models.firstIndex(where: { $0.id == name }) {
                        self.models[index].state = .downloading(progress: progress.fractionCompleted)
                        
                        print("[\(name)] Download progress: \(progress.fractionCompleted * 100)")
                    } else {
                        assertionFailure()
                    }
                }
            }
        )
        
        if let index = self.models.firstIndex(where: { $0.id == name }) {
            self.models[index].state = .downloaded
            self.models[index].url = modelDirectory
        }
        
        return modelDirectory
    }
    
    func cancelDownload(for model: Model) {
        guard let index = models.firstIndex(where: { $0.id == model.id }) else { return }
        models[index].state = .notDownloaded
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
        guard let model = models.first(where: { $0.id == model }) else {
            return
        }
        
        do {
            if let modelURL = model.url {
                print(modelURL)
                try fileManager.removeItem(at: modelURL)
            }
            
            cancelDownload(for: model)
            
            models.removeAll(where: { $0.id == model.id })
        } catch {
            assertionFailure(String(describing: error))
        }
    }
    
    private func refreshFromDisk() {
        let fileManager = FileManager.default
        
        do {
            let modelDirectories = try fileManager.contentsOfDirectory(
                at: downloadsURL,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            ).flatMap {
                try fileManager.contentsOfDirectory(
                    at: $0,
                    includingPropertiesForKeys: nil,
                    options: .skipsHiddenFiles
                )
            }
            
            for directory in modelDirectories {
                let modelName: String = directory.deletingLastPathComponent().lastPathComponent + "/" + directory.lastPathComponent
                let modelURL = directory
                let modelFiles = try fileManager.contentsOfDirectory(atPath: directory.path)
                let isDownloaded = modelFiles.contains(where: { $0.hasSuffix(".safetensors") })
                
                let model = Model(
                    name: modelName,
                    url: modelURL,
                    state: isDownloaded ? .downloaded : .notDownloaded
                )
                
                if self.containsModel(named: model.name) {
                    self[_modelWithName: model.name] = model
                } else {
                    self.models.append(model)
                }
            }
        } catch {
            print("Error loading models from disk: \(error)")
        }
    }
}

extension ModelStore {
    /*
     public func loadTokenizer(
     for model: Model.ID
     ) async throws -> Tokenizers.Tokenizer {
     var model: String = await self[_model: model].name
     
     if model == "mlx-community/stablelm-2-zephyr-1_6b-4bit" {
     model = "stabilityai/stablelm-2-zephyr-1_6b"
     }
     do {
     let config = HuggingFace.LanguageModelConfigurationFromHub(modelName: model)
     
     guard var tokenizerConfig = try await config.tokenizerConfig else {
     throw Error(message: "missing config")
     }
     
     var tokenizerData = try await config.tokenizerData
     
     if let tokenizerClass = tokenizerConfig.tokenizerClass?.stringValue,
     let replacement = replacementTokenizers[tokenizerClass] {
     var dictionary = tokenizerConfig.dictionary
     dictionary["tokenizer_class"] = replacement
     tokenizerConfig = HuggingFace.Config(dictionary)
     }
     
     if let tokenizerClass = tokenizerConfig.tokenizerClass?.stringValue {
     switch tokenizerClass {
     case "T5Tokenizer":
     break
     default:
     tokenizerData = discardUnhandledMerges(tokenizerData: tokenizerData)
     }
     }
     
     return try HuggingFace.PreTrainedTokenizer(
     tokenizerConfig: tokenizerConfig,
     tokenizerData: tokenizerData
     )
     } catch {
     return try await AutoTokenizer.from(pretrained: model)
     }
     }
     */
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
    
}

extension ModelStore {
    struct Error: Swift.Error {
        let message: String
    }
}

extension ModelStore {
    public static let exampleModelNames: [String] = [
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