//
// Copyright (c) Vatsal Manot
//

import AI
import LargeLanguageModels
import Swallow

extension Sideproject: LLMRequestHandling {
    public func complete<Prompt: AbstractLLM.Prompt>(
        prompt: Prompt,
        parameters: Prompt.CompletionParameters
    ) async throws -> Prompt.Completion {
        var prompt = prompt
        let llm = try await _llmRequestHandler(for: &prompt)
        
        return try await llm.complete(
            prompt: prompt,
            parameters: parameters
        )
    }
    
    public func completion(
        for prompt: AbstractLLM.ChatPrompt
    ) async throws -> AbstractLLM.ChatCompletionStream {
        var prompt = prompt
        let llm = try await _llmRequestHandler(for: &prompt)
        
        return try await llm.completion(for: prompt)
    }
}

extension Sideproject {
    /// Find an appropriate LLM request handler for the given prompt.
    private func _llmRequestHandler<T: AbstractLLM.Prompt>(
        for prompt: inout T
    ) async throws -> (any LLMRequestHandling) {
        try await _assertNonZeroServices()
        
        var _prompt: any AbstractLLM.Prompt = prompt
        
        let model: ModelIdentifier = try await self._model(for: &_prompt)
     
        prompt = try! cast(_prompt, to: T.self)
        
        let services = try await self.services
        let llms: [(any LLMRequestHandling)] = services.compactMap({ $0 as? (any LLMRequestHandling) })
        
        do {
            let llm = try await _findLLMRequestHandler(for: model, from: llms)
            
            return llm
        } catch {
            if let llm = llms.first(where: { $0._availableModels?.contains(model) ?? false }) {
                return llm
            } else {
                throw error
            }
        }
    }
    
    
    private func _findLLMRequestHandler(
        for model: ModelIdentifier,
        from llms: [(any LLMRequestHandling)]
    ) async throws -> (any LLMRequestHandling) {
        try await _catchAndMapError(to: Error.failedToResolveLLMForModel(model)) {
            let result = try await llms
                .firstAndOnly(where: { llm in
                    try await _resolveMaybeAsync(llm)
                    
                    return llm._availableModels?.contains(model) ?? false
                })
                .unwrap()
            
            return result
        }
    }
    
    private func _model(
        for prompt: inout (any AbstractLLM.Prompt)
    ) async throws -> ModelIdentifier {
        var result: ModelIdentifierScope
        
        if let modelIdentifier = prompt.context.get(\.modelIdentifier) {
            result = modelIdentifier
        } else {
            if 
                let prompt = (prompt as? AbstractLLM.ChatPrompt),
                let modelIdentifier = prompt.messages.first(byUnwrapping: { $0.content.stringInterpolation._sharedContext.modelIdentifier })
            {
                result = modelIdentifier
            } else {
                result = .one(OpenAI.Model.chat(.gpt_4_turbo).__conversion())
            }
        }
        
        if prompt.context.modelIdentifier == nil {
            prompt.context.modelIdentifier = result
        }
        
        return try! result._oneValue
    }
}

extension LLMRequestHandling {
    fileprivate func _unconditionallySupports(
        _ model: ModelIdentifier
    ) async throws -> Bool? {
        try await _resolveMaybeAsync(self)
        
        return _availableModels?.contains(model)
    }
}
