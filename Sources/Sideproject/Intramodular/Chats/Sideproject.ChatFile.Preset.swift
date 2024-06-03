//
// Copyright (c) Vatsal Manot
//

import Swift

extension Sideproject.ChatFile {
    public protocol Preset: Codable, HadeanIdentifiable, Hashable, Identifiable, Sendable where ID == _HashableExistential<any Hashable> {
        var id: _HashableExistential<any Hashable> { get }
    }
}

extension Sideproject.ChatFile {
    public enum Presets: _StaticSwift.TypeIterableNamespace {
        public static var _allNamespaceTypes: [Any.Type] {
            SystemMessage.self
        }
        
        @HadeanIdentifier("fimon-duhot-fipag-bodim")
        @RuntimeDiscoverable
        public struct SystemMessage: Sideproject.ChatFile.Preset {
            public var systemMessage: String
            
            public var id: _HashableExistential<any Hashable> {
                .init(wrappedValue: systemMessage.lowercased())
            }
            
            public init(systemMessage: String) {
                self.systemMessage = systemMessage
            }
            
            public init() {
                self.init(systemMessage: "You are a friendly assistant")
            }
        }
    }
}
