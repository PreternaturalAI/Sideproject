//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Swallow
import SwiftUIZ

@View(.dynamic)
public struct SideprojectAccountsView: View {
    public struct Configuration: ExpressibleByNilLiteral, DynamicProperty {
        public private(set) var predicate: Predicate<Sideproject.ExternalAccountTypeIdentifier>?
        
        public init(nilLiteral: ()) {
            
        }
        
        public init(
            predicate: Predicate<Sideproject.ExternalAccountTypeIdentifier>?
        ) {
            self.predicate = predicate
        }
    }
    
    private let configuration: Configuration
    
    @StateObject var store: Sideproject.ExternalAccountStore = Sideproject.ExternalAccountStore.shared
    
    public init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    public init() {
        self.init(
            configuration: .init(predicate: nil)
        )
    }
    
    public var filteredAccounts: IdentifierIndexingArrayOf<Sideproject.ExternalAccount> {
        guard let predicate = configuration.predicate else {
            return store.accounts
        }
        
        return IdentifierIndexingArrayOf(
            store.accounts.filter { account in
                (try? predicate.evaluate(account.accountType)) ?? false
            }
        )
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
                
                ForEach(filteredAccounts, from: $store.accounts) { ($account: Binding<Sideproject.ExternalAccount>) in
                    PresentationLink {
                        withEnvironmentValue(\.presentationManager) { presentationManager in
                            EditAccountView(account: $account._assigningLogicalParent(store, to: \.$store))
                                .onSubmit(of: Sideproject.ExternalAccount.self) { editedAccount in
                                    var editedAccount = editedAccount
                                    
                                    editedAccount.id = account.id
                                    
                                    store.accounts.upsert(editedAccount)
                                    
                                    presentationManager.dismiss()
                                }
                                ._overrideOnExitCommand {
                                    presentationManager.dismiss()
                                }
                        }
                    } label: {
                        Cell(account: $account._assigningLogicalParent(store, to: \.$store))
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
        ._environment(Configuration.self, configuration)
    }
    
    private struct EditAccountView: View {
        @Binding var account: Sideproject.ExternalAccount
        
        var body: some View {
            _SwiftUI_UnaryViewAdaptor {
                NavigationStack {
                    _AccountEntryForm(
                        .edit,
                        accountTypeDescriptor: account.accountTypeDescriptor,
                        credential: $account.credential
                    )
                    .navigationTitle("Edit Account")
                }
                .frame(idealWidth: 448, idealHeight: 560/2)
            }
        }
    }
    
    private struct NewAccountButton: View {
        @EnvironmentObject var store: Sideproject.ExternalAccountStore
        
        var body: some View {
            PresentationLink {
                withEnvironmentValue(\.presentationManager) { presentationManager in
                    _AccountPicker()
                        .onSubmit(of: Sideproject.ExternalAccount.self) { account in
                            let account = _withLogicalParent(store) {
                                account
                            }
                            
                            store.accounts.append(account)
                        }
                        ._overrideOnExitCommand {
                            presentationManager.dismiss()
                        }
                }
            } label: {
                Image(systemName: .plus)
                    .font(.title)
                    .foregroundColor(.secondary)
                    .imageScale(.large)
            }
            .buttonStyle(AnyButtonStyle {
                $0.label.modifier(_CellContentStyle())
            })
        }
    }
    
    private struct Cell: View {
        @EnvironmentObject var store: Sideproject.ExternalAccountStore
        
        @Binding var account: Sideproject.ExternalAccount
        
        var accountType: any Sideproject.ExternalAccountTypeDescriptor {
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
                
                EditableText(text: $account.displayName)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.body.weight(.medium))
                    .foregroundColor(.label)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.disabled)
            }
            .frame(width: .greedy, alignment: .leading)
            .padding(.horizontal, 10)
            .modifier(_CellContentStyle())
        }
    }
    
    private struct _CellContentStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .frame(CGSize(width: 126, height: 60))
                .background {
                    HoverReader { proxy in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.quaternary)
                            .overlay {
                                if proxy.isHovering {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.quaternary)
                                        .transition(.opacity)
                                }
                            }
                            .animation(.snappy.speed(2), value: proxy.isHovering)
                            .shadow(color: Color.black, radius: 6)
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
