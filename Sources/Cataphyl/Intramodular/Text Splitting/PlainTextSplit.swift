//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

/// A singular text split from some source plain-text document.
public struct PlainTextSplit: Codable, Hashable, PlainTextDocumentProtocol {
    public typealias Chunk = PlainTextDocument.SequentialSelection
    
    public var text: String {
        components.lazy.map(\.text).joined()
    }
    
    public var components: [Component]
    
    public init(components: [Component]) {
        self.components = components
    }
}

extension PlainTextSplit {
    public var ranges: PlainTextDocument.ConsecutiveRanges {
        .init(
            ranges: components
                .compactMap {
                    if case .original(let text) = $0 {
                        return text.utf16Range
                    } else {
                        return nil
                    }
                }
                .map({ PlainTextDocument.TextRange.utf16(range: $0) })
        )
    }
}

extension PlainTextSplit {
    public struct SourceText: Codable, Hashable {
        public let utf16Range: Range<Int>
        public let text: String
    }
    
    public enum Component: Codable, Hashable {
        case original(SourceText)
        case inserted(String)
        
        var eitherValue: Either<SourceText, String> {
            switch self {
                case .original(let x):
                    return .left(x)
                case .inserted(let y):
                    return .right(y)
            }
        }
        
        init(eitherValue: Either<SourceText, String>) {
            switch eitherValue {
                case .left(let x):
                    self = .original(x)
                case .right(let y):
                    self = .inserted(y)
            }
        }
        
        var text: String {
            switch self {
                case .original(let substring):
                    return substring.text
                case .inserted(let text):
                    return text
            }
        }
    }
}

extension PlainTextSplit {
    public var isEmpty: Bool {
        text.isEmpty
    }
    
    public var count: Int {
        text.count
    }
    
    public func contains(_ other: String) -> Bool {
        components.contains(where: { $0.text.contains(other) })
    }
    
    public func components(
        separatedBy separator: String
    ) -> [Self] {
        components.lazy
            .filter({ $0.text != separator })
            .flatMap({ $0.components(separatedBy: separator) })
            .map({ Self(components: [$0]) })
    }
    
    public mutating func append(_ other: Self) {
        self.components.append(contentsOf: other.components)
    }
    
    public func appending(_ other: Self) -> Self {
        build(self) {
            $0.append(other)
        }
    }
    
    public func prefix(
        _ count: Int,
        tokenizer: some TextTokenizer
    ) -> Self {
        fatalError()
    }
    
    public func trimmingCharacters(
        in characterSet: CharacterSet
    ) -> Self {
        var components = self.components
        
        components.mutateFirstAndLast(
            first: {
                $0 = $0?.removingLeadingCharacters(in: characterSet)
            },
            last: {
                $0 = $0?.removingTrailingCharacters(in: characterSet)
            }
        )
        
        return .init(components: components)
    }
}

// MARK: - Initializers

extension PlainTextSplit {
    public init() {
        self.init(components: [])
    }
    
    public init(source: String) {
        self.components = [.original(.init(utf16Range: source._toUTF16Range(source.bounds), text: source))]
    }
    
    public init(_ range: Range<String.Index>, in source: String) {
        let text = SourceText(utf16Range: source._toUTF16Range(range), text: String(source[range]))
        
        self.components = [.original(text)]
    }
}

// MARK: - Conformances

extension PlainTextSplit: AdditionOperatable {
    public static func + (lhs: Self, rhs: String) -> Self {
        lhs.appending(.init(stringLiteral: rhs))
    }
    
    public static func + (lhs: String, rhs: Self) -> Self {
        Self(stringLiteral: lhs).appending(rhs)
    }
    
    public static func + (lhs: Self, rhs: Self) -> Self {
        lhs.appending(rhs)
    }
}

extension PlainTextSplit: CustomStringConvertible {
    public var description: String {
        text
    }
}

extension PlainTextSplit: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(components: [.inserted(value)])
    }
}

// MARK: - Auxiliary

extension Sequence where Element == PlainTextSplit {
    public func joined(separator: String) -> Element {
        .init(components: Array(lazy.flatMap({ $0.components }).interspersed(with: .inserted(separator))))
    }
    
    public func joined() -> Element {
        Element(components: Array(lazy.flatMap({ $0.components })))
    }
}

extension PlainTextSplit.SourceText {
    public func removingLeadingCharacters(
        in characterSet: CharacterSet
    ) -> Self? {
        let newText = text.removingLeadingCharacters(in: characterSet)
        let delta = text.count - newText.count
        
        guard !newText.isEmpty else {
            return nil
        }
        
        let newRange = (utf16Range.startIndex + delta)..<utf16Range.upperBound
        
        return .init(
            utf16Range: newRange,
            text: newText
        )
    }
    
    public func removingTrailingCharacters(
        in characterSet: CharacterSet
    ) -> Self? {
        let newText = text.removingTrailingCharacters(in: characterSet)
        let delta = text.count - newText.count
        
        guard !newText.isEmpty else {
            return nil
        }
        
        let newRange = utf16Range.startIndex..<(utf16Range.upperBound - delta)
        
        return .init(
            utf16Range: newRange,
            text: newText
        )
    }
}

extension PlainTextSplit.Component {
    public func components(
        separatedBy separator: String
    ) -> [Self] {
        switch self {
            case .original(let text):
                let string = text.text
                
                return string
                    ._componentsWithRanges(separatedBy: separator)
                    .map { (componentString, componentRange) in
                        let componentUTF16Range = string._toUTF16Range(componentRange)
                        
                        let convertedRange = (text.utf16Range.lowerBound + componentUTF16Range.lowerBound)..<(text.utf16Range.lowerBound + componentUTF16Range.upperBound)
                        
                        return Self.original(.init(utf16Range: convertedRange, text: componentString))
                    }
            case .inserted(let text):
                return text.components(separatedBy: separator).map(Self.inserted)
        }
    }
    
    public func removingLeadingCharacters(
        in characterSet: CharacterSet
    ) -> Self? {
        eitherValue.flatMap(
            left: {
                $0.removingLeadingCharacters(in: characterSet)
            },
            right: {
                $0.removingLeadingCharacters(in: characterSet).nilIfEmpty()
            }
        )
        .map(Self.init(eitherValue:))
    }
    
    public func removingTrailingCharacters(
        in characterSet: CharacterSet
    ) -> Self? {
        eitherValue.flatMap(
            left: {
                $0.removingTrailingCharacters(in: characterSet)
            },
            right: {
                $0.removingTrailingCharacters(in: characterSet).nilIfEmpty()
            }
        )
        .map(Self.init(eitherValue:))
    }
}

/*extension Collection where Element: Collection {
 func prefixCumulative(_ n: Int) -> [[Element.Element]] {
 var result: [[Element.Element]] = []
 var count = 0
 
 outerLoop: for subCollection in self {
 var subResult: [Element.Element] = []
 for element in subCollection {
 if count < n {
 subResult.append(element)
 count += 1
 } else {
 break outerLoop
 }
 }
 result.append(subResult)
 }
 
 return result
 }
 
 func suffixCumulative(_ n: Int) -> [[Element.Element]] {
 let reversedResult = self.reversed().prefixCumulative(n)
 return reversedResult.reversed().map { $0.reversed() }
 }
 }*/
