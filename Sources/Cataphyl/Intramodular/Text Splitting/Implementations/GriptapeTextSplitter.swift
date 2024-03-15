//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

/// A text splitter builder inspired from https://github.com/griptape-ai/griptape
public protocol GriptapeTextSplitter: TextSplitter {
    @ArrayBuilder
    var separators: [GriptapeTextSeparator] { get }
}

// MARK: - Implementation

extension GriptapeTextSplitter {
    @ArrayBuilder
    public var separators: [GriptapeTextSeparator] {
        GriptapeTextSeparator(" ")
    }
    
    public func split(
        text: String
    ) throws -> [PlainTextSplit] {
        try splitRecursively(chunk: PlainTextSplit(source: text), currentSeparator: nil)
    }
    
    private func splitRecursively(
        chunk: PlainTextSplit,
        currentSeparator: GriptapeTextSeparator? = nil
    ) throws -> [PlainTextSplit] {
        let maximumSplitSize = configuration.maximumSplitSize ?? Int.max
        let tokenCount = try configuration.tokenizer.tokenCount(for: chunk.text)
        
        if tokenCount <= maximumSplitSize {
            return [chunk]
        } else {
            var balanceIndex = -1
            var balanceDiff = Double.infinity
            var tokensCount = 0
            let halfTokenCount = tokenCount / 2
            
            let separators: [GriptapeTextSeparator]
            
            if let currentSeparator {
                separators = Array(self.separators[try self.separators.firstIndex(of: currentSeparator).unwrap()...])
            } else {
                separators = self.separators
            }
            
            for separator in separators {
                let subchunks = chunk.components(separatedBy: separator.value).filter {
                    !$0.isEmpty
                }
                
                if subchunks.count > 1 {
                    for (index, var subchunk) in subchunks.enumerated() {
                        if index < subchunks.count {
                            if separator.isPrefix {
                                subchunk = separator.value + subchunk
                            } else {
                                subchunk = subchunk + separator.value
                            }
                        }
                        
                        tokensCount += try configuration.tokenizer.tokenCount(for: subchunk.text)
                        
                        if Double(abs(tokensCount - halfTokenCount)) < balanceDiff {
                            balanceIndex = index
                            balanceDiff = Double(abs(tokensCount - halfTokenCount))
                        }
                    }
                    
                    var firstSubchunk: PlainTextSplit
                    var secondSubchunk: PlainTextSplit
                    
                    if separator.isPrefix {
                        firstSubchunk = separator.value + subchunks.prefix(upTo: balanceIndex + 1).joined(separator: separator.value)
                        secondSubchunk = separator.value + subchunks.suffix(from: balanceIndex + 1).joined(separator: separator.value)
                    } else {
                        firstSubchunk = subchunks.prefix(upTo: balanceIndex + 1).joined(separator: separator.value) + separator.value
                        secondSubchunk = subchunks.suffix(from: balanceIndex + 1).joined(separator: separator.value)
                    }
                    
                    let firstSubchunkRec = try splitRecursively(
                        chunk: firstSubchunk,
                        currentSeparator: separator
                    )
                    let secondSubchunkRec = try splitRecursively(
                        chunk: secondSubchunk,
                        currentSeparator: separator
                    )
                    
                    return firstSubchunkRec + secondSubchunkRec
                }
            }
            
            return []
        }
    }
}

// MARK: - Auxiliary

public struct GriptapeTextSeparator: Hashable {
    public let value: String
    public let isPrefix: Bool
    
    public init(_ value: String, isPrefix: Bool = false) {
        self.value = value
        self.isPrefix = isPrefix
    }
}

extension GriptapeTextSeparator: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value, isPrefix: false)
    }
}

// MARK: - Implemented Conformances

public enum GriptapeTextSplitters {
    public struct Markdown: GriptapeTextSplitter {
        public var separators: [GriptapeTextSeparator] {
            GriptapeTextSeparator("##", isPrefix: true)
            GriptapeTextSeparator("###", isPrefix: true)
            GriptapeTextSeparator("####", isPrefix: true)
            GriptapeTextSeparator("#####", isPrefix: true)
            GriptapeTextSeparator("######", isPrefix: true)
            GriptapeTextSeparator("```")
            GriptapeTextSeparator("\n\n")
            GriptapeTextSeparator(". ")
            GriptapeTextSeparator("! ")
            GriptapeTextSeparator("? ")
            GriptapeTextSeparator(" ")
        }
        
        public var configuration: TextSplitterConfiguration
        
        public init(configuration: TextSplitterConfiguration) {
            self.configuration = configuration
        }
    }
}
