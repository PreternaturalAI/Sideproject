//
// Copyright (c) Vatsal Manot
//

import CoreMI
import LargeLanguageModels
import OpenAI
import Swallow

extension Sideproject: TextEmbeddingsRequestHandling {
    @MainActor
    private func _embedder(
        for request: TextEmbeddingsRequest
    ) async throws -> any TextEmbeddingsRequestHandling {
        try await _catchAndMapError(to: Error.failedToResolveService) {
            var model: _MLModelIdentifier? = request.model
            
            if model == nil {
                model = OpenAI.Model.embedding(.text_embedding_3_large).__conversion() // FIXME
            }
            
            let services = try await self.services
            
            let llms = services.compactMap({ $0 as? (any TextEmbeddingsRequestHandling) })
            
            return try llms
                .first(where: {
                    $0._availableModels?.contains(try model.unwrap()) ?? false
                })
                .unwrap()
        }
    }
    
    public func fulfill(
        _ request: TextEmbeddingsRequest
    ) async throws -> TextEmbeddings {
        let provider = try await _embedder(for: request)
        
        return try await provider.fulfill(request)
    }
}
