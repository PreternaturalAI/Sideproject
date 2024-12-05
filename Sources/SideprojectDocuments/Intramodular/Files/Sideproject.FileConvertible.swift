//
// Copyright (c) Vatsal Manot
//

import SideprojectCore
import SwiftUIX

extension Sideproject {
    /// A type that can be converted to an `Sideproject.File`.
    public protocol FileConvertible {
        func __conversion() async throws -> Sideproject.File
    }
}
