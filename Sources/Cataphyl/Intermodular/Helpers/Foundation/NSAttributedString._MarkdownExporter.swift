//
// Copyright (c) Vatsal Manot
//

import FoundationX
import SwiftUIX

extension NSAttributedString {
    @_spi(Internal)
    public struct _MarkdownExporter {
        public init() {
            
        }
        
        public func export(
            _ attributedString: NSAttributedString
        ) -> String {
            var result: String = ""
            let string = attributedString.string
            
            attributedString.enumerateAttributes { (attributes: [NSAttributedString.Key: Any], range: NSRange, _) in
                guard let range = Range<String.Index>(range, in: string) else {
                    assertionFailure()
                    
                    return
                }
                
                var substring: Substring = string[range]
                
                if let _ = attributes[.link] {
                    if let url = attributes[.link] as? URL {
                        substring = "[\(substring)](\(url.absoluteString))"
                    }
                } else {
                    if let font = attributes[.font] as? AppKitOrUIKitFont {
                        let descriptor = font.fontDescriptor
                        let traits = descriptor.symbolicTraits
                        
#if os(iOS)
                        if traits.contains(.bold) {
                            substring = "**\(substring)**"
                        }
                        
                        if traits.contains(.italic) {
                            substring = "_\(substring)_"
                        }
#endif
                    }
                }
                
                result.append(contentsOf: substring)
            }
            
            return result
        }
    }
}
