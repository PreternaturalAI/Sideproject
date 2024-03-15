//
// Copyright (c) Vatsal Manot
//

import SwiftUIZ

public struct LTAccountForm: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\._submit) var submit
    
    public enum Intent {
        case create
        case edit
    }
    
    public let intent: Intent
    public let accountTypeDescription: LTAccountTypeDescription
    
    @_ConstantOrStateOrBinding var credential: (any LTAccountCredential)?
    
    public init(
        _ intent: Intent,
        accountTypeDescription: LTAccountTypeDescription,
        credential: Binding<(any LTAccountCredential)?>? = nil
    ) {
        self.intent = intent
        self.accountTypeDescription = accountTypeDescription
        self._credential = credential.map({ .binding($0) }) ?? .state(initialValue: nil)
    }
    
    public var body: some View {
        Group {
            _TypeCastBinding($credential.withDefaultValue(accountTypeDescription.credentialType.empty)) { proxy in
                proxy.as(_LTAccountCredential.APIKey.self) { $binding in
                    APICredential(subject: $binding)
                }
            }
        }
        .formStyle(.grouped)
        .onSubmit(of: (any LTAccountCredential).self) { credential in
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
            }
        }
    }
    
    private func commit() {
        let account = LTAccount(
            accountType: accountTypeDescription.accountType,
            credential: credential,
            description: "Untitled"
        )
        
        self.submit(account)
    }
    
    fileprivate struct APICredential: View {
        @Environment(\._submit) var submit
        
        @Binding var subject: _LTAccountCredential.APIKey
        
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
