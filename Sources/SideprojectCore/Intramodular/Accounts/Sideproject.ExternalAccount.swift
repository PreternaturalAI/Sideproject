//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import FoundationX
import Merge
import Swallow
import SwiftUIZ

extension Sideproject {
    public struct ExternalAccount: Codable, Hashable, InterfaceModel {
        public static let defaultAccountDescription: String = "Untitled"
        
        public typealias ID = _TypeAssociatedID<Self, UUID>
        
        @LogicalParent var store: Sideproject.ExternalAccountStore
        
        public var id: ID
        public let accountType: Sideproject.ExternalAccountTypeIdentifier
        @_UnsafelySerialized
        public var credential: (any Sideproject.ExternalAccountCredential)?
        public var accountDescription: String?
        
        @MainActor
        public var accountTypeDescriptor: any Sideproject.ExternalAccountTypeDescriptor {
            store[accountType]
        }
        
        @MainActor
        public var displayName: String {
            get {
                if let accountDescription {
                    guard !accountDescription.isEmpty, accountDescription != Self.defaultAccountDescription else {
                        return accountTypeDescriptor.title
                    }
                    
                    return accountDescription
                }
                
                return accountTypeDescriptor.title
            } set {
                guard newValue != Self.defaultAccountDescription else {
                    return
                }
                
                accountDescription = newValue.nilIfEmpty()
            }
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

extension Sideproject.ExternalAccount: CustomStringConvertible {
    public var description: String {
        MainActor.assumeIsolated {
            "\(displayName) (External Account)"
        }
    }
}

extension Sideproject.ExternalAccount: PersistentIdentifierConvertible {
    public var persistentID: ID {
        id
    }
}
