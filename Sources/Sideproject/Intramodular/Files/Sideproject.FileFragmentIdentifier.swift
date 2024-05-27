//
// Copyright (c) Vatsal Manot
//

import Foundation

extension Sideproject {
    /// A unique key for each record in the embeddings index.
    ///
    /// The key contains two essential pieces of information:
    /// - The document identifier.
    /// - The span of the portion of the document text that has been indexed.
    public struct FileFragmentIdentifier: Codable, Hashable, Sendable {
        public let document: Sideproject.File.ID // just a plain UUID
        
        /// The UTF-8 range of the text.
        ///
        /// So that when we get the retrieved items from the vector index, we can also see what portion of the text was returned from the document.
        public let span: PlainTextDocument.SequentialSelection.Span // Range<String.Index>
    }
}

extension Sideproject.FileFragmentIdentifier: CustomStringConvertible {
    public var description: String {
        "{document:\"\(document.id.truncatedDescription)\", span:\(span)}"
    }
}
