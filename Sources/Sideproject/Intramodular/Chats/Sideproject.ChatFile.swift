//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import LargeLanguageModels
import Swallow

extension Sideproject {
    /// A document that represents a chat with an AI assistant.
    public struct ChatFile: Codable, Hashable, Identifiable, Initiable, PersistentIdentifierConvertible {
        public typealias ID = AnyPersistentIdentifier
        
        public var id: ID
        public var metadata = Metadata()
        public var messages: IdentifierIndexingArrayOf<Sideproject.ChatFile.Message> = []
        @_UnsafelySerialized
        public var preset: (any Sideproject.ChatFile.Preset)?
        @_UnsafelySerialized
        public var model: ModelIdentifier? = "gpt-3.5-turbo"
        
        public var persistentID: AnyPersistentIdentifier {
            id
        }
        
        public init(id: ID) {
            self.id = id
        }
        
        public init() {
            self.init(id: .init(erasing: UUID()))
        }
    }
}

extension Sideproject.ChatFile {
    public init<T: AbstractLLM.ChatMessageConvertible>(
        messages: some Sequence<T>
    ) throws {
        self.init()
        
        let messages: [AbstractLLM.ChatMessage] = try messages.map({ try $0.__conversion() })
        
        self.messages = IdentifierIndexingArray(messages.map({
            Message(base: $0, id: $0.id ?? AnyPersistentIdentifier(erasing: UUID()))
        }))
    }
}

extension Sideproject.ChatFile {
    public struct Metadata: Codable, Hashable, Sendable {
        public var creationDate: Date = Date()
        public var sendDate: Date?
        public var displayName: String = "Untitled"
    }
}

