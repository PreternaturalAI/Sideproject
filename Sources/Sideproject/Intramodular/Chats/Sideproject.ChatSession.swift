//
// Copyright (c) Vatsal Manot
//

import ChatKit
import CoreMI
import Diagnostics
import LargeLanguageModels
import Merge
import OpenAI

extension Sideproject {
    public typealias ChatSession = SideprojectChatSession
}

@ManagedActor
@MainActor
public final class SideprojectChatSession: Logging, ObservableObject {
    private let cancellables = Cancellables()
    private let taskQueue = TaskQueue()
    
    private let llm: LLMRequestHandling
    
    @PublishedAsyncBinding
    public var document: Sideproject.ChatFile
    
    @Published public var interactionState: InteractionState = .idle
    @Published public var ephemeralOptions = EphemeralOptions()
    @Published public var activityPhaseOfLastItem: ChatItemActivityPhase = .idle
    
    public init(
        document: @autoclosure @escaping () throws -> PublishedAsyncBinding<Sideproject.ChatFile>,
        llm: LLMRequestHandling = Sideproject.shared
    ) {
        self._document = #try(.optimistic) {
            try document()
        } ?? PublishedAsyncBinding(wrappedValue: Sideproject.ChatFile())
        
        self.llm = llm
    }
    
    /// Send a message.
    public func sendMessage(
        _ message: Sideproject.ChatFile.Message
    ) {
        sendMessage(message.__conversion())
    }
    
    /// Send a message.
    public func sendMessage(
        _ message: AbstractLLM.ChatMessage
    ) {
        taskQueue.addTask(priority: .userInitiated) { @MainActor in
            do {
                assert(interactionState != .streaming)
                
                var wantsStream: Bool
                
                let (didMessageExist, _) = try _upsert(message: message)
                
                if didMessageExist {
                    wantsStream = false // we're updating an existing message, so it's not a message being received from the server
                } else {
                    wantsStream = true
                }
                
                guard wantsStream else {
                    return
                }
                
                await _streamChatCompletion()
            } catch {
                activityPhaseOfLastItem = .failed(error)
            }
        }
    }
    
    public func sendMessage(_ body: String) {
        sendMessage(
            AbstractLLM.ChatMessage(
                id: UUID(),
                role: .user,
                content: body
            )
        )
    }
    
    /// Interrupt any sending/streaming of a message.
    ///
    /// If a response was being streamed, it'll be canceled and deleted.
    public func interrupt() {
        taskQueue.cancelAll()
    }
    
    /// Delete a given message from the chat file.
    public func delete(
        _ message: Sideproject.ChatFile.Message.ID
    ) {
        document.messages.remove(elementIdentifiedBy: message)
    }
    
    /// Delete a given message from the chat file.
    public func delete(
        _ message: AbstractLLM.ChatMessage.ID
    ) {
        #try(.optimistic) {
            try document.messages.removeAll(where: {
                try message?.as(Sideproject.ChatFile.Message.ID.self) == $0.id
            })
        }
    }
    
    /// Updates or appends a given chat message.
    ///
    /// If the message already exists, returns `inserted` as `false`.
    private func _upsert(
        message: AbstractLLM.ChatMessage
    ) throws -> (inserted: Bool, message: AbstractLLM.ChatMessage?) {
        if let existingMessageIndex = self.document.messages.index(
            ofElementIdentifiedBy: try message.id.unwrap().as(Sideproject.ChatFile.Message.ID.self)
        ) {
            if self.document.messages[existingMessageIndex].content != message.content {
                self.document.messages[existingMessageIndex] = Sideproject.ChatFile.Message(message)
                
                if existingMessageIndex == self.document.messages.lastIndex {
                    return (true, message)
                }
            }
        } else {
            self.document.messages.append(Sideproject.ChatFile.Message(message))
        }
        
        return (false, message)
    }
    
    /// Use the latest message history to construct a chat prompt, send it to the LLM and stream a response.
    @MainActor
    private func _streamChatCompletion() async {
        self.interactionState = .streaming
        self.activityPhaseOfLastItem = .sending
        
        let messages: [AbstractLLM.ChatMessage] = _latestMessageHistory()
        
        /// The message about to be streamed.
        var streamedMessage: AbstractLLM.ChatMessage?
        
        do {
            let model: ModelIdentifierConvertible = try (self.document.model ?? llm._availableModels?.first).unwrap()
            let completion: AbstractLLM.ChatCompletionStream = try await self.llm.stream(
                messages,
                model: model
            )
            
            try await withTaskCancellationHandler { @MainActor in
                let publisher = completion.throttle(for: .milliseconds(50), scheduler: DispatchQueue.main, latest: true)
                
                try await publisher.sinkAsync { _ in
                    if let message: AbstractLLM.ChatMessage = completion.partialMessage {
                        streamedMessage = message
                        
                        self.document.messages.updateOrAppend(Sideproject.ChatFile.Message(message))
                    }
                }
                
                self.interactionState = .idle
                self.activityPhaseOfLastItem = .idle
            } onCancel: {
                Task(priority: .userInitiated) { @MainActor in
                    _cancelStreaming(of: streamedMessage)
                }
            }
            
            self.interactionState = .idle
            self.activityPhaseOfLastItem = .idle
        } catch {
            self.interactionState = .idle
            self.activityPhaseOfLastItem = .failed(AnyError(erasing: error))
        }
    }
    
    /// Interrupts and cancels the current attempt at streaming a message.
    ///
    /// If a message is provided it will also be deleted from the chat history.
    @MainActor
    private func _cancelStreaming(
        of message: AbstractLLM.ChatMessage?
    ) {
        if let message {
            delete(message.id)
        }
        
        self.interactionState = .idle
        self.activityPhaseOfLastItem = .idle
    }
    
    /// Returns an array of the latest set of chat messages.
    private func _latestMessageHistory() -> [AbstractLLM.ChatMessage] {
        let preset = self.document.preset.map({ $0 as! Sideproject.ChatFile.Presets.SystemMessage })
        
        let systemMessage = AbstractLLM.ChatMessage.system(preset?.systemMessage ?? "You are a friendly assistant")
        let chatMessages: [AbstractLLM.ChatMessage] = self.document.messages.map({ $0.__conversion() })
        let messages = [systemMessage] + chatMessages
        
        return messages
    }
}

extension Sideproject.ChatSession {
    public enum InteractionState {
        case idle
        case streaming
    }
    
    public struct EphemeralOptions {
        public var rolesReversed: Bool = false
        public var contextFree: Bool = false
    }
}
