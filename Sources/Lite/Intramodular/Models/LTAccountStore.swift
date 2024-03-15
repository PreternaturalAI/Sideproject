//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Runtime
import Swallow
import SwiftUIX

@MainActor
public final class LTAccountStore: ObservableObject {
    public static let shared = LTAccountStore()
    
    @FileStorage(
        directory: .appDocuments,
        path: "Lite/Accounts",
        filename: UUID.self,
        coder: HadeanTopLevelCoder(coder: JSONCoder()),
        options: .init(readErrorRecoveryStrategy: .discardAndReset)
    )
    public var accounts: IdentifierIndexingArrayOf<LTAccount>
    
    @Published
    public var _testAccounts: IdentifierIndexingArrayOf<LTAccount>?
    
    private(set) lazy var allKnownAccountTypeDescriptions = {
        IdentifierIndexingArray<any LTAccountTypeDescription, LTAccountTypeIdentifier>(
            try! _SwiftRuntime.index
                .fetch(
                    .pureSwift,
                    .conformsTo(LTAccountTypeDescription.self),
                    .nonAppleFramework
                )
                .filter({ $0 is any _StaticInstance.Type })
                ._initializeAll(),
            id: \.accountType
        )
        .sorted(by: { $0.title < $1.title })
    }()
    
    public init() {
        _loadTestAccountsIfNeeded()
    }
}

extension LTAccountStore {
    fileprivate func _loadTestAccountsIfNeeded() {
        @FileStorage(
            url: URL.homeDirectory.appending(path: ".preternatural.toml"),
            coder: TOMLCoder()
        )
        var dotfile: _PreternaturalDotFile? = nil
        
        if let TEST_OPENAI_KEY = dotfile?.TEST_OPENAI_KEY {
            self._testAccounts = [LTAccount(
                accountType: LTAccountTypeDescriptions.OpenAI().accountType,
                credential: _LTAccountCredential.APIKey(key: TEST_OPENAI_KEY),
                description: nil
            )]
        }
    }
}

extension LTAccountStore {
    public subscript(
        _ type: LTAccountTypeIdentifier
    ) -> LTAccountTypeDescription {
        get {
            allKnownAccountTypeDescriptions[id: type]!
        }
    }
}
