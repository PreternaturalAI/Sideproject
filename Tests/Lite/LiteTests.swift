//
// Copyright (c) Vatsal Manot
//

import Lite
import XCTest

final class LiteTests: XCTestCase {
    @MainActor
    func testLoadingServices() async throws {
        let services = try await Lite.shared.services
        
        XCTAssert(!services.isEmpty)
    }
}
