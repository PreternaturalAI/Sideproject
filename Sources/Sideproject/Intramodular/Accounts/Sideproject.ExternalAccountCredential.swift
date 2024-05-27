//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow

extension Sideproject {
    public protocol ExternalAccountCredential: Codable, Hashable {
        static var empty: Self { get }
    }
}

// MARK: - Implemented Conformances

extension Sideproject {
    public enum ExternalAccountCredentialTypes {
        @HadeanIdentifier("didap-vipin-jazil-nudam")
        @RuntimeDiscoverable
        public struct APIKey: Sideproject.ExternalAccountCredential {
            public static var empty: Self {
                .init(serverURL: nil, key: "")
            }
            
            public var serverURL: URL?
            public var key: String
        }
    }
}
