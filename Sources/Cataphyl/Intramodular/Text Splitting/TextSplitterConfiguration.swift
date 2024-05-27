//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Diagnostics
import FoundationX
import Swallow

public enum TextSplitterError: Error {
    case invalidConfiguration
    case maximumSplitSizeExceeded(Int)
    case unexpectedOverlap(between: PlainTextSplit, and: PlainTextSplit)
    case topLevelSplitsMoreGranularThanExpected([PlainTextSplit])
    case unknown
}

public struct TextSplitterConfiguration: Codable, Hashable, Sendable {
    public let maximumSplitSize: Int?
    public let maximumSplitOverlap: Int?
    @_UnsafelySerialized
    public var tokenizer: any Codable & TextTokenizer
    
    public init(
        maximumSplitSize: Int?,
        maximumSplitOverlap: Int?,
        tokenizer: any Codable & TextTokenizer = _StringCharacterTokenizer()
    ) throws {
        self.maximumSplitSize = maximumSplitSize
        self.maximumSplitOverlap = maximumSplitOverlap ?? 0
        self.tokenizer = tokenizer
        
        if let maximumSplitSize, let maximumSplitOverlap {
            guard maximumSplitSize > maximumSplitOverlap else {
                assertionFailure(TextSplitterError.invalidConfiguration)
                
                return
            }
        }
    }
}
