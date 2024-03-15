//
// Copyright (c) Vatsal Manot
//

import Cataphyl

extension LTDocument {
    func embed() async throws {
        let lite: Lite = dataStore.configuration.lite
        
        try await ingest()

        /// The raw text of the document.
        let rawText: PlainTextDocument = try await rawText.unwrap()
        /// The text splitter to use.
        let textSplitter: any TextSplitter = try await textSplitter()
        
        let splits: [PlainTextSplit] = try textSplitter.split(rawText)
        
        let embeddings: TextEmbeddings = try await lite.textEmbeddings(
            for: splits.map(\.text)
        )
        
        let indexedTextEmbeddings: [(LTDocumentFragmentIdentifier, _RawTextEmbedding)]
        
        indexedTextEmbeddings = embeddings.enumerated().map { (index, element) in
            let span = PlainTextDocument.SequentialSelection.Span(rawValue: splits[index].ranges)
            let key = LTDocumentFragmentIdentifier(document: self.id, span: span)
            let embedding: _RawTextEmbedding = element.embedding
            
            return (key, embedding)
        }
        
        try await MainActor.run {
            try dataStore.textEmbeddings.insert(contentsOf: indexedTextEmbeddings)
        }
    }
    
    private func textSplitter() async throws -> any TextSplitter {
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
