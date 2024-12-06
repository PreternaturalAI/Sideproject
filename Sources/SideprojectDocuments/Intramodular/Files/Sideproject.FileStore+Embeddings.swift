//
// Copyright (c) Vatsal Manot
//

import SideprojectCore
import Cataphyl

extension Sideproject.FileStore {
    @MainActor
    public func embedAllDocuments() async throws {
        try await internalTasks.perform {
            try await _embedPendingDocuments(removeAll: true)
        }
    }
    
    @MainActor
    public func embedPendingDocuments() async throws {
        try await internalTasks.perform {
            try await _embedPendingDocuments(removeAll: false)
        }
    }
    
    @MainActor
    private func _embedPendingDocuments(removeAll: Bool) async throws {
        if removeAll {
            await MainActor.run {
                self.textEmbeddings.removeAll()
                self.state.documentsToEmbed.insert(contentsOf: documents.map(\.id))
            }
        }
        
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
        let unembeddedDocuments = self.documents._mapToSet(\.id).subtracting(textEmbeddings._mapToSet(\.document.id))

        var documentIDs: Set<Sideproject.File.ID> = []
        
        documentIDs.insert(contentsOf: self.state.documentsToEmbed)
        documentIDs.insert(contentsOf: unembeddedDocuments)
        
        let result: [Sideproject.File] = documentIDs.compactMap({
            self.documents[id: $0]._selfAssumingNonNil
        })
                        
        self.state.documentsToEmbed = []
        
        return result
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
