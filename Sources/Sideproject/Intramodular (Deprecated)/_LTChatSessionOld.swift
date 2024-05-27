/*//
// Copyright (c) Vatsal Manot
//

import Cataphyl
import LargeLanguageModels
import Merge
import Swallow
import SwiftUI

@MainActor
public final class _LTChatSessionOld: Logging,  ObservableObject {
    @Dependency(\.llmServices) var llmServices: LLMRequestHandling
    @Dependency(\.textEmbeddingsProvider) var textEmbeddingsProvider
    
    @PublishedAsyncBinding public var document: Sideproject.ChatFile
    
    public let store: Sideproject.FileStore
    
    public init(store: Sideproject.FileStore, document: PublishedAsyncBinding<Sideproject.ChatFile>) {
        self.store = store
        self._document = document
    }
    
    @TaskStreamed(failureType: Error.self)
    public var lastResponse: String? = nil
    
    /// Ingest all documents specified in the chat's scope.
    func _ingestScope() async throws {
        /*try await document.scope.documents.compactMap({ store[$0] }).concurrentForEach {
            try await $0.ingest()
        }*/
    }
    
    public func send(
        _ messageBody: String,
        id: Sideproject.ChatFile.Message.ID? = nil
    ) {
        let message = Sideproject.ChatFile.Message(.user(messageBody))
        
        _prepareToSend(message)
        
        $lastResponse.stream { @MainActor in
            try await _ingestScope()
            
            var response = try await _sendNewMessage(message)
            
            response = response
                .replacingOccurrences(of: "<article>", with: "")
                .replacingOccurrences(of: "</article>", with: "")
                .trimmingWhitespace()
            
            document.messages.append(.init(.assistant(response)))
            
            return response
        }
    }
    
    private func _prepareToSend(
        _ message: Sideproject.ChatFile.Message
    ) {
        withAnimation {
            document.messages.removeFrom(predicate: { $0.id == message.id })
            document.messages.append(message)
        }
    }
    
    func _sendNewMessage(
        _ message: Sideproject.ChatFile.Message
    ) async throws -> String {
        let messageBody = try message.content._stripToText()
        
        let prompt = try await self.createPrompt(
            for: message,
            query: messageBody
        )
        let completion =  try await self.llmServices.complete(
            prompt: prompt,
            parameters: nil
        )
        
        let response: String = try completion._stripToText()
        
        return response
    }
    
    @MainActor
    public func delete(_ id: Sideproject.ChatFile.Message.ID) {
        guard let message = self.document.messages[id: id] else {
            assertionFailure()
            
            return
        }
        
        withAnimation {
            self.document.messages.removeFrom(predicate: { $0.id == message.id })
        }
    }
    
    @MainActor
    public func resend(_ id: Sideproject.ChatFile.Message.ID) {
        guard let message = self.document.messages[id: id] else {
            assertionFailure()
            
            return
        }
        
        guard message.role != .assistant else {
            return
        }
        
        return send(try! message.content._stripToText(), id: id)
    }
    
    /// Creates a prompt to pass to the LLM.
    ///
    /// - Parameters:
    ///   - query: The user's query.
    ///   - topMatch: The matched portion of a relevant document to send to the LLM.
    func createPrompt(
        for message: Sideproject.ChatFile.Message,
        query: String
    ) async throws -> AbstractLLM.ChatPrompt {
        if let documentID = try? self.document.scope.documents.toCollectionOfOne().value, let document = store.documents[id: documentID], let text = document.rawText {
            var prompt = AbstractLLM.ChatPrompt(
                messages: [
                    .system(
                    """
                    You are a highly intelligent assistant designed to interact and answer questions from a article on behalf of the user.
                    
                    You will be given the entire article as raw text. The article will be delimited by XML tags in the format of <article>...</article>.
                    
                    The user's query will be delimited in XML also, as <user-query>...</user-query>.
                    """
                    ),
                    .user(
                    """
                    <article>
                    \(text)
                    \(String.quotationMark)
                    </article>
                    """
                    ),
                    .assistant("What is your query?"),
                ]
            )
            
            for message in self.document.messages.removingAll(where: { $0.id == message.id }) {
                switch message.role {
                    case .assistant:
                        prompt.append(.assistant(message.content))
                    case .user:
                        prompt.append((.user(message.content)))
                    default:
                        assertionFailure()
                }
            }
            
            prompt.append(
                .user(
                    """
                    <user-query>
                    "\(query)"
                    </user-query>
                    """
                )
            )
            
            return prompt
        } else {
            let topMatch = try await self.relevantMatches(for: query).first.unwrap()
            
            let prompt = AbstractLLM.ChatPrompt(
                messages: [
                    .system(
                    """
                    You are a helpful bot designed to answer questions from a knowledge base. You will be given paragraphs of reference text along with a user query, and your job is to answer the user's query using information from the reference text. If the reference text does not contain the answer, reply saying that an answer could not be found.
                    """
                    ),
                    .user(
                    """
                    User query: \(String.quotationMark)\(query)\(String.quotationMark)"
                    
                    Reference text:
                    \(String.quotationMark)
                    \(topMatch)
                    \(String.quotationMark)
                    """
                    ),
                ]
            )
            
            return prompt
        }
    }
    
   @MainActor
    private func relevantMatches(
        for query: String
    ) async throws -> [String] {
        let embedding = try await withTaskTimeout(.seconds(2)) {
            logger.info("Beginning embedding query.")
            
            defer {
                logger.info("Finished embedding query.")
            }
            
            return try await $textEmbeddingsProvider.get().textEmbedding(for: query)
        }
        
        if store.textEmbeddings.isEmpty {
            try await store.embedAllDocuments()
        }
        
        let items: [Sideproject.FileFragmentIdentifier] = try store.textEmbeddings
            .query(
                .topMatches(for: embedding.rawValue, maximumNumberOfResults: 5)
            )
            .map({ $0.item })
        
        let longest = items
            .longestConsecutiveSequences(by: \.span, relativeTo: store.textEmbeddings.keys)
            .first ?? []
        
        let consecutives = try longest.compactMap({ try store[$0].rawText })
        
        if consecutives.count > 1 {
            return [consecutives.joined()]
        } else {
            return try items.compactMap({ try store[$0].rawText })
        }
    }
}
*/
