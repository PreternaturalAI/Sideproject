//
// Copyright (c) Vatsal Manot
//

import Cataphyl

extension LTDocumentStore {
    public func embedAllDocumentsIfNeeded() async throws {
        if textEmbeddings.isEmpty {
            try await embedAllDocuments()
        }
    }
    
    public func embedAllDocuments() async throws {
        try await internalTasks.perform {
            try await _embedAllDocuments()
        }
    }
    
    private func _embedAllDocuments() async throws {
        logger.info("Embedding \(self.documents.count) document(s).")
        
        textEmbeddings.removeAll()
        
        do {
            try await self.documents.concurrentForEach { document in
                try await document.ingest()
                
                logger.info("Embedding \(document.id.rawValue)")
                
                try await document.embed()
            }
            
            assert(Array(textEmbeddings.map(\.document).distinct()).count == documents.count)
            
            logger.info("Finished embedding \(self.documents.count) document(s).")
        } catch {
            logger.error(error)
            
            throw error
        }
        
        $textEmbeddings.commit()
    }
}
