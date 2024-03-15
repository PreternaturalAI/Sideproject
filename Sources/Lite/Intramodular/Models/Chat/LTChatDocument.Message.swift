//
// Copyright (c) Vatsal Manot
//

import ChatKit
import CorePersistence
import LargeLanguageModels
import Swallow

extension LTChatDocument {
    @dynamicMemberLookup
    public struct Message: Codable, Hashable, Identifiable, Sendable {
        public typealias ID = _TypeAssociatedID<Self, UUID>
        
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
            self.id = id
            self.metadata = .init()
        }
    }
}

extension LTChatDocument.Message {
    public subscript<T>(
        dynamicMember keyPath: KeyPath<AbstractLLM.ChatMessage, T>
    ) -> T {
        get {
            base[keyPath: keyPath]
        }
    }
}

extension LTChatDocument.Message: AbstractLLM.ChatMessageConvertible {
    public init(_ message: AbstractLLM.ChatMessage) {
        self.init(base: message, id: .random())
    }
    
    public func __conversion() -> AbstractLLM.ChatMessage {
        self.base
    }
}

extension LTChatDocument.Message: AnyChatMessageConvertible {    
    public func __conversion() -> AnyChatMessage {
        self.base.__conversion()
    }
}
