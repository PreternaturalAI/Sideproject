//
// Copyright (c) Vatsal Manot
//

import Cataphyl
import SideprojectCore
import Cataphyl

extension Sideproject.File {
    /// Generate and save text-embeddings for this document.
    public func embed() async throws {
        try await _embed()
    }
}

extension Sideproject.File {
    func _embed() async throws {
        Task { @MainActor in
            logger.info("Embedding document: \(displayIdentifier)")
        }

        do {
            let lite: Sideproject = dataStore.configuration.lite
            let splits: [PlainTextSplit] = try await _textSplitsForEmbedding()
            let embeddings: TextEmbeddings = try await lite.textEmbeddings(
                for: splits.map(\.text)
            )
            
            let indexedTextEmbeddings: [(Sideproject.FileFragmentIdentifier, _RawTextEmbedding)]
            
            indexedTextEmbeddings = embeddings.enumerated().map { (index, element: TextEmbeddings.Element) in
                let span = PlainTextDocument.SequentialSelection.Span(rawValue: splits[index].ranges)
                let key = Sideproject.FileFragmentIdentifier(document: self.id, span: span)
                let embedding: _RawTextEmbedding = element.embedding
                
                return (key, embedding)
            }
            
            try await MainActor.run {
                try dataStore.textEmbeddings.insert(contentsOf: indexedTextEmbeddings)
                
                assert(!dataStore.textEmbeddings.isEmpty)
            }
        } catch {
            Task { @MainActor in
                logger.info("An error occurred while embedding \(displayIdentifier): \(error)")
            }
            
            throw error
        }
        
        Task { @MainActor in
            logger.info("Successfully embedded document: \(displayIdentifier)")
        }
    }
    
    func _embedWholeDocumentAsSingleEmbedding()async throws  -> _WholeDocumentAsSingleEmbedding {
        let lite: Sideproject = dataStore.configuration.lite
        let rawText: PlainTextDocument = try await rawText.unwrap()
        let embedding: SingleTextEmbedding = try await lite.singleTextEmbedding(for: rawText.text)
        
        return .init(embedding: embedding)
    }
    
    private func _textSplitsForEmbedding() async throws -> [PlainTextSplit] {
        try await _ingest()

        /// The raw text of the document.
        let rawText: PlainTextDocument = try await rawText.unwrap()
        /// The text splitter to use.
        let textSplitter: any TextSplitter = try await _textSplitter()
        
        let splits: [PlainTextSplit] = try textSplitter.split(rawText)
        
        return splits
    }
    
    private func _textSplitter() async throws -> any TextSplitter {
        switch dataStore.configuration.chunkingStrategy {
            case .automatic:
                let textSplitter = try RecursiveCharacterTextSplitter(
                    configuration: .init(
                        maximumSplitSize: MSFT_KnowledgeMiningWithOpenAI.LARGE_EMB_TOKEN_NUM,
                        maximumSplitOverlap: nil
                    )
                )
                
                return textSplitter
            case .none:
                return _NoTextSplittingTextSplitter()
        }
    }
}

// MARK: - Auxiliary

extension Sideproject.File {
    public struct _WholeDocumentAsSingleEmbedding {
        public let embedding: TextEmbeddings.Element
        
        public init(embedding: TextEmbeddings.Element) {
            self.embedding = embedding
        }
    }
}
