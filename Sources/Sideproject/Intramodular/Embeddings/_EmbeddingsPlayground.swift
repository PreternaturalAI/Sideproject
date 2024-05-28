//
// Copyright (c) Vatsal Manot
//

import Accelerate
import Cataphyl
import Merge
import LargeLanguageModels
import OpenAI
import SwiftUI

public struct _EmbeddingsPlayground: Codable, Hashable, Sendable {
    public var query: String? {
        didSet {
            cache = .init()
        }
    }
    public var data: [String] = [] {
        didSet {
            cache = .init()
        }
    }
    
    public var cache = Cache()
    
    public init() {
        
    }
}

extension _EmbeddingsPlayground {
    public final class PlaygroundSession: _CancellablesProviding, ObservableObject {
        @Dependency(\.embedding) var textEmbeddingsProvider
        
        @PublishedAsyncBinding public var document: _EmbeddingsPlayground
        
        public init(document: PublishedAsyncBinding<_EmbeddingsPlayground>) {
            self._document = document
            
            $document
                .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
                .sink { _ in
                    Task { @MainActor in
                        try await self.embed()
                    }
                    ._expectNoThrow()
                }
                .store(in: cancellables)
        }
        
        @MainActor
        func embed() async throws {
            guard document.cache.embeddings.query == nil || document.cache.embeddings.data == nil || document.cache.comparison == .init() else {
                return
            }
            
            let lite = Sideproject.shared
            
            let query = try document.query.unwrap()
            let data = document.data
            
            let embeddingModel = OpenAI.Model.embedding(.text_embedding_3_large)
            
            self.document.cache = try .init(
                embeddings: .init(
                    query: try await lite.textEmbedding(for: query, model: embeddingModel),
                    data: try await lite.textEmbeddings(for: data, model: embeddingModel).data.map {
                        $0.embedding
                    }
                ),
                query: query,
                data: data
            )
        }
    }
}

// MARK: - Auxiliary

extension _EmbeddingsPlayground {
    public struct Cache: Codable, Hashable, Sendable {
        public struct Embeddings: Codable, Hashable, Sendable {
            public var query: _RawTextEmbedding?
            public var data: [_RawTextEmbedding]?
        }
        
        public struct Comparison: Codable, Hashable, Sendable {
            public var scoresByIndex: [Int: Double] = [:]
        }
        
        public var embeddings = Embeddings()
        public var comparison = Comparison()
        
        init(
            embeddings: Embeddings,
            query: String,
            data: [String]
        ) throws {
            self.embeddings = embeddings
            self.comparison = .init(scoresByIndex: try Dictionary(uniqueKeysWithValues: data.indices.map { index in
                let queryEmbedding = try embeddings.query.unwrap().rawValue
                let dataEmbedding = try embeddings.data.unwrap()[index].rawValue
                
                let similarity = (vDSP.cosineSimilarity(lhs: queryEmbedding, rhs: dataEmbedding))
                
                return (index, similarity)
            }))
        }
        
        init() {
            
        }
    }
}
