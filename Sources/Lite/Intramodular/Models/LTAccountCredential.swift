//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow

public protocol LTAccountCredential: Codable, Hashable {
    static var empty: Self { get }
}

// MARK: - Implemented Conformances


public enum _LTAccountCredential {
    @HadeanIdentifier("didap-vipin-jazil-nudam")
    @RuntimeDiscoverable
    public struct APIKey: LTAccountCredential {
        public static var empty: Self {
            .init(serverURL: nil, key: "")
        }

        public var serverURL: URL?
        public var key: String
    }
}
