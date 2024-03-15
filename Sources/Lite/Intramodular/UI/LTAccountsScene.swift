//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow
import SwiftUIZ

public struct LTAccountsScene: DynamicView {
    @StateObject var store: LTAccountStore = LTAccountStore.shared
    
    public init() {
        
    }
    
    public var body: some View {
        VStack {
            cellGrid
                .frame(minWidth: 126)
            
            #if os(macOS)
            PathControl(url: try! store.$accounts.url)
            #endif
        }
        .padding()
        .environmentObject(store)
        .navigationTitle("Accounts")
    }
    
    private var cellGrid: some View {
        XStack(alignment: .topLeading) {
            LazyVGrid(
                columns: [.adaptive(width: 126, spacing: 8, alignment: .leading)],
                alignment: .leading,
                spacing: 8
            ) {
                NewAccountButton()
                
                ForEach($store.accounts) { $account in
                    PresentationLink {
                        EditAccountView(account: $account)
                            .onSubmit(of: LTAccount.self) { account in
                                store.accounts[id: account.id] = account
                            }
                    } label: {
                        Cell(account: $account._withLogicalParent(store))
                            .contextMenu {
                                Button("Delete", role: .destructive) {
                                    store.accounts.remove(account)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

extension LTAccountsScene {
    private struct EditAccountView: View {
        @Binding var account: LTAccount
        
        var body: some View {
            _SwiftUI_UnaryViewAdaptor {
                NavigationStack {
                    LTAccountForm(
                        .edit,
                        accountTypeDescription: account.accountTypeDescription,
                        credential: $account.credential
                    )
                    .navigationTitle("Edit Account")
                }
                .frame(width: 448, height: 560/2)
            }
        }
    }
    
    private struct NewAccountButton: View {
        @EnvironmentObject var store: LTAccountStore
        
        var body: some View {
            PresentationLink {
                LTAccountPicker()
                    .onSubmit(of: LTAccount.self) { account in
                        let account = try! _withLogicalParent(store) {
                            account
                        }
                                                
                        store.accounts.append(account)
                    }
            } label: {
                Image(systemName: .plus)
                    .font(.title)
                    .foregroundColor(.secondary)
                    .imageScale(.large)
            }
            .buttonStyle(AnyButtonStyle {
                $0.label.modifier(_CellStyle())
            })
        }
    }
    
    private struct Cell: View {
        @EnvironmentObject var store: LTAccountStore
        
        @Binding var account: LTAccount
        
        var accountType: LTAccountTypeDescription {
            store[account.accountType]
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                if let icon = accountType.icon {
                    icon
                        .resizable()
                        .clipShape(Circle())
                        .squareFrame(sideLength: 22)
                        .shadow(color: Color.black.opacity(0.33 / 2), radius: 1)
                }
                
                EditableText(
                    account.displayName,
                    text: $account.accountDescription
                )
                .onSubmit { text in
                    if text == "Untitled" {
                        withoutAnimation(after: .milliseconds(50)) {
                            account.accountDescription = account.accountTypeDescription.title
                        }
                    }
                }
                .font(.body.weight(.medium))
                .foregroundColor(.label)
            }
            .frame(width: .greedy, alignment: .leading)
            .padding(.horizontal, 10)
            .modifier(_CellStyle())
        }
    }
}

extension LTAccountsScene {
    struct _CellStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .frame(CGSize(width: 126, height: 60))
                .background {
                    HoverReader { proxy in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.quaternary)
                            .overlay {
                                if proxy.isHovering {
                                    Color.gray.opacity(0.1)
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 12)
                                        )
                                        .transition(.opacity)
                                }
                            }
                            .animation(.snappy.speed(2), value: proxy.isHovering)
                            .shadow(color: Color.black, radius: 7)
                    }
                }
            
        }
    }
}

extension Color {
    public static let alertBackgroundColor = Color.adaptable(
        light: .unimplemented,
        dark: Color(hexadecimal: "1b1b1c")
    )
    
    public static let accountModalBackgroundColor = Color.adaptable(
        light: .unimplemented,
        dark: Color(cube256: .sRGB, red: 29, green: 29, blue: 30)
    )
}
