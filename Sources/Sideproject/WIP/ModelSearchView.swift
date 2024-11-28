//
//  SwiftUIView.swift
//  Sideproject
//
//  Created by Purav Manot on 20/11/24.
//

import SwiftUIX

public struct ModelSearchView: View {
    @StateObject private var modelStore = try! ModelStore()
    
    @State private var selectedAccount: Sideproject.ExternalAccount? = nil
    @State private var selectedTab: Tab = .downloaded
    @State private var text: String = ""
    @State private var isShowingAllDownloads: Bool = false
    
    public init() {
        
    }
    
    public var body: some View {
        NavigationSplitView {
            
        } detail: {
            SideprojectAccountsView()
                .background(Color.systemBackground)
        }
        .inspector(isPresented: .constant(true)) {
            Group {
                if let account = Sideproject.ExternalAccountStore.shared.accounts(for: .huggingFace).first {
                    ModelAssetsListView(account: account, selectedTab: $selectedTab, searchText: $text)
                }
            }
            .environmentObject(modelStore)
            .safeAreaInset(edge: .top) {
                VStack(spacing: 5) {
                    SearchBar(text: $text, onEditingChanged: { _ in }) {
                        guard let account = Sideproject.ExternalAccountStore.shared.accounts(for: .huggingFace).first else { return }
                        
                        Task {
                            do {
                                try await attemptDownload(for: text, using: account)
                            } catch {
                                print(error)
                                print(error.localizedDescription)
                            }
                        }
                    }
                    
                    Picker(selection: $selectedTab) {
                        ForEach(Tab.allCases, id: \.self) { tab in
                            Text(tab.description)
                                .tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 5)
            }
        }
    }
    
    @discardableResult
    func attemptDownload(for searchText: String, using account: Sideproject.ExternalAccount) async throws -> URL? {
        var urlString = searchText
        guard urlString.contains("huggingface") else { return nil }
        
        if !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }
        
        guard let url = URL(string: urlString) else { return nil }
        var components = url.pathComponents
        
        components.removeAll { $0 == "/" }
        let name = components.joined(separator: "/")
        
        return try await modelStore.download(modelNamed: name, using: account)
    }
}

#Preview {
    ModelSearchView()
}

extension ModelSearchView {
    struct ModelAssetsListView: View {
        @EnvironmentObject private var store: ModelStore
        
        var account: Sideproject.ExternalAccount
        
        @Binding var selectedTab: ModelSearchView.Tab
        @Binding var searchText: String

        var body: some View {
            List {
                DisclosureGroup("^[\(store.activeDownloads.count) downloads](inflect: true)") {
                    ForEach(store.activeDownloads) { model in
                        ModelDownloadRow(model: model)
                    }
                }
                
                switch selectedTab {
                    case .discover:
                        Section("Available models") {
                            ForEach(store.models.filter(searchFilter), id: \.id) { model in
                                HStack {
                                    Text(model.name)
                                    
                                    Spacer()
                                    
                                    Button {
                                        Task {
                                            do {
                                                let url = try await store.download(modelNamed: model.name, using: account)
                                                print(url)
                                            } catch {
                                                print(error)
                                                print(error.localizedDescription)
                                            }
                                            
                                        }
                                    } label: {
                                        Image(systemName: .arrowDown)
                                    }
                                    .disabled(model.isDownloading)
                                    .buttonStyle(.borderless)
                                }
                            }
                        }
                    case .downloaded:
                        Section("Your models") {
                            ForEach(store.models.filter { $0.state == .downloaded }.filter(searchFilter)) { model in
                                HStack {
                                    Text(model.displayName)
                                    
                                    Button {
                                        store.delete(model.id)
                                    } label: {
                                        Image(systemName: .trash)
                                    }
                                }
                            }
                        }
                }
            }
        }
        
        func searchFilter(model: ModelStore.Model) -> Bool {
            let searchText = searchText.trimmingWhitespaceAndNewlines()
            guard !searchText.isEmpty else { return true }
            
            return model.name.localizedCaseInsensitiveContains(searchText)
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
