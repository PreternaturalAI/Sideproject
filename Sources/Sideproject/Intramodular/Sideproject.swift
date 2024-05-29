//
// Copyright (c) Vatsal Manot
//

import CoreMI
import CorePersistence
import LargeLanguageModels
import Merge
import Runtime
import SwiftUIX

extension Sideproject {
    public static let shared = Sideproject()
}

/// `Sideproject` is a utility class that bundles a set of services.
///
/// For e.g. if you're using OpenAI to generate text and ElevenLabs to convert it to speech, you can add the Swift objects for the API clients (`OpenAI.APIClient(...)` and `ElevenLabs.APIClient(...)`) to a `Sideproject` and then send it your machine intelligence tasks (`AbstractLLM.ChatPrompt` and `NaiveTextToSpeechRequest` for example).
///
/// It's useful to have this abstraction, because it forces you to think in terms of the _machine intelligence_ tasks that you're working with rather than specific providers. This is really useful because, for instance, in the first example if you were using `OpenAI.APIClient` directly and wanted to switch to Mistral, you'd have to update your code everywhere you're using an LLM. But with `Sideproject`, you can use types from Preternatural's AI SDK (`AbstractLLM.ChatPrompt` etc.) and let the specific model being used be an implementation detail.
///
/// You can send it abstract requests for AI/ML tasks (for e.g. an LLM chat prompt, or a TTS request), it will find the appropriate service to forward it to and use that to perform the task.
///
/// It also provides an implementation of a fallback mechanism. For e.g. if you've added two OpenAI accounts and use it to complete an LLM chat prompt and the first account *fails*, it'll automatically try with the second account.
///
/// `Sideproject` may also decide which provider is the best one to handle your task. For example, if you've added both OpenAI and Anthropic services, and you try and send it a prompt exceeding 128K tokens (something that OpenAI can't handle at the moment), it'll use Anthropic's Claude to handle that. Or for e.g. if you've added multiple OpenAI accounts, and one of them has access to GPT-4 and the other doesn't, if your LLM task request specifies that the model used must be GPT-4 then it'll pick the account that has access.
public final class Sideproject: _CancellablesProviding, Logging, ObservableObject {
    private let queue = TaskQueue()
    
    private var shouldAutoinitializeServices: Bool
    
    @MainActor
    @Published private var autoinitializedServices: [any _MIService]? = nil {
        didSet {
            if let newValue = autoinitializedServices {
                logger.info("Auto-initialized \(newValue.count) service(s).")
            }
        }
    }
    
    @MainActor
    @Published private var manuallyAddedServices: [any _MIService] = []
    
    // @Published public var modelIdentifierScope: _MLModelIdentifierScope?
    
    public var services: [any _MIService] {
        get async throws {
            await self.queue.perform {
                await _populateAutoinitializedServicesIfNecessary()
            }
            
            return await (autoinitializedServices ?? []).appending(contentsOf: manuallyAddedServices)
        }
    }
    
    @MainActor(unsafe)
    public init(services: [any _MIService]) {
        shouldAutoinitializeServices = false
        
        self.manuallyAddedServices = services
        
        Task { @MainActor in
            self.setUp()
        }
    }
    
    private init() {
        shouldAutoinitializeServices = true
        
        Task { @MainActor in
            self.setUp()
        }
    }
    
    @MainActor
    public func add(_ service: some _MIService) {
        self.manuallyAddedServices.append(service)
    }
    
    @MainActor
    private func setUp() {
        @Sendable
        func _runSetUp() async {
            await self._populateAutoinitializedServicesIfNecessary()
            
            do {
                try await self._assertNonZeroServices()
            } catch {
                runtimeIssue(error)
            }
        }
        
        queue.addTask(priority: .userInitiated) {
            await _runSetUp()
        }
        
        Sideproject.ExternalAccountStore.shared.$accounts.sink { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            queue.addTask(priority: .userInitiated) {
                await _runSetUp()
            }
        }
        .store(in: self.cancellables)
    }
    
    func _assertNonZeroServices() async throws {
        let services = try await self.services
        
        guard !services.isEmpty else {
            throw Sideproject.Error.failedToDiscoverServices
        }
    }
}

extension Sideproject {
    public var _availableModels: [_MLModelIdentifier]? {
        nil
    }
}

extension Sideproject: _TaskDependenciesExporting {
    public var _exportedTaskDependencies: Dependencies {
        var result = Dependencies()
        
        result[\.llm] = self
        result[\.embedding] = self
        
        return result
    }
}

extension Sideproject {
    @MainActor
    private func _populateAutoinitializedServicesIfNecessary() async {
        guard shouldAutoinitializeServices, autoinitializedServices == nil else {
            return
        }
        
        shouldAutoinitializeServices = false

        self.logger.debug("Discovering services to auto-intialize.")
        
        var services: [any _MIService] = []
        
        do {
            services = try await self._makeServices()
            
            self.autoinitializedServices = services
        } catch {
            runtimeIssue(error)
            
            self.autoinitializedServices = nil
        }
    }
    
    /// Converts Sideproject accounts loaded from Sideproject's managed account store to CoreMI accounts.
    @MainActor
    private func _serviceAccounts() throws -> [_AnyMIServiceAccount] {
        let allAccounts: IdentifierIndexingArrayOf<Sideproject.ExternalAccount> = Sideproject.ExternalAccountStore.shared.accounts + (Sideproject.ExternalAccountStore.shared._testAccounts ?? [])
        
        return try allAccounts.compactMap { (account: Sideproject.ExternalAccount) in
            let credential = _MIServiceAPIKeyCredential(
                apiKey: (account.credential as! Sideproject.ExternalAccountCredentialTypes.APIKey).key
            )
            let service: _MIServiceTypeIdentifier = try account.accountType.__conversion()
            
            return _AnyMIServiceAccount(
                serviceIdentifier: service,
                credential: credential
            )
        }
    }
        
    /// Initializes all CoreMI services that can be initialized using the loaded Sideproject accounts.
    private func _makeServices() async throws -> [any _MIService] {
        let serviceTypes: [any _MIService.Type] = try TypeMetadata._queryAll(
            .conformsTo((any _MIService).self),
            .nonAppleFramework
        )
        let serviceAccounts: [any _MIServiceAccount] = try await _serviceAccounts()
        
        var result: [any _MIService] = await serviceAccounts
            .concurrentMap { account in
                await serviceTypes.first(byUnwrapping: { type -> (any _MIService)? in
                    do {
                        return try await type.init(account: account)
                    } catch {
                        do {
                            return try await type.init(account: nil)
                        } catch(_) {
                            return nil
                        }
                    }
                })
            }
            .compactMap({ $0 })
        
        result += await serviceTypes
            .concurrentMap({ try? await $0.init(account: nil) })
            .compactMap({ $0 })
        
        // FIXME: Ollama is special-cased.
        if let ollama = try await serviceTypes.firstAndOnly(byUnwrapping: { try? await $0.init(account: _AnyMIServiceAccount(serviceIdentifier: ._Ollama, credential: nil)) }) {
            result += ollama
        }
        
        return result
    }
}

extension Sideproject {
    public enum Error: Swift.Error {
        case failedToDiscoverServices
        case failedToResolveLLMService
        case failedToResolveService
        case completionFailed(AnyError)
    }
}

extension Sideproject.ExternalAccountTypeIdentifier: _MIServiceTypeIdentifierConvertible {
    public func __conversion() throws -> _MIServiceTypeIdentifier {
        switch self {
            case Sideproject.ExternalAccountTypeDescriptions.Anthropic().accountType:
                return ._Anthropic
            case Sideproject.ExternalAccountTypeDescriptions.HuggingFace().accountType:
                return ._HuggingFace
            case Sideproject.ExternalAccountTypeDescriptions.Mistral().accountType:
                return ._Mistral
            case Sideproject.ExternalAccountTypeDescriptions.OpenAI().accountType:
                return ._OpenAI
            case Sideproject.ExternalAccountTypeDescriptions.Perplexity().accountType:
                return ._Perplexity
            case Sideproject.ExternalAccountTypeDescriptions.Replicate().accountType:
                return ._Replicate
            case Sideproject.ExternalAccountTypeDescriptions.Groq().accountType:
                return ._Groq
            default:
                throw Never.Reason.unexpected
        }
    }
}
