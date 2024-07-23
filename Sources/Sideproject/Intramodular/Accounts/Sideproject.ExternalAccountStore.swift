//
// Copyright (c) Vatsal Manot
//

import CoreMI
import CorePersistence
import FoundationX
import Runtime
import Swallow

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
            IdentifierIndexingArray<any Sideproject.ExternalAccountTypeDescriptor, Sideproject.ExternalAccountTypeIdentifier>(
                try! TypeMetadata._queryAll(
                    .pureSwift,
                    .conformsTo((any Sideproject.ExternalAccountTypeDescriptor).self),
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
    public subscript(
        _ type: Sideproject.ExternalAccountTypeIdentifier
    ) -> any Sideproject.ExternalAccountTypeDescriptor {
        get {
            allKnownAccountTypeDescriptions[id: type]!
        }
    }
    
    public subscript(
        _ id: Sideproject.ExternalAccount.ID
    ) -> Sideproject.ExternalAccount? {
        get {
            accounts[id: id]
        }
    }
}

extension Sideproject.ExternalAccountStore {
    public func accounts(
        for type: any Sideproject.ExternalAccountTypeDescriptor
    ) -> [Sideproject.ExternalAccount] {
        self.accounts.filter({ $0.accountTypeDescriptor.accountType == type.accountType })
    }

    /// Returns all available credentials for a given account type, keyed by account IDs.
    ///
    /// For example `Sideproject.ExternalAccountStore.shared.credentials(for: .groq)`
    public func credentials(
        for type: any Sideproject.ExternalAccountTypeDescriptor
    ) -> [Sideproject.ExternalAccount.ID: any Sideproject.ExternalAccountCredential] {
        self.accounts
            .filter({ $0.accountTypeDescriptor.accountType == type.accountType })
            ._mapToDictionaryWithUniqueKey({ $0.id })
            .compactMapValues({ $0.credential })
    }
    
    public func credential<T: Sideproject.ExternalAccountCredential>(
        ofType type: Sideproject.ExternalAccountCredentialTypeName<T>,
        for accountType: any Sideproject.ExternalAccountTypeDescriptor
    ) throws -> T {
        try credentials(for: accountType).firstAndOnly(byUnwrapping: { $0.value as? T }).unwrap()
    }
    
    public func hasCredentials(
        type: any Sideproject.ExternalAccountTypeDescriptor
    ) -> Bool {
        !credentials(for: type).isEmpty
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
                accountType: Sideproject.ExternalAccountTypeDescriptors.OpenAI().accountType,
                credential: Sideproject.ExternalAccountCredentialTypes.APIKey(key: key),
                description: nil
            )]
        }

        if let key = _PreternaturalDotFile.dotfileForCurrentUser?.TEST_ANTHROPIC_KEY {
            self._testAccounts = [Sideproject.ExternalAccount(
                accountType: Sideproject.ExternalAccountTypeDescriptors.Anthropic().accountType,
                credential: Sideproject.ExternalAccountCredentialTypes.APIKey(key: key),
                description: nil
            )]
        }
    }
}
