//
// Copyright (c) Vatsal Manot
//

import Cataphyl
import CorePersistence
import Merge
import Swallow

public enum DataStoreError: Error {
    case failedToIndex(LTDocument.ID)
}

extension LTDocumentStore {
    @MainActor
    public func addDocument(_ document: LTDocument) {
        self.documents.append(document)
        
        internalTasks.addTask { @MainActor in
            try await document.ingest()
        }
    }

    @MainActor
    public func addDocument(_ url: URL) throws {
        let document = try _withLogicalParent(self) {
            try LTDocument(url: url)
        }
        
        self.documents.append(document)
        
        internalTasks.addTask { @MainActor in
            try await document.ingest()
        }
    }
    
    @MainActor
    public func remove(_ document: LTDocument) throws {
        document.delete()
        
        self.documents.remove(document)
    }
}

extension LTDocumentStore {
    public subscript(
        _ key: LTDocument.ID
    ) -> LTDocument? {
        get {
            _expectNoThrow {
                try! documents[id: key].unwrap()
            }
        }
    }
}
