//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import FoundationX
import Swallow

@RuntimeDiscoverable
public struct RecursiveCharacterTextSplitter: Codable, TextSplitter {
    public let configuration: TextSplitterConfiguration
    public let separators: [String]
    
    public init(
        configuration: TextSplitterConfiguration,
        separators: [String] = ["\n\n", "\n", ".", " ", ""]
    ) {
        self.configuration = configuration
        self.separators = separators
    }
}

// MARK: - Implementation

extension RecursiveCharacterTextSplitter {
    public func split(
        text: String
    ) throws -> [PlainTextSplit] {
        try _split(PlainTextSplit(source: text), topLevel: true)
    }
    
    private func _split(
        _ input: PlainTextSplit,
        topLevel: Bool
    ) throws -> [PlainTextSplit] {
        let maximumSplitSize = configuration.maximumSplitSize ?? Int.maximum
        let separator = try _bestSeparator(for: input)
        let splits = input
            .components(separatedBy: separator)
            .compactMap({ $0.trimmingCharacters(in: .whitespaces) })
            .filter({ !$0.isEmpty })
        
        if try configuration.tokenizer.tokenCount(for: input.text) <= maximumSplitSize {
            return [input]
        }
        
        var result: [PlainTextSplit] = []
        var validSplits: [PlainTextSplit] = []
        
        for split in splits {
            if try configuration.tokenizer.tokenCount(for: split.text) < (maximumSplitSize + (separator.count * (validSplits.count > 1 ? 1 : 0))) {
                validSplits.append(split)
            } else {
                if !validSplits.isEmpty {
                    let merged = try _naivelyMerge(
                        validSplits,
                        separator: separator,
                        topLevel: false
                    )
                                        
                    result.append(contentsOf: merged)
                    
                    validSplits.removeAll()
                }
                
                let otherSplits = try self._split(split, topLevel: false)
                                
                result.append(contentsOf: otherSplits)
            }
        }
        
        if !validSplits.isEmpty {
            let merged = try _naivelyMerge(
                validSplits,
                separator: separator,
                topLevel: false
            )
                    
            result.append(contentsOf: merged)
            
            validSplits.removeAll()
        }
        
        try _tryAssert(validSplits.isEmpty)
        
        if topLevel {
            try validate(topLevel: result)
        }
        
        return result
    }
    
    private func _split2(
        _ input: PlainTextSplit,
        topLevel: Bool
    ) throws -> [PlainTextSplit] {
        let maximumSplitSize = configuration.maximumSplitSize ?? Int.maximum
        let maximumSplitOverlap = configuration.maximumSplitOverlap ?? 0
        
        let separator = try _bestSeparator(for: input)
        let splits = input
            .components(separatedBy: separator)
            .compactMap({ $0.trimmingCharacters(in: .whitespaces) })
            .filter({ !$0.isEmpty })
        
        if try configuration.tokenizer.tokenCount(for: input.text) < maximumSplitSize {
            return [input]
        }
        
        var result: [PlainTextSplit] = []
        var current: [PlainTextSplit] = []
        var total = 0
        
        for split in splits {
            let currentLength = try configuration.tokenizer.tokenCount(for: split.text)
            
            if (currentLength + total) > maximumSplitSize {
                if total > maximumSplitSize {
                    throw TextSplitterError.maximumSplitSizeExceeded(maximumSplitSize)
                }
                
                if current.count > 0  {
                    guard let joinedSplit = _concatenate(current) else {
                        assertionFailure()
                        
                        throw TextSplitterError.invalidConfiguration
                    }
                    
                    current.append(joinedSplit)
                    
                    while (total > maximumSplitOverlap) || ((total + currentLength) > maximumSplitSize && (total > 0)) {
                        total -= try configuration.tokenizer.tokenCount(for: current[0].text)
                        
                        current.removeFirst()
                    }
                }
            }
            
            current.append(split)
            
            total += currentLength
        }
        
        if !current.isEmpty {
            if let joinedSplit = _concatenate(current) {
                result.append(joinedSplit)
            }
            
            current.removeAll()
        }
        
        try _tryAssert(current.isEmpty)
        
        try _warnOnThrow {
            try validate(topLevel: result)
        }
        
        return result
    }
    
    private func _bestSeparator(
        for split: PlainTextSplit
    ) throws -> String {
        var result = try separators.last.unwrap()
        
        for currentSeparator in separators {
            if currentSeparator.isEmpty {
                result = ""
                
                break
            }
            
            if split.contains(currentSeparator) {
                result = currentSeparator
                
                break
            }
        }
        
        return result
    }
}
