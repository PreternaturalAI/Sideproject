//
// Copyright (c) Vatsal Manot
//

import Cataphyl
import CorePersistence
import Swallow

/// A document that has been ingested by our app.
///
/// For the purposes of this app, we only need to store the text of the document.
///
/// In a real-world application, you'd likely want to store the source file/data of the document along with other metadata.
public final class LTDocument: Codable, Identifiable, _LogicalParentConsuming, ObservableObject {
    public typealias ID = _TypeAssociatedID<LTDocument, UUID>
    public typealias LogicalParentType = LTDocumentStore
    
    public struct Metadata: Codable, Hashable, Sendable {
        public var creationDate: Date
        public var displayName: String
        
        public init(
            creationDate: Date = Date(),
            displayName: String = "Untitled"
        ) {
            self.creationDate = creationDate
            self.displayName = displayName
        }
    }
    
    public var id: ID
    
    @MainActor @Published public var metadata: Metadata
    @MainActor @Published public var url: URL?
    @MainActor @Published public var rawText: PlainTextDocument?
    
    @Published public var indexingInterval: IndexingInterval?
    
    @LogicalParent public var dataStore: LTDocumentStore
    
    @MainActor
    public init() {
        self.id = .random()
        self.metadata = .init()
    }
    
    @MainActor
    public init(
        id: ID,
        metadata: Metadata = .init(),
        rawText: PlainTextDocument?,
        in store: LTDocumentStore
    ) {
        self._dataStore = .init(_wrappedValue: store)
        self.id = id
        self.metadata = metadata
        self.rawText = rawText
    }
    
    @MainActor
    public convenience init(
        id: ID,
        metadata: Metadata = .init(),
        rawText: String?,
        in store: LTDocumentStore
    ) {
        self.init(
            id: id,
            metadata: metadata,
            rawText: rawText.map(PlainTextDocument.init(text:)),
            in: store
        )
    }
}

extension LTDocument {
    @MainActor
    public func delete() {
        if let url = url, url.isFileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

extension LTDocument {
    @MainActor
    public convenience init(url: WebLocationDocument) {
        self.init()
        
        self.url = url.url
        self.metadata.displayName = url.url.absoluteString
    }
    
    @MainActor
    public convenience init(rawText: PlainTextDocument) {
        self.init()
        
        self.rawText = rawText
    }
    
    @MainActor
    public convenience init(url: URL) throws {
        self.init()
        
        if url.isFileURL {
            let newURL = try URL(
                directory: .userDocuments,
                subdirectory: "files",
                filename: UUID().uuidString
            ).appendingPathExtension(url._fileExtension)
            
            try FileManager.default.createDirectoryIfNecessary(at: newURL.deletingLastPathComponent())
            
            try FileManager.default.copyItem(at: url, to: newURL)
            
            self.url = newURL
            self.metadata.displayName = url._fileNameWithoutExtension
        } else if url.isWebURL {
            self.init(url: WebLocationDocument(url: url))
        } else {
            assertionFailure()
        }
    }
}

// MARK: - Auxiliary

extension LTDocument {
    public enum IndexingInterval: String, Codable, Hashable, Sendable {
        case assessing
        case preparing
        case indexing
    }
}
