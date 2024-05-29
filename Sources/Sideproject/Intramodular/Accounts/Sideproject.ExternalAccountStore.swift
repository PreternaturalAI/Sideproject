//
// Copyright (c) Vatsal Manot
//

import CoreMI
import CorePersistence
import Runtime
import Swallow
import AppIntents

extension Sideproject {
    @MainActor
    public final class ExternalAccountStore: ObservableObject {
        public static let shared = Sideproject.ExternalAccountStore()
        
        @FileStorage(
            directory: .appDocuments,
            path: "Sideproject/Accounts",
            filename: UUID.self,
            coder: HadeanTopLevelCoder(coder: JSONCoder()),
            options: .init(readErrorRecoveryStrategy: .discardAndReset)
        )
        public var accounts: IdentifierIndexingArrayOf<Sideproject.ExternalAccount>
        
        @_documentation(visibility: internal)
        @Published
        public var _testAccounts: IdentifierIndexingArrayOf<Sideproject.ExternalAccount>?
        
        private(set) lazy var allKnownAccountTypeDescriptions = {
            IdentifierIndexingArray<any Sideproject.ExternalAccountTypeDescription, Sideproject.ExternalAccountTypeIdentifier>(
                try! TypeMetadata._queryAll(
                    .pureSwift,
                    .conformsTo(Sideproject.ExternalAccountTypeDescription.self),
                    .nonAppleFramework
                )
                .filter({ $0 is any _StaticInstance.Type })
                ._initializeAll(),
                id: \.accountType
            )
            .sorted(by: { $0.title < $1.title })
        }()
        
        public init() {
            
        }
    }
}

extension Sideproject.ExternalAccountStore {
    /// Loads test accounts from ~/.preternatural.toml during unit tests.
    fileprivate func _loadTestAccountsIfNeeded() {
        guard ProcessInfo.processInfo._isRunningWithinXCTest else {
            return
        }
                
        if let key = _PreternaturalDotFile.dotfileForCurrentUser?.TEST_OPENAI_KEY {
            self._testAccounts = [Sideproject.ExternalAccount(
                accountType: Sideproject.ExternalAccountTypeDescriptions.OpenAI().accountType,
                credential: Sideproject.ExternalAccountCredentialTypes.APIKey(key: key),
                description: nil
            )]
        }

        if let key = _PreternaturalDotFile.dotfileForCurrentUser?.TEST_ANTHROPIC_KEY {
            self._testAccounts = [Sideproject.ExternalAccount(
                accountType: Sideproject.ExternalAccountTypeDescriptions.Anthropic().accountType,
                credential: Sideproject.ExternalAccountCredentialTypes.APIKey(key: key),
                description: nil
            )]
        }
    }
}

extension Sideproject.ExternalAccountStore {
    public subscript(
        _ type: Sideproject.ExternalAccountTypeIdentifier
    ) -> Sideproject.ExternalAccountTypeDescription {
        get {
            allKnownAccountTypeDescriptions[id: type]!
        }
    }
}
