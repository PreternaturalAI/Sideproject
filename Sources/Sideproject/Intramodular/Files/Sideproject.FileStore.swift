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

extension Sideproject {
    public class FileStore: Logging, ObservableObject {
        @MainActor
        final class _State {
            var documentsToEmbed: Set<Sideproject.File.ID> = []
        }
        
        @MainActor
        let state = _State()
        
        private var cancellables: Set<AnyCancellable> = []
        
        let configuration: Configuration
        
        let internalTasks = ThrowingTaskQueue()
        
        @MainActor
        @FileStorage<MutableValueBox<IdentifierIndexingArrayOf<Sideproject.ChatFile>>, IdentifierIndexingArrayOf<Sideproject.ChatFile>>
        public var chats: IdentifierIndexingArrayOf<Sideproject.ChatFile>
        
        /// The documents ingested by our app.
        ///
        /// They're referred to as 'ingested' because in many cases these documents will be coming from richer data sources (web articles, PDFs etc.), and we are stripping them down to plain-text suitable for retrieval with text embeddings.
        ///
        /// In a real-world application, you will likely want to store both the source document and the ingested document.
        @MainActor
        @FileStorage<MutableValueBox<IdentifierIndexingArrayOf<Sideproject.File>>, IdentifierIndexingArrayOf<Sideproject.File>>
        public var documents: IdentifierIndexingArrayOf<Sideproject.File>
        
        @MemoizedProperty(\Self.$documents, value: { `self` in
            self.documents
                .filter({ $0.metadata.persistentID != nil })
                ._compactMapToDictionary(key: { $0.metadata.persistentID! }, value: { $0.id })
        })
        @MainActor
        var documentsByPersistentIdentifier: [AnyPersistentIdentifier: Sideproject.File.ID]
        
        /// The **indexed** embeddings for the chunks of our ingested documents.
        ///
        /// The embeddings are indexed by a custom Swift type that we've created for our app's needs - `EmbeddingsIndexKey`.
        ///
        /// This index serves as our 'vector database' for the app. Real-world applications require careful thinking and assessment of storage techniques, and a naive `Array` backed vector index may not be ideal in many cases.
        @MainActor
        @FileStorage<MutableValueBox<NaiveVectorIndex<Sideproject.FileFragmentIdentifier>>, NaiveVectorIndex<Sideproject.FileFragmentIdentifier>>
        public var textEmbeddings: NaiveVectorIndex<Sideproject.FileFragmentIdentifier>
        
        @MainActor
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
            
            internalTasks.addTask {
                await self.documents.forEach({ $0.indexingInterval = nil })
            }
        }
        
        @MainActor
        public convenience init() {
            self.init(
                configuration: .init(
                    lite: .shared,
                    directoryURL: try! CanonicalFileDirectory.userDocuments.toURL()
                )
            )
        }
        
        @MainActor
        private func documentsDidChange() {
            Task {
                try await self.embedPendingDocuments()
            }
            ._expectNoThrow()
        }
    }
}

extension Sideproject.FileStore {
    @MainActor
    public subscript(
        _ key: Sideproject.ChatFile.ID
    ) -> Sideproject.ChatFile? {
        get {
            #try(.optimistic) {
                try chats[id: key].unwrap()
            }
        }
    }
    
    /// Our index keys contain two vital pieces of information:
    /// - The document identifier (i.e. just a UUID).
    /// - The span of the text (i.e. just a UTF16 range).
    ///
    /// This is a convenience subscript that allows us to retrieve the actual text for the range and document specified by the key.
    @MainActor
    public subscript(
        _ id: Sideproject.FileFragmentIdentifier
    ) -> Sideproject.File.RetrievedFragment {
        get throws {
            guard let document: Sideproject.File = self.documents[id: id.document] else {
                throw Sideproject.FileStore.Error.invalidDocument(id.document)
            }
            
            return Sideproject.File.RetrievedFragment(
                id: id,
                document: document
            )
        }
    }
}

extension Sideproject.File {
    public struct RetrievedFragment: Identifiable {
        public typealias ID = Sideproject.FileFragmentIdentifier
        
        public let id: ID
        public let document: Sideproject.File
        
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

extension Sideproject.FileStore {
    public enum Error: _ErrorX {
        case invalidDocument(Sideproject.File.ID)
    }
}

extension Sideproject.FileStore {
    public struct Configuration {
        /// Chunking refers to how the text from each document is chunked (usually by the process of text splitting).
        public enum ChunkingStrategy {
            case automatic
            case none
        }
        
        public let lite: Sideproject
        public let directoryURL: URL
        public var chunkingStrategy: ChunkingStrategy = .automatic
        
        public init(
            lite: Sideproject,
            directoryURL: URL
        ) {
            self.lite = lite
            self.directoryURL = directoryURL
        }
    }
}
