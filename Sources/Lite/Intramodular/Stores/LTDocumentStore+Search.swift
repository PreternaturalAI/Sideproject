//
// Copyright (c) Vatsal Manot
//

import AI
import Cataphyl
import CorePersistence

extension LTDocumentStore {
    public struct SearchResult: Identifiable {
        public typealias ID = LTDocument.RetrievedFragment.ID
        
        private let store: LTDocumentStore
        
        public let fragmentID: LTDocument.RetrievedFragment.ID
        public let score: Double
        
        public var id: ID {
            fragmentID
        }
        
        @MainActor
        public var fragment: LTDocument.RetrievedFragment {
            get {
                try! self.store[fragmentID]
            }
        }
        
        init(
            store: LTDocumentStore,
            fragmentID: LTDocument.RetrievedFragment.ID,
            score: Double
        ) {
            self.store = store
            self.fragmentID = fragmentID
            self.score = score
        }
    }
}

extension LTDocumentStore {
    public func search(
        query: String,
        maximumNumberOfResults: Int? = nil
    ) async throws -> [SearchResult] {
        try await embedAllDocumentsIfNeeded()
        
        // "Depressing"
        let query: _RawTextEmbedding = try await withTaskTimeout(.seconds(2)) {
            return try await configuration.lite.textEmbedding(for: query)
        }
        
        let result: [SearchResult] = try textEmbeddings
            .query(
                .topMatches(
                    for: query,
                    maximumNumberOfResults: maximumNumberOfResults ?? self.documents.count
                )
            )
            .map { (item: VectorIndexSearchResult<NaiveVectorIndex<LTDocumentFragmentIdentifier>>) in
                SearchResult(
                    store: self,
                    fragmentID: item.item,
                    score: item.score
                )
            }
        
        return result
    }
}

extension LTDocumentStore {
    public func relevantMatches(
        for query: String
    ) async throws -> [SearchResult] {
        let queryEmbedding = try await withTaskTimeout(.seconds(2)) {
            logger.info("Beginning embedding query.")
            
            defer {
                logger.info("Finished embedding query.")
            }
            
            return try await Lite.shared.textEmbedding(for: query)
        }
        
        if textEmbeddings.isEmpty {
            try await embedAllDocuments()
        }
        
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
