//
// Copyright (c) Vatsal Manot
//

import Sideproject
import XCTest

final class ExternalAccountStoreTests: XCTestCase {
    @MainActor
    func testAccountStore() async throws {
        let store = Sideproject.ExternalAccountStore.shared
        
        _ = store.accounts
    }
}
