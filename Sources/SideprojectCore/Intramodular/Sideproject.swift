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
/// For e.g. if you're using OpenAI to generate text and ElevenLabs to convert it to speech, you can add the Swift objects for the API clients (`OpenAI.Client(...)` and `ElevenLabs.APIClient(...)`) to a `Sideproject` and then send it your machine intelligence tasks (`AbstractLLM.ChatPrompt` and `NaiveTextToSpeechRequest` for example).
///
/// It's useful to have this abstraction, because it forces you to think in terms of the _machine intelligence_ tasks that you're working with rather than specific providers. This is really useful because, for instance, in the first example if you were using `OpenAI.Client` directly and wanted to switch to Mistral, you'd have to update your code everywhere you're using an LLM. But with `Sideproject`, you can use types from Preternatural's AI SDK (`AbstractLLM.ChatPrompt` etc.) and let the specific model being used be an implementation detail.
///
/// You can send it abstract requests for AI/ML tasks (for e.g. an LLM chat prompt, or a TTS request), it will find the appropriate service to forward it to and use that to perform the task.
///
/// It also provides an implementation of a fallback mechanism. For e.g. if you've added two OpenAI accounts and use it to complete an LLM chat prompt and the first account *fails*, it'll automatically try with the second account.
///
/// `Sideproject` may also decide which provider is the best one to handle your task. For example, if you've added both OpenAI and Anthropic services, and you try and send it a prompt exceeding 128K tokens (something that OpenAI can't handle at the moment), it'll use Anthropic's Claude to handle that. Or for e.g. if you've added multiple OpenAI accounts, and one of them has access to GPT-4 and the other doesn't, if your LLM task request specifies that the model used must be GPT-4 then it'll pick the account that has access.
public final class Sideproject: _CancellablesProviding, Logging, ObservableObject {
    private let queue = TaskQueue()
    
    private var shouldAutoinitializeServices: Bool
    private var autodiscoveredServiceAccounts: [CoreMI._AnyServiceAccount] = []
    
    @MainActor
    @Published private var autoinitializedServices: [any CoreMI._ServiceClientProtocol]? = nil {
        didSet {
            if let newValue = autoinitializedServices {
                logger.info("Auto-initialized \(newValue.count) service(s).")
            }
        }
    }
    
    @MainActor
    @Published private var manuallyAddedServices: [any CoreMI._ServiceClientProtocol] = []
    
    // @Published public var modelIdentifierScope: ModelIdentifierScope?
    
    public var services: [any CoreMI._ServiceClientProtocol] {
        get async throws {
            await self.queue.perform {
                await _populateAutoinitializedServicesIfNecessary()
            }
            
            return await (autoinitializedServices ?? []).appending(contentsOf: manuallyAddedServices)
        }
    }
    
    public init(services: [any CoreMI._ServiceClientProtocol]?) {
        if services != nil {
            shouldAutoinitializeServices = false
        } else {
            shouldAutoinitializeServices = true
        }
        
        MainActor.unsafeAssumeIsolated {
            if let services {
                self.manuallyAddedServices = services
            }
            
            self.setUp()
        }
    }
    
    private convenience init() {
        self.init(services: nil)
    }
    
    @MainActor
    public func add(
        _ service: some CoreMI._ServiceClientProtocol
    ) {
        self.manuallyAddedServices.append(service)
    }
    
    @MainActor
    private func setUp() {
        queue.addTask(priority: .userInitiated) {
            await self._populateAutoinitializedServicesIfNecessary()
        }
        
        Sideproject.ExternalAccountStore.shared.$accounts.removeDuplicates().sink { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            queue.addTask(priority: .userInitiated) {
                self.shouldAutoinitializeServices = true
                
                await self._populateAutoinitializedServicesIfNecessary()
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
    public var _availableModels: [ModelIdentifier]? {
        nil
    }
}

extension Sideproject: _TaskDependenciesExporting {
    public var _exportedTaskDependencies: TaskDependencies {
        var result = TaskDependencies()
        
        result[\.llm] = self
        result[\.embedding] = self
        
        return result
    }
}

extension Sideproject {
    @MainActor
    private func _populateAutoinitializedServicesIfNecessary() async {
        guard shouldAutoinitializeServices else {
            return
        }
        
        self.logger.debug("Discovering services to auto-intialize.")
        
        do {
            let oldAccounts: [CoreMI._AnyServiceAccount] = self.autodiscoveredServiceAccounts
            let newAccounts = try self._serviceAccounts()
            
            guard oldAccounts != newAccounts else {
                return
            }
            
            let services: [any CoreMI._ServiceClientProtocol] = try await self._makeServices(forAccounts: newAccounts)
            
            self.autodiscoveredServiceAccounts = newAccounts
            self.autoinitializedServices = services
            
            logger.info("Auto-initialized \(services.count) services.")
            
            shouldAutoinitializeServices = false
        } catch {
            runtimeIssue(error)
            
            self.autoinitializedServices = nil
        }
    }
    
    /// Converts Sideproject accounts loaded from Sideproject's managed account store to CoreMI accounts.
    @MainActor
    private func _serviceAccounts() throws -> [CoreMI._AnyServiceAccount] {
        let allAccounts: IdentifierIndexingArrayOf<Sideproject.ExternalAccount> = Sideproject.ExternalAccountStore.shared.accounts + (Sideproject.ExternalAccountStore.shared._testAccounts ?? [])
        
        return try allAccounts.compactMap { (account: Sideproject.ExternalAccount) in
            let credential = CoreMI._ServiceCredentialTypes.APIKeyCredential (
                apiKey: (account.credential as! Sideproject.ExternalAccountCredentialTypes.APIKey).key
            )
            
            let service: CoreMI._ServiceVendorIdentifier = try account.accountType.__conversion()
            
            return CoreMI._AnyServiceAccount(
                serviceVendorIdentifier: service,
                credential: credential
            )
        }
    }
    
    /// Initializes all CoreMI services that can be initialized using the loaded Sideproject accounts.
    private func _makeServices(
        forAccounts serviceAccounts: [CoreMI._AnyServiceAccount]
    ) async throws -> [any CoreMI._ServiceClientProtocol] {
        @_StaticMirrorQuery(type: (any CoreMI._ServiceClientProtocol).self)
        var serviceTypes: [any CoreMI._ServiceClientProtocol.Type]
        
        var result: [any CoreMI._ServiceClientProtocol] = await serviceAccounts
            .asyncMap { account in
                await serviceTypes.first(byUnwrapping: { type -> (any CoreMI._ServiceClientProtocol)? in
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
        if let ollama = try await serviceTypes.firstAndOnly(byUnwrapping: { try? await $0.init(account: CoreMI._AnyServiceAccount(serviceVendorIdentifier: ._Ollama, credential: nil)) }) {
            result += ollama
        }
        
        return result
    }
}

extension Sideproject {
    public enum Error: Swift.Error {
        case failedToDiscoverServices
        case failedToResolveLLMService
        case failedToResolveService(AnyError)
        case failedToResolveLLMForModel(ModelIdentifier)
        case completionFailed(AnyError)
    }
}

extension Sideproject.ExternalAccountTypeIdentifier: CoreMI._ServiceVendorIdentifierConvertible {
    public func __conversion() throws -> CoreMI._ServiceVendorIdentifier {
        switch self {
            case Sideproject.ExternalAccountTypeDescriptors.Anthropic().accountType:
                return ._Anthropic
            case Sideproject.ExternalAccountTypeDescriptors.ElevenLabs().accountType:
                return ._ElevenLabs
            case Sideproject.ExternalAccountTypeDescriptors.FalAI().accountType:
                return ._Fal
            case Sideproject.ExternalAccountTypeDescriptors.Groq().accountType:
                return ._Groq
            case Sideproject.ExternalAccountTypeDescriptors.HuggingFace().accountType:
                return ._HuggingFace
            case Sideproject.ExternalAccountTypeDescriptors.HumeAI().accountType:
                return ._HumeAI
            case Sideproject.ExternalAccountTypeDescriptors.Mistral().accountType:
                return ._Mistral
            case Sideproject.ExternalAccountTypeDescriptors.OpenAI().accountType:
                return ._OpenAI
            case Sideproject.ExternalAccountTypeDescriptors.Perplexity().accountType:
                return ._Perplexity
            case Sideproject.ExternalAccountTypeDescriptors.Replicate().accountType:
                return ._Replicate
            case Sideproject.ExternalAccountTypeDescriptors.PlayHT().accountType:
                return ._PlayHT
            case Sideproject.ExternalAccountTypeDescriptors.NeetsAI().accountType:
                return ._NeetsAI
            case Sideproject.ExternalAccountTypeDescriptors.Rime().accountType:
                return ._Rime
            default:
                throw Never.Reason.unexpected
        }
    }
}
