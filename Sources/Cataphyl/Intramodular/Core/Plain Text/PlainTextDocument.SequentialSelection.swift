//
// Copyright (c) Vatsal Manot
//

import Swallow

extension PlainTextDocument {
    /// A sequential selection of text from a source `PlainTextDocument`.
    ///
    /// The selection maintains a list of consecutive ranges from the source document.
    public struct SequentialSelection: Codable, Comparable, Hashable, _ContiguousDocumentChunk {
        /// The consecutive ranges that constitute the span of the sequential selection of text.
        public struct Span: Comparable, CustomStringConvertible, Codable, Hashable, Sendable {
            public typealias RawValue = PlainTextDocument.ConsecutiveRanges
            
            public let rawValue: RawValue
            
            public var description: String {
                if let first = rawValue.first, let last = rawValue.ranges.last {
                    switch (first, last) {
                        case (.utf16(let lhs), .utf16(let rhs)):
                            let range = lhs.lowerBound..<rhs.upperBound
                            
                            return "\(range.bounds.lowerBound)..<\(range.bounds.upperBound) (utf-16)"
                    }
                } else {
                    return rawValue.description
                }
            }
            
            public init(rawValue: RawValue) {
                self.rawValue = rawValue
            }
            
            public static func < (lhs: Self, rhs: Self) -> Bool {
                lhs.rawValue.ranges.first! < rhs.rawValue.ranges.first!
            }
        }
        
        public let span: Span
        public let effectiveText: String
        
        public init(span: Span, effectiveText: String) {
            self.span = span
            self.effectiveText = effectiveText
        }
        
        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.span < rhs.span
        }
    }
}

// MARK: - Identifiable

extension PlainTextDocument.SequentialSelection: CustomStringConvertible {
    public var description: String {
        text.description
    }
}

extension PlainTextDocument.SequentialSelection: CustomTextConvertible {
    public var text: String {
        effectiveText
    }
}

extension PlainTextDocument.SequentialSelection: Identifiable {
    public var id: Span {
        span
    }
}
