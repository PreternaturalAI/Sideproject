//
// Copyright (c) Vatsal Manot
//

import SwiftUIZ

public struct _AccountEntryForm: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\._submit) var submit
    
    public enum Intent {
        case create
        case edit
    }
    
    public let intent: Intent
    public let accountTypeDescription: Sideproject.ExternalAccountTypeDescription
    
    @_ConstantOrStateOrBinding var credential: (any Sideproject.ExternalAccountCredential)?
    
    public init(
        _ intent: Intent,
        accountTypeDescription: Sideproject.ExternalAccountTypeDescription,
        credential: Binding<(any Sideproject.ExternalAccountCredential)?>? = nil
    ) {
        self.intent = intent
        self.accountTypeDescription = accountTypeDescription
        self._credential = credential.map({ .binding($0) }) ?? .state(initialValue: nil)
    }
    
    private var isSubmitDisabled: Bool {
        self.credential?.isEmpty ?? true
    }
    
    public var body: some View {
        Group {
            _TypeCastBinding($credential.withDefaultValue(accountTypeDescription.credentialType.empty)) { proxy in
                proxy.as(Sideproject.ExternalAccountCredentialTypes.APIKey.self) { $binding in
                    APICredential(subject: $binding)
                }
            }
        }
        .submitDisabled(isSubmitDisabled)
        .formStyle(.grouped)
        .onSubmit(of: (any Sideproject.ExternalAccountCredential).self) { credential in
            self.credential = credential
            
            commit()
        }
        .toolbar {
            ToolbarItemGroup(placement: .cancellationAction) {
                DismissPresentationButton("Cancel")
            }
            
            ToolbarItemGroup(placement: .confirmationAction) {
                DismissPresentationButton("Done") {
                    commit()
                }
                .disabled(isSubmitDisabled)
            }
        }
    }
    
    private func commit() {
        let account = Sideproject.ExternalAccount(
            accountType: accountTypeDescription.accountType,
            credential: credential,
            description: "Untitled"
        )
        
        self.submit(account)
    }
    
    fileprivate struct APICredential: View {
        @Environment(\._submit) var submit
        
        @Binding var subject: Sideproject.ExternalAccountCredentialTypes.APIKey
        
        var body: some View {
            Form {
                SecureField(
                    subject.key.count < 32 ? "Enter your API key here:" : "API Key:",
                    text: $subject.key
                )
                ._focusOnAppear()
            }
            .onSubmit {                
                submit(subject)
            }
            .animation(.none, value: subject.key)
        }
    }
}
