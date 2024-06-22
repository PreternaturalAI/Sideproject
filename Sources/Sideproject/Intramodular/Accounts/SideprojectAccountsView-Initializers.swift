//
// Copyright (c) Vatsal Manot
//

import Foundation
import SwiftUI

extension SideprojectAccountsView {
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
