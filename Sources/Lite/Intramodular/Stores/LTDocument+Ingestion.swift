//
// Copyright (c) Vatsal Manot
//

import BrowserKit
import Cataphyl
import CorePersistence
import PDFKit
import Swallow

@MainActor
extension LTDocument {
    public func ingest() async throws {
        guard rawText == nil else {
            return
        }
        
        if indexingInterval == .indexing {
            return
        }
        
        self.indexingInterval = .indexing
        
        if let url = url?.url {
            try await _ingestURL(url)
        } else {
            throw _PlaceholderError()
        }
        
        await MainActor.run {
            self.indexingInterval = nil
            
            dataStore.$documents.commit()
        }
    }
    
    private func _ingestURL(_ url: URL) async throws {
        if url.isWebURL {
            try await _ingestByScrapingWebContent(from: url)
        } else if url.isFileURL {
            if url.pathExtension == "pdf" {
                try await _ingestPDF(from: url)
            } else {
                assertionFailure()
            }
        }
    }
    
    private func _ingestPDF(
        from url: URL
    ) async throws {
        let document = PDFFileDocument(pdf: try PDFDocument(url: url).unwrap())
        let extractionStrategy = DefaultPDFTextExtractionStrategy()
        
        let ingested = try await extractionStrategy.extract(from: document)
        
        self.rawText = .init(text: ingested.text)
    }
    
    private func _ingestByScrapingWebContent(
        from url: URL
    ) async throws {
        let cleaned = try await Readability(engine: .readability).extract(from: url)
        let markdown = try await _TurndownJS().convert(htmlString: cleaned.content.htmlString)
        
        self.rawText = PlainTextDocument(text: markdown)
    }
}
