//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

/// A document that can be broken down into contiguous chunks.
public protocol _ContiguousChunkableDocument {
    associatedtype Chunk: _ContiguousDocumentChunk
    
    subscript(_ span: Chunk.ID) -> Chunk { get throws } // FIXME: Remove
    subscript(_ span: Chunk.Span) -> Chunk { get throws }
}

public protocol _ContiguousDocumentChunk: Identifiable, Sendable where ID: Sendable {
    associatedtype Span: Codable, Hashable, Sendable
    
    var span: Span { get }
}
