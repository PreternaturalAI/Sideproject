//
// Copyright (c) Vatsal Manot
//

import Cataphyl

extension Sideproject.FileStore {
    @MainActor
    public func embedAllDocuments() async throws {
        try await internalTasks.perform {
            await MainActor.run {
                self.textEmbeddings.removeAll()
                self.state.documentsToEmbed.insert(contentsOf: documents.map(\.id))
            }
            
            try await _embedPendingDocuments()
        }
    }
    
    @MainActor
    public func embedPendingDocuments() async throws {
        try await internalTasks.perform {
            try await _embedPendingDocuments()
        }
    }
    
    @MainActor
    func _embedPendingDocuments() async throws {
        let documentsToEmbed: [Sideproject.File] = _isolateDocumentsToEmbed()
        
        do {
            logger.info("Embedding \(documentsToEmbed.count) document(s).")

            try await documentsToEmbed.concurrentForEach { document in
                try await document._ingest()
                try await document._embed()
            }
            
            assert(Array(textEmbeddings.map(\.document).distinct()).count == documents.count)
            
            logger.info("Finished embedding \(self.documents.count) document(s).")
        } catch {
            logger.error(error)
            
            throw error
        }
        
        $textEmbeddings.commit()
    }
    
    @MainActor
    private func _isolateDocumentsToEmbed() -> [Sideproject.File] {
        let documentsToEmbed: [Sideproject.File] = self.state.documentsToEmbed.compactMap({
            self.documents[id: $0]._selfAssumingNonNil
        })
                
        self.state.documentsToEmbed = []
        
        return documentsToEmbed
    }
}

// MARK: - Deprecated

extension Sideproject.FileStore {
    @available(*, deprecated, renamed: "embedPendingDocuments")
    @MainActor
    public func embedAllDocumentsIfNeeded() async throws {
        try await embedPendingDocuments()
    }
}
