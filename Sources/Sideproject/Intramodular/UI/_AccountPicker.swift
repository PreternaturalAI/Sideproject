//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Foundation
import Swallow
import SwiftUIZ

public struct _AccountPicker: View {
    @Environment(_type: SideprojectAccountsView.Configuration.self)
    var accountsViewConfiguration: SideprojectAccountsView.Configuration
    
    @Environment(\._submit) var submit
    @Environment(\.presentationMode) var presentationMode

    @EnvironmentObject var store: Sideproject.ExternalAccountStore
    
    @State var path = NavigationPath()
    @State private var showAccountsHelpPopover = false
    
    public var body: some View {
        NavigationStack(path: $path) {
            _SwiftUI_UnaryViewAdaptor {
                content
            }
            .toolbar {
                if path.isEmpty {
                    toolbar
                }
            }
            .navigationDestination(for: Sideproject.ExternalAccountTypeIdentifier.self) { account in
                _AccountEntryForm(.create, accountTypeDescription: store[account])
                    .onSubmit(of: Sideproject.ExternalAccount.self) { account in
                        submit(account)
                        
                        presentationMode.dismiss()
                    }
            }
        }
        .frame(idealWidth: 448, idealHeight: 560)
        .background(Color.accountModalBackgroundColor.ignoresSafeArea())
        .toolbarBackground(.hidden, for: .automatic)
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup {
            Button {
                showAccountsHelpPopover.toggle()
            } label: {
                Image(systemName: .questionmark)
                    .imageScale(.medium)
                    .font(.subheadline.weight(.semibold))
            }
            .modify {
                if #available(iOS 17.0, macOS 14.0, *) {
                    $0.buttonBorderShape(.circle)
                } else {
                    $0
                }
            }
            .popover(isPresented: $showAccountsHelpPopover) {
                _AccountsHelpPopoverContent()
            }
        }
        
        ToolbarItemGroup(placement: .cancellationAction) {
            DismissPresentationButton("Cancel")
        }
    }
    
    private var content: some View {
        Form {
            List {
                ForEach(filteredAccountTypes, id: \.accountType) { account in
                    Cell(account: account, onSubmit: {
                        path.append(account.accountType)
                    })
                }
            }
        }
        .formStyle(.grouped)
        .frame(idealHeight: 500)
        .hidden(!path.isEmpty)
    }
    
    private struct Cell: View {
        let account: Sideproject.ExternalAccountTypeDescription
        let onSubmit: () -> Void
        
        var body: some View {
            #if os(iOS)
            button
            #endif
            
            #if os(macOS)
            HoverReader { hoverProxy in
                button
                .listRowBackground {
                    Group {
                        hoverProxy.isHovering ? Color.white.opacity(0.05) : nil
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSubmit()
                    }
                }
            }
            #endif
        }
        
        var button: some View {
            Button {
                onSubmit()
            } label: {
                ZStack(alignment: .leading) {
                    HStack {
                        if let image = account.icon {
                            image
                                .resizable()
                                .squareFrame(sideLength: 28)
                        }
                        
                        Text(account.title)
                            .font(.title3)
                            .foregroundStyle(Color.label)
                    }
                    .frame(width: .greedy, alignment: .center)
                    Text(account.title).opacity(0) //FIXME: This is a hack to get the separators to the edge
                }
                .frame(width: .greedy, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .padding(.vertical, 12)
            .frame(width: .greedy, alignment: .leading)
        }
    }
    
    private var filteredAccountTypes: [Sideproject.ExternalAccountTypeDescription] {
        if let predicate = accountsViewConfiguration.predicate {
            return store.allKnownAccountTypeDescriptions.filter { account in
                (try? predicate.evaluate(account.accountType)) ?? false
            }
        } else {
            return Array(store.allKnownAccountTypeDescriptions)
        }
    }
}
