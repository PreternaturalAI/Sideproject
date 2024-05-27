//
// Copyright (c) Vatsal Manot
//

#if canImport(ChatKit)

import ChatKit
import OpenAI

extension OpenAI.Message: AnyChatMessageConvertible {
    public func __conversion() -> AnyChatMessage {
        AnyChatMessage(
            id: self.id,
            isSender: self.role == .user ? true : false,
            body: self.debugDescription
        )
    }
}

#endif
