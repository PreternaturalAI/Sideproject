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
public class SideprojectChatPlayground: Logging, ObservableObject {
    private let cancellables = Cancellables()
    private let taskQueue = TaskQueue()
    
    private let llm: LLMRequestHandling
    
    @PublishedAsyncBinding
    public var document: Sideproject.ChatFile
    
    @Published public var interactionState: InteractionState = .idle
    @Published public var ephemeralOptions = EphemeralOptions()
    @Published public var activityPhaseOfLastItem: ChatItemActivityPhase = .idle
    
    public init(
        document: PublishedAsyncBinding<Sideproject.ChatFile>
    ) {
        self._document = document
        self.llm = Sideproject.shared
    }
    
    public func sendMessage(
        _ message: String
    ) {
        sendMessage(Sideproject.ChatFile.Message(AbstractLLM.ChatMessage(role: .user, content: message)))
    }
    
    public func sendMessage(
        _ message: Sideproject.ChatFile.Message
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
        let preset = self.document.preset.map({ $0 as! Sideproject.ChatFile.Presets.SystemMessage })
        
        let systemMessage = Sideproject.ChatFile.Message(AbstractLLM.ChatMessage.system(preset?.systemMessage ?? "You are a friendly assistant"))
        let messages: [Sideproject.ChatFile.Message] = [systemMessage] + self.document.messages
        
        self.interactionState = .streaming
        self.activityPhaseOfLastItem = .sending
        
        var latestMessage: Sideproject.ChatFile.Message?
        
        let completion: AbstractLLM.ChatCompletionStream = try await self.llm.stream(
            messages.map({ $0.base }),
            model: self.document.model ?? OpenAI.Model.chat(.gpt_4).__conversion()
        )
        
        try await withTaskCancellationHandler { @MainActor in
            let publisher = completion.throttle(for: .milliseconds(50), scheduler: DispatchQueue.main, latest: true)
            
            try await publisher.sinkAsync { _ in
                if let message = completion.partialMessage {
                    latestMessage = Sideproject.ChatFile.Message(message)
                    
                    self.document.messages.updateOrAppend(Sideproject.ChatFile.Message(message))
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
        _ message: Sideproject.ChatFile.Message.ID
    ) {
        document.messages.removeAll(where: { message == $0.id })
    }
}

extension SideprojectChatPlayground {
    public enum InteractionState {
        case idle
        case streaming
    }
    
    public struct EphemeralOptions {
        public var rolesReversed: Bool = false
        public var contextFree: Bool = false
    }
}
