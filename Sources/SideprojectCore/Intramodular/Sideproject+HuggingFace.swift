//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import HuggingFace

extension HuggingFace.Hub.Client {
    @MainActor
    init(from account: Sideproject.ExternalAccount) throws {
        if account.accountType != Sideproject.ExternalAccountTypeDescriptors.HuggingFace().accountType {
            throw CustomStringError("the account must be a HuggingFace account")
        }
        
        guard let credentials = Sideproject.ExternalAccountStore.shared.credentials(for: .huggingFace).first?.value as? Sideproject.ExternalAccountCredentialTypes.APIKey else {
            throw Never.Reason.unexpected
        }
        
        self.init(hfToken: credentials.key)
    }
}
