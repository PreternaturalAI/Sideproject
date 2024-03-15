//
// Copyright (c) Vatsal Manot
//

import ChatKit
import CoreMI
import Diagnostics
import LargeLanguageModels
import Merge
import OpenAI

@MainActor
public class LTChatPlayground: Logging, ObservableObject {
    private let cancellables = Cancellables()
    private let taskQueue = TaskQueue()
    
    private let llm: LLMRequestHandling
    
    @PublishedAsyncBinding
    public var document: LTChatDocument
    
    @Published public var interactionState: InteractionState = .idle
    @Published public var ephemeralOptions = EphemeralOptions()
    @Published public var activityPhaseOfLastItem: ChatItemActivityPhase = .idle
    
    public init(
        document: PublishedAsyncBinding<LTChatDocument>
    ) {
        self._document = document
        self.llm = Lite.shared
    }
    
    public func sendMessage(
        _ message: String
    ) {
        sendMessage(LTChatDocument.Message(AbstractLLM.ChatMessage(role: .user, content: message)))
    }
    
    public func sendMessage(
        _ message: LTChatDocument.Message
    ) {
        taskQueue.addTask { @MainActor in
            assert(interactionState == .idle)
            
            do {
                var wantsStream: Bool = true
                
                let messageID = message.id
                
                if let existingMessageIndex = self.document.messages.index(ofElementIdentifiedBy: messageID) {
                    if self.document.messages[existingMessageIndex].content != message.content {
                        self.document.messages[existingMessageIndex] = message
                        
                        if existingMessageIndex == self.document.messages.lastIndex {
                            wantsStream = false
                        }
                    }
                } else {
                    self.document.messages.append(message)
                }
                
                guard wantsStream else {
                    return
                }
                
                try await send()
                
                self.activityPhaseOfLastItem = .idle
            } catch {
                self.logger.error(error)
                
                self.interactionState = .idle
                self.activityPhaseOfLastItem = .failed(error)
            }
        }
    }
    
    public func interrupt() {
        taskQueue.cancelAll()
    }
    
    @MainActor
    private func send() async throws {
        let preset = self.document.preset.map({ $0 as! LTChatDocument.Presets.SystemMessage })
        
        let systemMessage = LTChatDocument.Message(AbstractLLM.ChatMessage.system(preset?.systemMessage ?? "You are a friendly assistant"))
        let messages: [LTChatDocument.Message] = [systemMessage] + self.document.messages
        
        self.interactionState = .streaming
        self.activityPhaseOfLastItem = .sending
        
        var latestMessage: LTChatDocument.Message?
        
        let completion: AbstractLLM.ChatCompletionStream = try await self.llm.stream(
            messages.map({ $0.base }),
            model: self.document.model ?? OpenAI.Model.chat(.gpt_4).__conversion()
        )
        
        try await withTaskCancellationHandler { @MainActor in
            let publisher = completion.throttle(for: .milliseconds(50), scheduler: DispatchQueue.main, latest: true)
            
            try await publisher._asyncSink { _ in
                if let message = completion.partialMessage {
                    latestMessage = LTChatDocument.Message(message)
                    
                    self.document.messages.updateOrAppend(LTChatDocument.Message(message))
                }
            }
            
            self.interactionState = .idle
            self.activityPhaseOfLastItem = .idle
        } onCancel: {
            Task { @MainActor in
                if let latestMessage {
                    delete(latestMessage.id)
                }
                
                self.interactionState = .idle
                self.activityPhaseOfLastItem = .idle
            }
        }
        
        self.interactionState = .idle
        self.activityPhaseOfLastItem = .idle
    }
    
    public func delete(
        _ message: LTChatDocument.Message.ID
    ) {
        document.messages.removeAll(where: { message == $0.id })
    }
}

extension LTChatPlayground {
    public enum InteractionState {
        case idle
        case streaming
    }
    
    public struct EphemeralOptions {
        public var rolesReversed: Bool = false
        public var contextFree: Bool = false
    }
}
