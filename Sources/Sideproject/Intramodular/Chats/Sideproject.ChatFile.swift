//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import LargeLanguageModels
import Swallow

extension Sideproject {
    /// A document that represents a chat with an AI assistant.
    public struct ChatFile: Codable, Hashable, Identifiable, PersistentIdentifierConvertible {
        public typealias ID = _TypeAssociatedID<Self, UUID>
        
        public var id: ID
        public var metadata = Metadata()
        public var messages: IdentifierIndexingArrayOf<Sideproject.ChatFile.Message> = []
        @_UnsafelySerialized
        public var preset: (any Sideproject.ChatFile.Preset)?
        @_UnsafelySerialized
        public var model: ModelIdentifier? = "gpt-3.5-turbo"
        
        public init(id: ID) {
            self.id = .random()
        }
        
        public init() {
            self.init(id: .random())
        }
    }
}

extension Sideproject.ChatFile {
    public struct Metadata: Codable, Hashable, Sendable {
        public var creationDate: Date = Date()
        public var sendDate: Date?
        public var displayName: String = "Untitled"
    }
}

extension Sideproject.FileStore {
    public struct Selection: Codable, Hashable, Initiable, Sendable {
        public var documents: Set<Sideproject.File.ID> = []
        
        public init() {
            
        }
    }
}
