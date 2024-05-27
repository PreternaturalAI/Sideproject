//
// Copyright (c) Vatsal Manot
//

import Merge
import Swallow

/// An asynchronous text tokenizer.
public protocol AsyncTextTokenizer<Token>: Hashable, Sendable {
    associatedtype Token: Codable, Hashable, Sendable
    
    func encode(_ input: String) async throws -> [Token]
    func decode(_ tokens: [Token]) async throws -> String
    
    func tokenCount(for input: String) async throws -> Int
}

/// A synchronous text tokenizer.
///
/// The tokenizer *must* be preheated before use.
public protocol TextTokenizer<Token>: AsyncTextTokenizer, _MaybeAsyncProtocol, Hashable, Sendable {
    func encode(_ input: String) throws -> [Token]
    func decode(_ tokens: [Token]) throws -> String
    
    /// Allows tokenizers to optimize for token counting.
    func tokenCount(for input: String) throws -> Int
}

// MARK: - Implementation

extension TextTokenizer {
    public static func _preheat() async throws {
        
    }
    
    public func tokenCount(
        for input: String
    ) throws -> Int {
        try encode(input).count
    }
}

// MARK: - Implemented Conformances

public struct _StringCharacterTokenizer: HadeanIdentifiable, Codable, TextTokenizer {
    public typealias Token = Character
    
    public static var hadeanIdentifier: HadeanIdentifier {
        "hizih-havol-jonid-mahaf"
    }
    
    public init() {
        
    }
    
    public func encode(_ input: String) throws -> [Token] {
        Array(input)
    }
    
    public func decode(_ tokens: [Token]) throws -> String {
        String(tokens)
    }
    
    public func tokenCount(for input: String) throws -> Int {
        input.count
    }
}
