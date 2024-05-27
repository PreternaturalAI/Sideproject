//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import FoundationX
import Swallow

/// Extra protocol needed so that `Chunk` has a default type of `PlainTextDocument.SequentialSelection`.
public protocol _PlainTextDocumentProtocol {
    typealias Chunk = PlainTextDocument.SequentialSelection
}

public protocol PlainTextDocumentProtocol: _PlainTextDocumentProtocol, _ContiguousChunkableDocument, CustomTextConvertible where Chunk.Span == PlainTextDocument.SequentialSelection.Span, Chunk.ID == PlainTextDocument.SequentialSelection.ID, Chunk: CustomTextConvertible {
    var text: String { get throws }
    
    subscript(
        span: PlainTextDocument.SequentialSelection.Span
    ) -> PlainTextDocument.SequentialSelection { get throws }
    
    func chunk(
        for span: PlainTextDocument.SequentialSelection.Span
    ) throws -> PlainTextDocument.SequentialSelection
}

// MARK: - Implementation

extension PlainTextDocumentProtocol where Chunk == PlainTextDocument.SequentialSelection {
    public subscript(
        span: Chunk.Span
    ) -> Chunk {
        get throws {
            guard let first = span.rawValue.first, let last = span.rawValue.last else {
                throw _PlaceholderError()
            }
            
            return Chunk(span: span, effectiveText: String(try text[from: first, to: last]))
        }
    }
    
    public func chunk(
        for span: PlainTextDocument.SequentialSelection.Span
    ) throws -> PlainTextDocument.SequentialSelection {
        try self[span]
    }
}

// MARK: - Conformances

extension PlainTextDocumentProtocol where Self: CustomStringConvertible {
    public var description: String {
        (try? text) ?? "<error>"
    }
}

// MARK: - Auxiliary

extension String {
    subscript(
        from first: PlainTextDocument.TextRange,
        to second: PlainTextDocument.TextRange
    ) -> Substring {
        get throws {
            switch (first, second) {
                case (.utf16(let first), .utf16(let second)):
                    return self[_utf16Range: first.lowerBound..<second.upperBound]
            }
        }
    }
}
