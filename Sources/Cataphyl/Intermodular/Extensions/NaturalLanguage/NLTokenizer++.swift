//
// Copyright (c) Vatsal Manot
//

import Foundation
import NaturalLanguage

extension NLTokenizer {
    public static func tokens(
        for text: String,
        unit: NLTokenUnit
    ) -> [Range<String.Index>] {
        let tokenizer = NLTokenizer(unit: unit)
        
        tokenizer.string = text
        
        return tokenizer.tokens(for: text.startIndex..<text.endIndex)
    }
}
