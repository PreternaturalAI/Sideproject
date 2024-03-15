//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import FoundationX
import Swallow

/// A document that represents plain-text.
public struct PlainTextDocument: Hashable, PlainTextDocumentProtocol, Sendable {
    public typealias Chunk = SequentialSelection
    
    public var text: String
    
    public init(text: String) {
        self.text = text
    }
}

extension PlainTextDocument {
    /// The range of a piece of text relative to some source string.
    public enum TextRange: Codable, Comparable, CustomStringConvertible, Hashable, Sendable {
        case utf16(range: Range<Int>)
        
        public var description: String {
            switch self {
                case .utf16(let range):
                    return "\(range.bounds.lowerBound)..<\(range.bounds.upperBound) (utf-16)"
            }
        }
        
        public func overlaps(_ other: Self) -> Bool {
            switch (self, other) {
                case (.utf16(let lhs), .utf16(let rhs)):
                    return lhs.overlaps(rhs)
            }
        }
        
        public static func < (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
                case (.utf16(let lhs), .utf16(let rhs)):
                    assert(!lhs.overlaps(rhs))
                    
                    return lhs.lowerBound < rhs.lowerBound
            }
        }
    }
    
    public struct ConsecutiveRanges: Codable, CustomStringConvertible, Hashable, Sendable, Sequence {
        public let ranges: [TextRange]
        
        public init(ranges: [TextRange]) {
            self.ranges = ranges
        }
        
        public var description: String {
            ranges.description
        }
        
        public var first: TextRange? {
            ranges.first
        }
        
        public var last: TextRange? {
            ranges.last
        }
        
        public func makeIterator() -> AnyIterator<TextRange> {
            AnyIterator(ranges.makeIterator())
        }
    }
}

// MARK: - Conformances

extension PlainTextDocument: Codable {
    public init(from decoder: Decoder) throws {
        try self.init(text: String(from: decoder))
    }
    
    public func encode(to encoder: Encoder) throws {
        try text.encode(to: encoder)
    }
}

extension PlainTextDocument: CustomStringConvertible, LosslessStringConvertible {
    public var description: String {
        text
    }
    
    public init(_ description: String) {
        self.init(text: description)
    }
}

extension PlainTextDocument: HadeanIdentifiable {
    public static var hadeanIdentifier: HadeanIdentifier {
        "guguk-batab-nojin-fiton"
    }
}
