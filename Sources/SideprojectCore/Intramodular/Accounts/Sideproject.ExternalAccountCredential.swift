//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow

extension Sideproject {
    public protocol ExternalAccountCredential: Codable, Hashable {
        static var empty: Self { get }
        
        var isEmpty: Bool { get }
    }
}

extension Sideproject {
    public struct ExternalAccountCredentialTypeName<T: Sideproject.ExternalAccountCredential> {
        fileprivate init() {
            
        }
    }
}

extension Sideproject.ExternalAccountCredentialTypeName where T == Sideproject.ExternalAccountCredentialTypes.APIKey {
    public static var apiKey: Self {
        Self()
    }
}

// MARK: - Conformees

extension Sideproject {
    public enum ExternalAccountCredentialTypes {

    }
}

extension Sideproject.ExternalAccountCredentialTypes {
    @HadeanIdentifier("pasap-sizak-tokak-dufuz")
    @RuntimeDiscoverable
    public struct UsernameAndPassword: Sideproject.ExternalAccountCredential {
        public static var empty: Self {
            Self(username: nil, password: nil)
        }
        
        public var username: String?
        public var password: String?
        
        public var isEmpty: Bool {
            username.isNilOrEmpty && password.isNilOrEmpty
        }
    }

    @HadeanIdentifier("didap-vipin-jazil-nudam")
    @RuntimeDiscoverable
    public struct APIKey: Sideproject.ExternalAccountCredential {
        public static var empty: Self {
            Self(serverURL: nil, key: "")
        }
        
        public var serverURL: URL?
        public var key: String
        
        public var isEmpty: Bool {
            key.isEmpty
        }
    }
}

extension Sideproject.ExternalAccountCredential where Self == Sideproject.ExternalAccountCredentialTypes.APIKey {
    public static var apiKey: Self.Type {
        Self.self
    }
}
