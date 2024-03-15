//
// Copyright (c) Vatsal Manot
//

import Foundation

public protocol DocumentStore<Document> {
    associatedtype Document: Identifiable
    
    func fetchDocument(
        _ document: Document.ID
    ) async throws -> Document
}

public struct AnyDocumentStore<Document: Identifiable>: DocumentStore {
    private let base: any DocumentStore<Document>
    
    public init(erasing base: any DocumentStore<Document>) {
        self.base = base
    }
    
    public func fetchDocument(
        _ document: Document.ID
    ) async throws -> Document {
        func _fetch<Store: DocumentStore<Document>>(_ store: Store) async throws -> Document {
            try await store.fetchDocument(document)
        }
        
        return try await _openExistential(base, do: _fetch)
    }
}
