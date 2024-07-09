//
// Copyright (c) Vatsal Manot
//

import ChatKit
import CorePersistence
import LargeLanguageModels
import Swallow

extension Sideproject.ChatFile {
    @dynamicMemberLookup
    public struct Message: Codable, Hashable, Identifiable, Sendable {
        public typealias ID = AnyPersistentIdentifier

        public struct Metadata: Codable, Hashable, Sendable {
            public var creationDate: Date = Date()
            public var sendDate: Date?
        }

        public let id: ID

        /// We use `AbstractLLM.ChatMessage` from `LargeLanguageModels` as a base message type because it is built to store useful metadata (token usage, logprobs etc.)
        public var base: AbstractLLM.ChatMessage
        
        public var metadata = Metadata()
        
        public init(
            base: AbstractLLM.ChatMessage,
            id: ID
        ) {
            self.base = base
            
            if let existingID: AnyPersistentIdentifier = self.base.id {
                assert(existingID == id)
            } else {
                self.base.id = id
            }
            
            self.id = id
            self.metadata = .init()
        }
    }
}

extension Sideproject.ChatFile.Message {
    public subscript<T>(
        dynamicMember keyPath: KeyPath<AbstractLLM.ChatMessage, T>
    ) -> T {
        get {
            base[keyPath: keyPath]
        }
    }
    
    public subscript<T>(
        dynamicMember keyPath: WritableKeyPath<AbstractLLM.ChatMessage, T>
    ) -> T {
        get {
            base[keyPath: keyPath]
        } set {
            base[keyPath: keyPath] = newValue
        }
    }
}

extension Sideproject.ChatFile.Message: AbstractLLM.ChatMessageConvertible {
    public init(_ message: AbstractLLM.ChatMessage) {
        self.init(
            base: message,
            id: message.id ?? AnyPersistentIdentifier(erasing: UUID())
        )
    }
    
    public func __conversion() -> AbstractLLM.ChatMessage {
        self.base
    }
}

extension Sideproject.ChatFile.Message: AnyChatMessageConvertible {    
    public func __conversion() -> AnyChatMessage {
        self.base.__conversion()
    }
}
