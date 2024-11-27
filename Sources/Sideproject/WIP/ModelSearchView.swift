//
//  SwiftUIView.swift
//  Sideproject
//
//  Created by Purav Manot on 20/11/24.
//

import SwiftUIX

public struct ModelSearchView: View {
    @State private var selectedAccount: Sideproject.ExternalAccount? = nil
    @State private var selectedTab: Tab = .downloaded
    @State private var text: String = ""
    
    public init() {
        
    }
    
    public var body: some View {
        NavigationSplitView {
            SideprojectAccountsView()
                .background(Color.systemBackground)
        } detail: {
            if let account = Sideproject.ExternalAccountStore.shared.accounts(for: .huggingFace).first {
                switch selectedTab {
                    case .discover:
                        ModelListView(account: account)
                    case .downloaded:
                        ModelAssetsDetailView(account: account)
                }
            }
        }
        .searchable(text: $text, placement: .toolbar)
        .onSubmit(of: .search) {
            
        }
        .toolbar {
            Picker(selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.description)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    func downloadModel() {
        print("downloading model")
    }
}

#Preview {
    ModelSearchView()
}

extension ModelSearchView {
    struct ModelListView: View {
        @StateObject var store: ModelStore
        @State private var text: String = ""
        
        init(account: Sideproject.ExternalAccount) {
            self._store = StateObject(wrappedValue: try! ModelStore(from: account))
            
        }
        
        var body: some View {
            List {
                Section("Models") {
                    ForEach(store.models, id: \.id) { model in
                        HStack {
                            Text(model.name)
                            
                            Spacer()

                            Button {
                                Task {
                                    let url = try await store.download(modelNamed: model.name)
                                }
                            } label: {
                                Image(systemName: .arrowDown)
                            }
                            .disabled(model.isDownloading)
                            .buttonStyle(.borderless)
                        }
                        
                    }
                }
                
                
                Section("Active downloads") {
                    ForEach(store.models.filter({ return $0.isDownloading }), id: \ModelStore.Model.id) { (model: ModelStore.Model) in
                        Group {
                            Text(model.name)
                            
                            switch model.state {
                                case .downloading(let progress):
                                    ProgressView(value: progress)
                                        .progressViewStyle(.linear)
                                        .padding(.horizontal, 5)
                                default:
                                    EmptyView()
                            }
                        }
                    }
                }
                 
            }
        }
    }
    
    struct ModelAssetsDiscoverView: View {
        var body: some View {
            Text("_")
        }
    }
    
    struct ModelAssetsDetailView: View {
        @StateObject var store: ModelStore
        
        init(account: Sideproject.ExternalAccount) {
            self._store = StateObject(wrappedValue: try! ModelStore(from: account))
            
        }
        
        var body: some View {
            List {
                Section("Your models") {
                    ForEach(store.models) { model in
                        Text(model.displayName)
                    }
                }
            }
        }
    }
}

extension ModelSearchView {
    enum Tab {
        case discover
        case downloaded
    }
}

// MARK: - Conformances

extension ModelSearchView.Tab: CustomStringConvertible, CaseIterable {
    var description: String {
        switch self {
            case .discover: "Discover"
            case .downloaded: "Downloaded"
        }
    }
}
