//
// Copyright (c) Vatsal Manot
//

import Cataphyl
import Diagnostics
import CorePersistence
import Swallow

/// A document that has been ingested by our app.
///
/// For the purposes of this app, we only need to store the text of the document.
///
/// In a real-world application, you'd likely want to store the source file/data of the document along with other metadata.
extension Sideproject {
    public final class File: Codable, Identifiable, Logging, _LogicalParentConsuming, ObservableObject {
        public typealias ID = _TypeAssociatedID<Sideproject.File, UUID>
        public typealias LogicalParentType = Sideproject.FileStore
        
        public var id: ID
        
        @MainActor @Published public var metadata: Metadata
        
        @MainActor @Published public var url: URL? {
            didSet {
                if let oldValue, let newValue = url, newValue != oldValue {
                    self.rawText = nil
                }
            }
        }
        @MainActor @Published public var rawText: PlainTextDocument? {
            didSet {
                _markAsPendingEmbedding()
            }
        }
        
        @Published public var indexingInterval: IndexingInterval?
        
        @LogicalParent public var dataStore: Sideproject.FileStore
        
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
            in store: Sideproject.FileStore
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
            in store: Sideproject.FileStore
        ) {
            self.init(
                id: id,
                metadata: metadata,
                rawText: rawText.map(PlainTextDocument.init(text:)),
                in: store
            )
        }
        
        @MainActor
        private func _markAsPendingEmbedding() {
            guard dataStore.documents[id: self.id] != nil else {
                return
            }
            
            dataStore.state.documentsToEmbed.insert(self.id)
        }
    }
}

extension Sideproject.File {
    @MainActor
    public var displayIdentifier: AnyHashable {
        self.metadata.persistentID?.erasedAsAnyHashable ?? id.erasedAsAnyHashable
    }
}

extension Sideproject.File {
    @MainActor
    public func delete() {
        if let url = url, url.isFileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

// MARK: - Auxiliary

extension Sideproject.File {
    public struct Metadata: Codable, Hashable, Sendable {
        public var persistentID: AnyPersistentIdentifier? {
            didSet {
                if let oldValue, persistentID != oldValue {
                    assertionFailure("Changing a document's persistent ID is currently unsupported.")
                }
            }
        }
        public var creationDate: Date
        public var displayName: String
        
        public init(
            persistentID: AnyPersistentIdentifier? = nil,
            creationDate: Date = Date(),
            displayName: String = "Untitled"
        ) {
            self.persistentID = persistentID
            self.creationDate = creationDate
            self.displayName = displayName
        }
    }

    public enum IndexingInterval: String, Codable, Hashable, Sendable {
        case assessing
        case preparing
        case indexing
    }
}
