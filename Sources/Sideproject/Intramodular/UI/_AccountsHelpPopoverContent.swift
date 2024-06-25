//
// Copyright (c) Vatsal Manot
//

import SwiftUIX

struct _AccountsHelpPopoverContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About Accounts")
                .font(.headline)
            Text("The Accounts view lets you safely manage your API keys for external service providers. Here's what you can do:")
                .font(.body)
            
            VStack(alignment: .leading, spacing: 8) {
                BulletPoint("Add new provider accounts")
                BulletPoint("View and manage existing accounts")
                BulletPoint("Automatically use API keys for each provider")
            }
            
            Text("When you add an account, the app securely stores the API key on your device. You won't need to re-enter it for future use.")
                .font(.body)
                .padding(.top, 4)
            
            Text("Note: API keys are stored locally on your device only. They are never uploaded to any server.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .frame(width: 300)
    }
}

struct BulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
