//
//  File.swift
//  Sideproject
//
//  Created by Purav Manot on 22/11/24.
//

import Foundation
import SwiftSoup

// TODO: - Come up with a better name
public enum OllamaSite {
    public static let baseURL = URL(string: "https://registry.ollama.ai")!
    public static let libraryURL = baseURL.appending(path: "library")
    
    public static var endpoints: [String] {
        get async throws {
            let html = try await String(url: OllamaSite.libraryURL)
            let libraryDocument = try SwiftSoup.parse(html, OllamaSite.baseURL.absoluteString)
            
            return try libraryDocument.select("#repo").array()[0].select("[href]").map { try $0.attr("href") }
        }
    }

}

public extension OllamaSite {
    struct ModelFamily {
        public let name: String
        public let models: [Model]
        
        public var url: URL? {
            URL(string: "https://registry.ollama.ai/library/\(name)")
        }
        
        public init(name: String) async throws {
            self.name = name
            
            let url = URL(string: "https://registry.ollama.ai/library/\(name)/tags")!
            let html = try await String(url: url)
            let document = try SwiftSoup.parse(html, OllamaSite.baseURL.absoluteString)
            
            self.models = try await withThrowingTaskGroup(of: OllamaSite.Model.self, returning: [OllamaSite.Model].self) { group in
                try document.select("section").first()!.select("a").array().forEach { element in
                    group.addTask {
                        let name = try element.attr("href")
                        return try await Model(name: name)
                    }
                }
                
                return try await group.collect()
            }
        }
    }
    
    struct Model {
        public let familyName: String
        public let variantName: String
        
        public let systemPrompt: String
        public let template: String
        public let license: String
        
        public var name: String { [familyName, variantName].joined(separator: ":") }
        
        public var url: URL? {
            URL(string: "https://registry.ollama.ai/library/\(name)")
        }
        
        public init(name: String) async throws {
            let components = name.components(separatedBy: ":")
            
            guard components.count == 2 else { throw Error.invalidModelName }
            
            self.familyName = components[0]
            self.variantName = components[1]
            
            let html = try await String(url: OllamaSite.baseURL.appending(path: name))
            let document = try SwiftSoup.parse(html)
            
            let properties = try document.select("#file-explorer").first()!.select("[href]").array()
            print(properties)
            guard properties.count == 4 else { throw Error.unexpectedNumberOfElements(url: OllamaSite.baseURL.appending(path: name)) }
            
            _ = try properties[0].attr("href")
            self.systemPrompt = try properties[1].attr("href")
            self.template = try properties[2].attr("href")
            self.license = try properties[3].attr("href")
            
            /*
             withThrowingTaskGroup(of: Void.self) { group in
             group.addTask {
             
             }
             }*/
        }
    }
}

// MARK: - Error handling

extension OllamaSite {
    public enum Error: Swift.Error {
        case invalidModelName
        case unexpectedNumberOfElements(url: URL)
    }
}
