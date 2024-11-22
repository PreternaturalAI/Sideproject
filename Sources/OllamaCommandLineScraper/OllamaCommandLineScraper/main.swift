//
//  main.swift
//  OllamaCommandLineScraper
//
//  Created by Purav Manot on 21/11/24.
//

import Foundation
import SwiftSoup
import Sideproject
import BrowserKit



let names = try await OllamaSite.endpoints.map { String($0.split(separator: "/").last!) }
let tagURLs = names.map { URL(string: "https://registry.ollama.ai/library/\($0)/tags") }
print(names)

do {
    try await withThrowingTaskGroup(of: Void.self) { group in
        for name in names.prefix(4) {
            group.addTask {
                let family = try await OllamaSite.ModelFamily(name: name)
                print(family.models)
            }
        }
        
        try await group.waitForAll()
    }
} catch {
    print(error)
}
