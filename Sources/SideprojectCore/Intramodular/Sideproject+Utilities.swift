//
// Copyright (c) Vatsal Manot
//

import CoreMI
import CorePersistence
import LargeLanguageModels
import Merge
import Runtime
import SwiftUIX

extension Sideproject {
    /// Get a specific API client (for e.g. `Sideproject.shared.client(ofType: OpenAI.Client.self)`)
    ///
    /// Note that this will fail if there are multiple API keys for the same client type.
    public func client<T>(
        ofType type: T.Type
    ) async -> T? {
        #try(.optimistic) {
            try await services.firstAndOnly(byUnwrapping: { $0 as? T })
        }
    }
    
    /// Get a list of all known API clients of a given type.
    public func client<T>(
        ofType type: T.Type
    ) async -> [T] {
        #try(.optimistic) {
            try await services.compactMap({ $0 as? T })
        } ?? []
    }
}
