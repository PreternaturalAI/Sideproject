//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import LargeLanguageModels
import Swallow

/// A document that represents a chat with an AI assistant.
public struct LTChatDocument: Codable, Hashable, Identifiable, PersistentIdentifierConvertible {
    public typealias ID = _TypeAssociatedID<Self, UUID>
    
    public struct Metadata: Codable, Hashable, Sendable {
        public var creationDate: Date = Date()
        public var sendDate: Date?
        public var displayName: String = "Untitled"
    }
    
    public var id: ID
    public var metadata = Metadata()
    public var messages: IdentifierIndexingArrayOf<Message> = []
    @_UnsafelySerialized
    public var preset: (any LTChatDocument.Preset)?
    @_UnsafelySerialized
    public var model: _MLModelIdentifier? = "gpt-3.5-turbo"
    
    public init(id: ID) {
        self.id = .random()
    }
    
    public init() {
        self.init(id: .random())
    }
}

extension LTDocumentStore {
    public struct Selection: Codable, Hashable, Initiable, Sendable {
        public var documents: Set<LTDocument.ID> = []
        
        public init() {
            
        }
    }
}
