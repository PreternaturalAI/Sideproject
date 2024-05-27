//
// Copyright (c) Vatsal Manot
//

import Cataphyl
import CorePersistence
import Merge
import Swallow

public enum DataStoreError: Error {
    case failedToIndex(Sideproject.File.ID)
}

@MainActor
extension Sideproject.FileStore {
    public func addDocuments(
        _ documents: [Sideproject.File]
    ) {
        _insertDocumentsDeduplicatingIfNecessary(documents)
    }
    
    public func addDocument(
        _ document: Sideproject.File
    ) {
        _insertDocumentsDeduplicatingIfNecessary([document])
    }
    
    public func addDocuments<T: Sideproject.FileConvertible>(
        _ documents: some Sequence<T>
    ) async throws {
        let documents: [Sideproject.File] = try await documents.concurrentMap({ item in
            try await _withLogicalParent(self) {
                try await item.__conversion()
            }
        })
        
        _insertDocumentsDeduplicatingIfNecessary(documents)
    }
    
    public func addDocument(_ url: URL) throws {
        let document = try _withLogicalParent(self) {
            try Sideproject.File(url: url)
        }
        
        _insertDocumentsDeduplicatingIfNecessary([document])
    }
    
    @MainActor
    public func remove(_ document: Sideproject.File) throws {
        let embeddingsToRemove = self.textEmbeddings.keys.filter({ $0.document == document.id })
        
        try self.textEmbeddings.remove(embeddingsToRemove)
        
        self.state.documentsToEmbed.remove(document.id)
        self.documents.remove(document)
        
        document.delete()
    }
    
    @discardableResult
    private func _insertDocumentsDeduplicatingIfNecessary(
        _ incomingDocuments: [Sideproject.File]
    ) -> [Sideproject.File] {
        var documentsSkipped: Set<Sideproject.File.ID> = []
        
        let documentsToInsert: [Sideproject.File] = incomingDocuments.filter { (incoming: Sideproject.File) -> Bool in
            guard let incomingPersistentID: AnyPersistentIdentifier = incoming.metadata.persistentID else {
                return true
            }
            
            if let existingID = self.documentsByPersistentIdentifier[incomingPersistentID] {
                let existingDocument = self.documents[id: existingID]!
                
                if existingDocument.rawText != incoming.rawText {
                    existingDocument.rawText = incoming.rawText
                }
                
                documentsSkipped.insert(incoming.id)
                
                return false // skip the incoming document as it already exists
            }
            
            return true
        }
        
        guard !documentsToInsert.isEmpty else {
            return []
        }
        
        self.documents.append(contentsOf: documentsToInsert)
        self.state.documentsToEmbed.subtract(documentsSkipped)
        self.state.documentsToEmbed.insert(contentsOf: documentsToInsert.map(\.id))
        
        internalTasks.addTask { @MainActor in
            try await documentsToInsert.concurrentForEach { document in
                try await document._ingest()
            }
            
            try await _embedPendingDocuments()
        }
        
        return documentsToInsert
    }
}

extension Sideproject.FileStore {
    @MainActor
    public subscript(
        _ key: Sideproject.File.ID
    ) -> Sideproject.File? {
        get {
            #try(.optimistic) {
                try documents[id: key].unwrap()
            }
        }
    }
}
