//
// Copyright (c) Vatsal Manot
//

import BrowserKit
import Cataphyl
import CorePersistence
import LargeLanguageModels
import Merge
import OpenAI
import Swallow

@MainActor
public class LTDocumentStore: Logging, ObservableObject {
    private var cancellables: Set<AnyCancellable> = []
    
    public struct Configuration {
        /// Chunking refers to how the text from each document is chunked (usually by the process of text splitting).
        public enum ChunkingStrategy {
            case automatic
            case none
        }

        public let lite: Lite
        public let directoryURL: URL
        public var chunkingStrategy: ChunkingStrategy = .automatic
        
        public init(
            lite: Lite,
            directoryURL: URL
        ) {
            self.lite = lite
            self.directoryURL = directoryURL
        }
    }
    
    let configuration: Configuration
    
    let internalTasks = ThrowingTaskQueue()
    
    @FileStorage<MutableValueBox<IdentifierIndexingArrayOf<LTChatDocument>>, IdentifierIndexingArrayOf<LTChatDocument>>
    public var chats: IdentifierIndexingArrayOf<LTChatDocument>
    
    /// The documents ingested by our app.
    ///
    /// They're referred to as 'ingested' because in many cases these documents will be coming from richer data sources (web articles, PDFs etc.), and we are stripping them down to plain-text suitable for retrieval with text embeddings.
    ///
    /// In a real-world application, you will likely want to store both the source document and the ingested document.
    @FileStorage<MutableValueBox<IdentifierIndexingArrayOf<LTDocument>>, IdentifierIndexingArrayOf<LTDocument>>
    public var documents: IdentifierIndexingArrayOf<LTDocument>
    
    /// The **indexed** embeddings for the chunks of our ingested documents.
    ///
    /// The embeddings are indexed by a custom Swift type that we've created for our app's needs - `EmbeddingsIndexKey`.
    ///
    /// This index serves as our 'vector database' for the app. Real-world applications require careful thinking and assessment of storage techniques, and a naive `Array` backed vector index may not be ideal in many cases.
    @FileStorage<MutableValueBox<NaiveVectorIndex<LTDocumentFragmentIdentifier>>, NaiveVectorIndex<LTDocumentFragmentIdentifier>>
    public var textEmbeddings: NaiveVectorIndex<LTDocumentFragmentIdentifier>
    
    public init(
        configuration: Configuration
    ) {
        self.configuration = configuration
        
        _chats = FileStorage(
            url: configuration.directoryURL.appending("chat.json"),
            coder: HadeanTopLevelCoder(coder: JSONCoder()),
            options: .init(readErrorRecoveryStrategy: .discardAndReset)
        )
        
        _documents = FileStorage(
            url: configuration.directoryURL.appending("documents.json"),
            coder: JSONCoder(),
            options: .init(readErrorRecoveryStrategy: .discardAndReset)
        )
        
        _textEmbeddings = FileStorage(
            url: configuration.directoryURL.appending("embeddings.json"),
            coder: JSONCoder(),
            options: .init(readErrorRecoveryStrategy: .discardAndReset)
        )
        
        $documents
            .eraseToAnyPublisher()
            .sink { documents in
                self.documentsDidChange()
            }
            .store(in: &cancellables)
        
        self.documents.forEach({ $0.indexingInterval = nil })
    }
    
    public convenience init() {
        self.init(
            configuration: .init(
                lite: .shared,
                directoryURL: try! CanonicalFileDirectory.userDocuments.toURL()
            )
        )
    }
        
    private func documentsDidChange() {
        Task {
            try await self.embedAllDocuments()
        }
        ._expectNoThrow()
    }
}

extension LTDocumentStore {
    public subscript(
        _ key: LTChatDocument.ID
    ) -> LTChatDocument? {
        get {
            _expectNoThrow {
                try? chats[id: key].unwrap()
            }
        }
    }

    /// Our index keys contain two vital pieces of information:
    /// - The document identifier (i.e. just a UUID).
    /// - The span of the text (i.e. just a UTF16 range).
    ///
    /// This is a convenience subscript that allows us to retrieve the actual text for the range and document specified by the key.
    public subscript(
        _ id: LTDocumentFragmentIdentifier
    ) -> LTDocument.RetrievedFragment {
        get throws {
            guard let document: LTDocument = self.documents[id: id.document] else {
                throw LTDocumentStore.Error.invalidDocument(id.document)
            }
            
            return LTDocument.RetrievedFragment(
                id: id,
                document: document
            )
        }
    }
}

extension LTDocument {
    public struct RetrievedFragment: Identifiable {
        public typealias ID = LTDocumentFragmentIdentifier
        
        public let id: ID
        public let document: LTDocument
        
        @MainActor
        public var rawText: String {
            String {
                try document.rawText.unwrap().chunk(for: id.span).text
            } recovery: {
                "<error>"
            }
        }
    }
}

extension LTDocumentStore {
    public enum Error: _ErrorX {
        case invalidDocument(LTDocument.ID)
    }
}
