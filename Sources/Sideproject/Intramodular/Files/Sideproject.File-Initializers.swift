//
// Copyright (c) Vatsal Manot
//

import Cataphyl
import CorePersistence
import SwiftUIX

extension Sideproject.File {
    @MainActor
    public convenience init(url: WebLocationDocument) {
        self.init()
        
        self.url = url.url
        self.metadata.displayName = url.url.absoluteString
    }
    
    @MainActor
    public convenience init(rawText: PlainTextDocument) {
        self.init()
        
        self.rawText = rawText
    }
    
    @MainActor
    public convenience init(rawText: String) {
        self.init(rawText: PlainTextDocument(text: rawText))
    }
    
    @MainActor
    public convenience init(id: some PersistentIdentifier, rawText: String) {
        self.init(rawText: PlainTextDocument(text: rawText))
        
        self.metadata.persistentID = .init(erasing: id)
    }
    
    @MainActor
    public convenience init(url: URL) throws {
        self.init()
        
        if url.isFileURL {
            let newURL = try URL(
                directory: .userDocuments,
                subdirectory: "files",
                filename: UUID().uuidString
            ).appendingPathExtension(url._fileExtension)
            
            try FileManager.default.createDirectoryIfNecessary(at: newURL.deletingLastPathComponent())
            
            try FileManager.default.copyItem(at: url, to: newURL)
            
            self.url = newURL
            self.metadata.displayName = url._fileNameWithoutExtension
        } else if url.isWebURL {
            self.init(url: WebLocationDocument(url: url))
        } else {
            assertionFailure()
        }
    }
}
