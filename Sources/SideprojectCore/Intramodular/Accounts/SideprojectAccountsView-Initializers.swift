//
// Copyright (c) Vatsal Manot
//

import Foundation
import SwiftUI

extension SideprojectAccountsView {
    /// e.g. let view = SideprojectAccountsView(only: [.openAI, .anthropic, .mistral])
    public init(only accounts: [any Sideproject.ExternalAccountTypeDescriptor]) {
        let identifiers = Set(accounts.map({ $0.accountType }))
        self.init(
            configuration: .init(predicate: #Predicate { accountType in
                identifiers.contains(accountType)
            })
        )
    }
    
    /// e.g. let view = SideprojectAccountsView(excluding: [.notion, .replicate])
    public init(excluding accounts: [any Sideproject.ExternalAccountTypeDescriptor]) {
        let identifiers = Set(accounts.map({ $0.accountType }))
        self.init(
            configuration: .init(predicate: #Predicate { accountType in
                !identifiers.contains(accountType)
            })
        )
    }
    
    public init(
        only identifiers: Set<Sideproject.ExternalAccountTypeIdentifier>
    ) {
        self.init(
            configuration: .init(predicate: #Predicate { accountType in
                identifiers.contains(accountType)
            })
        )
    }
    
    public init(
        excluding identifiers: Set<Sideproject.ExternalAccountTypeIdentifier>
    ) {
        self.init(
            configuration: .init(predicate: #Predicate { accountType in
                !identifiers.contains(accountType)
            })
        )
    }
}
