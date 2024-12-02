//
//  File.swift
//  Sideproject
//
//  Created by Purav Manot on 29/11/24.
//

import Foundation

extension ModelStore.Model {
    enum AssetURL: Codable, Hashable, Sendable {
        case huggingFace(URL)
        case ollama(URL)
        
        public init?(_ url: URL) {           
            switch url.host() {
                case "huggingface.co":
                    self = .huggingFace(url)
                case "ollama.com", "registry.ollama.ai", "ollama.ai":
                    self = .ollama(url)
                default:
                    return nil
            }
        }
    }
}
