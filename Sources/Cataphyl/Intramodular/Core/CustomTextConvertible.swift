//
// Copyright (c) Vatsal Manot
//

import Swallow

/// A type that can be represented as text.
public protocol CustomTextConvertible: CustomStringConvertible {
    var text: String { get throws }
}
