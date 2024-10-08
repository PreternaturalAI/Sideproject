//
// Copyright (c) Vatsal Manot
//

@_exported import Cataphyl
@_exported import Diagnostics
@_exported import LargeLanguageModels
@_exported import Merge
@_exported import OpenAI
@_exported import Swallow
@_exported import SwallowMacrosClient
@_exported import SwiftUIX

extension Bundle {
    public static let _Sideproject = Bundle.module
}

#once {
    Task(priority: .userInitiated) { @MainActor in
        try await Task.sleep(.seconds(1))
        
        _ = Sideproject.shared
        _ = Sideproject.ExternalAccountStore.shared
    }
}
