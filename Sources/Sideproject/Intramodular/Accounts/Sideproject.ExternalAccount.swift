//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Merge
import Swallow
import SwiftUIZ

extension Sideproject {
    public struct ExternalAccount: Codable, Hashable, InterfaceModel {
        public typealias ID = _TypeAssociatedID<Self, UUID>
        
        @LogicalParent var store: Sideproject.ExternalAccountStore
        
        public let id: ID
        public let accountType: Sideproject.ExternalAccountTypeIdentifier
        @_UnsafelySerialized
        public var credential: (any Sideproject.ExternalAccountCredential)?
        public var accountDescription: String?
        
        @MainActor
        public var accountTypeDescription: Sideproject.ExternalAccountTypeDescription {
            store[accountType]
        }
        
        @MainActor
        public var displayName: String {
            if let accountDescription {
                guard !accountDescription.isEmpty, accountDescription != "Untitled" else {
                    return accountTypeDescription.title
                }
                
                return accountDescription
            }
            
            return accountTypeDescription.title
        }
        
        public init(
            id: ID = .init(),
            accountType: Sideproject.ExternalAccountTypeIdentifier,
            credential: (any Sideproject.ExternalAccountCredential)?,
            description: String?
        ) {
            self.id = id
            self.accountType = accountType
            self.credential = credential
            self.accountDescription = description
        }
    }
}

extension Sideproject {
    public struct ExternalAccountTypeIdentifier: Codable, ExpressibleByStringLiteral, Hashable, Sendable {
        public var rawValue: String
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(from decoder: Decoder) throws {
            var rawValue = try String(from: decoder)
            
            if rawValue == "ai.preternatural.OpenAI" {
                rawValue = "com.vmanot.openai"
            }
            
            self.init(rawValue: rawValue)
        }
        
        public func encode(to encoder: Encoder) throws {
            try rawValue.encode(to: encoder)
        }
        
        public init(stringLiteral value: StringLiteralType) {
            self.init(rawValue: .init(stringLiteral: value))
        }
    }
}

// MARK: - Conformances

extension Sideproject.ExternalAccount: PersistentIdentifierConvertible {
    public var persistentID: ID {
        id
    }
}
