//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import PDFKit

@HadeanIdentifier("kitip-dapib-musod-dopuk")
@RuntimeDiscoverable
public struct DefaultPDFTextExtractionStrategy {
    public init() {
        
    }
}

extension PDFFileDocument {
    @HadeanIdentifier("tanir-tozim-godal-tijit")
    public struct ExtractedText: Codable, Hashable, PlainTextDocumentProtocol, Sendable {
        public typealias Chunk = PlainTextDocument.SequentialSelection
        
        public let text: String
    }
}

extension DefaultPDFTextExtractionStrategy: DocumentTextExtractionStrategy {
    public typealias Document = PDFFileDocument
    public typealias Ingestion = PDFFileDocument.ExtractedText
    
    public func extract(
        from document: Document
    ) async throws -> Ingestion {
        do {
            return try await document.pdf.extractText()
        } catch {
            throw error
        }
    }
}

extension PDFDocument {
    fileprivate func extractText() async throws -> PDFFileDocument.ExtractedText {
        let pageCount = pageCount
        var text: String = ""
        
        try await (0..<pageCount)
            .concurrentMap { index -> (page: Int, content: String)? in
                guard let page: PDFPage = self.page(at: index) else {
                    return nil
                }
                
                let rawPageText: String = try page._extractText() ?? ""
                
                return (index, rawPageText)
            }
            .lazy
            .compactMap({ $0 })
            .forEach {
                if !text.isEmpty {
                    text.append("\n")
                }
                
                text.append($0.content)
            }
        
        return .init(text: text)
    }
}

extension PDFPage {
    func _extractText() throws -> String? {
        guard let string = attributedString else {
            return nil
        }
        
        let text = NSAttributedString._MarkdownExporter().export(string)
        
        return text
    }
}
