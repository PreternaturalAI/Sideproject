//
// Copyright (c) Vatsal Manot
//

import Swift

extension Sideproject.ChatFile {
    public typealias PresetID = _TypeAssociatedID<any Sideproject.ChatFile.Preset, UUID>
    
    /// A preset contains some preconfigured chat history (including a system message).
    ///
    /// Presets are meant to be saved and loaded by users, think of them as prompt templates.
    public protocol Preset: Codable, HadeanIdentifiable, Hashable, Identifiable, Sendable where ID == PresetID {
        var id: PresetID { get }
    }
}

extension Sideproject.ChatFile {
    public enum Presets: _StaticSwift.TypeIterableNamespace {
        public static var _allNamespaceTypes: [Any.Type] {
            SystemMessage.self
        }
        
        /// A preset that just represents a single system-message.
        @HadeanIdentifier("fimon-duhot-fipag-bodim")
        @RuntimeDiscoverable
        public struct SystemMessage: Sideproject.ChatFile.Preset {
            public var id = PresetID()
            public var systemMessage: String
            
            public init(systemMessage: String) {
                self.systemMessage = systemMessage
            }
            
            public init() {
                self.init(systemMessage: "You are a friendly assistant")
            }
        }
    }
}
