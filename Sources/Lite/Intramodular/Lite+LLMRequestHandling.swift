//
// Copyright (c) Vatsal Manot
//

import LargeLanguageModels
import Swallow

extension Lite: LLMRequestHandling {
    public func complete<Prompt: AbstractLLM.Prompt>(
        prompt: Prompt,
        parameters: Prompt.CompletionParameters
    ) async throws -> Prompt.Completion {
        var prompt = prompt
        let llm = try await _llmService(for: &prompt)
        
        return try await llm.complete(
            prompt: prompt,
            parameters: parameters
        )
    }
    
    public func completion(
        for prompt: AbstractLLM.ChatPrompt
    ) async throws -> AbstractLLM.ChatCompletionStream {
        var prompt = prompt
        let llm = try await _llmService(for: &prompt)
        
        return try await llm.completion(for: prompt)
    }
    
    @MainActor
    private func _llmService<T: AbstractLLM.Prompt>(
        for prompt: inout T
    ) async throws -> (any LLMRequestHandling) {
        var _prompt: any AbstractLLM.Prompt = prompt
        
        let model = try await self._model(for: &_prompt)
     
        prompt = try! cast(_prompt, to: T.self)
        
        let services = try await self.services
        let llms = services.compactMap({ $0 as? (any LLMRequestHandling) })
        
        do {
            let result = try await llms
                .firstAndOnly(where: { llm in
                    try await _resolveMaybeAsync(llm)
                    
                    return llm._availableModels?.contains(model) ?? false
                })
                .unwrap()
            
            return result
        } catch {
            if let llm = llms.first(where: { $0._availableModels?.contains(model) ?? false }) {
                return llm
            } else {
                throw error
            }
        }
    }
    
    private func _model(
        for prompt: inout (any AbstractLLM.Prompt)
    ) async throws -> _MLModelIdentifier {
        var result: _MLModelIdentifierScope
        
        if let modelIdentifier = prompt.context.get(\.modelIdentifier) {
            result = modelIdentifier
        } else {
            if 
                let prompt = (prompt as? AbstractLLM.ChatPrompt),
                let modelIdentifier = prompt.messages.first(byUnwrapping: { $0.content.stringInterpolation._sharedContext.modelIdentifier })
            {
                result = modelIdentifier
            } else {
                result = .one(OpenAI.Model.chat(.gpt_4_32k_0314).__conversion())
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
        _ model: _MLModelIdentifier
    ) async throws -> Bool? {
        try await _resolveMaybeAsync(self)
        
        return _availableModels?.contains(model)
    }
}
