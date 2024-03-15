//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Merge
import Swallow
import SwiftUIZ

public struct LTAccount: Codable, Hashable, InterfaceModel {
    public typealias ID = _TypeAssociatedID<Self, UUID>
    
    @LogicalParent var store: LTAccountStore
    
    public let id: ID
    public let accountType: LTAccountTypeIdentifier
    @_UnsafelySerialized
    public var credential: (any LTAccountCredential)?
    public var accountDescription: String?
    
    @MainActor
    public var accountTypeDescription: LTAccountTypeDescription {
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
        accountType: LTAccountTypeIdentifier,
        credential: (any LTAccountCredential)?,
        description: String?
    ) {
        self.id = id
        self.accountType = accountType
        self.credential = credential
        self.accountDescription = description
    }
}
 
public struct LTAccountTypeIdentifier: Codable, ExpressibleByStringLiteral, Hashable, Sendable {
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

// MARK: - Conformances

extension LTAccount: PersistentIdentifierConvertible {
    public var persistentID: ID {
        id
    }
}
