//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow

/// A strategy for extracting text from a document.
public protocol DocumentTextExtractionStrategy<Document>: Codable, HadeanIdentifiable, Hashable {
    associatedtype Document
    associatedtype ExtractedText: PlainTextDocumentProtocol
    
    func extract(
        from document: Document
    ) async throws -> ExtractedText
}

// MARK: - Implementation

extension DocumentTextExtractionStrategy {
    public var _opaque_ExtractedText: any PlainTextDocumentProtocol.Type {
        ExtractedText.self
    }
    
    public func _opaque_extract(
        from document: _AnyReferenceFileDocument
    ) async throws -> any PlainTextDocumentProtocol {
        let document = try await document.cast(to: Document.self)
        let extractedText = try await extract(from: document)
        
        return extractedText
    }
}

// MARK: - Extensions

extension DocumentTextExtractionStrategy {
    public func extract<D, S: AllCaseInitiable>(
        _ document: D
    ) async throws -> ExtractedText where Document == _ContentSelectionSpecified<D, S> {
        try await self.extract(from: _ContentSelectionSpecified(base: document))
    }
}
