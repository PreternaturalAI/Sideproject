//
// Copyright (c) Vatsal Manot
//

import AI
import Cataphyl
import CorePersistence

extension Sideproject.FileStore {
    public struct SearchResult: Identifiable {
        public typealias ID = Sideproject.File.RetrievedFragment.ID
        
        private let store: Sideproject.FileStore
        
        public let fragmentID: Sideproject.File.RetrievedFragment.ID
        public let score: Double
        
        public var id: ID {
            fragmentID
        }
        
        @MainActor
        public var fragment: Sideproject.File.RetrievedFragment {
            get {
                try! self.store[fragmentID]
            }
        }
        
        init(
            store: Sideproject.FileStore,
            fragmentID: Sideproject.File.RetrievedFragment.ID,
            score: Double
        ) {
            self.store = store
            self.fragmentID = fragmentID
            self.score = score
        }
    }
}

extension Sideproject.FileStore {
    @MainActor
    public func search(
        query: some Sideproject.FileConvertible,
        maximumNumberOfResults: Int? = nil
    ) async throws -> [SearchResult] {
        let queryDocument: Sideproject.File = try await _withLogicalParent(self) {
            try await query.__conversion()
        }
        
        let queryEmbedding: SingleTextEmbedding = try await queryDocument
            ._embedWholeDocumentAsSingleEmbedding()
            .embedding
        
        let result: [SearchResult] = try textEmbeddings
            .query(
                .topMatches(
                    for: queryEmbedding,
                    maximumNumberOfResults: maximumNumberOfResults ?? self.documents.count
                )
            )
            .map { (item: RawVectorIndexSearchResult<NaiveRawVectorIndex<Sideproject.FileFragmentIdentifier>>) in
                SearchResult(
                    store: self,
                    fragmentID: item.item,
                    score: item.score
                )
            }
        
        return result
    }
    
    @MainActor
    public func search(
        query: String,
        maximumNumberOfResults: Int? = nil
    ) async throws -> [SearchResult] {
        try await embedPendingDocuments()
        
        let query: SingleTextEmbedding = try await withTaskTimeout(.seconds(2)) {
            return try await configuration.lite.singleTextEmbedding(for: query)
        }
        
        let result: [SearchResult] = try textEmbeddings
            .query(
                .topMatches(
                    for: query,
                    maximumNumberOfResults: maximumNumberOfResults ?? self.documents.count
                )
            )
            .map { (item: RawVectorIndexSearchResult<NaiveRawVectorIndex<Sideproject.FileFragmentIdentifier>>) in
                SearchResult(
                    store: self,
                    fragmentID: item.item,
                    score: item.score
                )
            }
        
        return result
    }
}

extension Sideproject.FileStore {
    @MainActor
    public func relevantMatches(
        for query: String
    ) async throws -> [SearchResult] {
        let queryEmbedding = try await withTaskTimeout(.seconds(2)) {
            logger.info("Beginning embedding query.")
            
            defer {
                logger.info("Finished embedding query.")
            }
            
            return try await Sideproject.shared.singleTextEmbedding(for: query).embedding
        }
        
        try await embedPendingDocuments()

        let result: [SearchResult] = try textEmbeddings
            .query(
                .topMatches(for: queryEmbedding.rawValue, maximumNumberOfResults: 5)
            )
            .map {
                SearchResult(
                    store: self,
                    fragmentID: $0.item,
                    score: $0.score
                )
            }
        
        return result
    }
}
