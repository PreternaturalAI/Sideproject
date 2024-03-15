//
// Copyright (c) Vatsal Manot
//

import Swift

extension LTChatDocument {
    public protocol Preset: Codable, HadeanIdentifiable, Hashable, Identifiable, Sendable where ID == _HashableExistential<any Hashable> {
        var id: _HashableExistential<any Hashable> { get }
    }
}

extension LTChatDocument {
    public enum Presets: _TypeIterableStaticNamespaceType {
        public static var _allNamespaceTypes: [Any.Type] {
            SystemMessage.self
        }
        
        @HadeanIdentifier("fimon-duhot-fipag-bodim")
        @RuntimeDiscoverable
        public struct SystemMessage: LTChatDocument.Preset {
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
