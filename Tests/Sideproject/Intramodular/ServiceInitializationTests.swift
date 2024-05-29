//
// Copyright (c) Vatsal Manot
//

import Sideproject
import XCTest

final class ServiceInitializationTests: XCTestCase {
    @MainActor
    func testLoadingServices() async throws {
        let services = try await Sideproject.shared.services
        
        XCTAssert(!services.isEmpty)
    }
}
