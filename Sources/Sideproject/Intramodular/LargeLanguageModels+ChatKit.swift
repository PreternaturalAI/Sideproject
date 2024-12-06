//
// Copyright (c) Vatsal Manot
//

import AI
import ChatKit
import LargeLanguageModels

extension AbstractLLM.ChatMessage: ChatKit.ChatMessageConvertible {
    public func __conversion() -> AnyChatMessage {
        AnyChatMessage(
            id: self.id,
            role: self.role.__conversion(),
            body: self.content.debugDescription
        )
    }
}

extension AbstractLLM.ChatRole: ChatKit.ChatItemRoleConvertible {
    public func __conversion() -> any ChatItemRole {
        switch self {
            case .system:
                return ChatItemRoles.SenderRecipient.sender // FIXME: !!!
            case .user:
                return ChatItemRoles.SenderRecipient.sender
            case .assistant:
                return ChatItemRoles.SenderRecipient.recipient
            case .other:
                fatalError()
        }
    }
}
