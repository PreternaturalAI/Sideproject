//
//  SwiftUIView.swift
//  Sideproject
//
//  Created by Purav Manot on 20/11/24.
//

import SwiftUIX

public struct ModelSearchView: View {
    @StateObject private var modelStore: ModelStore = ModelStore()
    
    @State private var selectedTab: Tab = .downloaded
    @State private var searchText: String = ""
    @State private var isShowingAllDownloads: Bool = false
    
    public init() {
        
    }
    
    public var body: some View {
        NavigationSplitView {
            SideprojectAccountsView()
                .background(.black)
        } detail: {
            TableView(selectedTab: $selectedTab, searchText: $searchText)
        }
        .environmentObject(modelStore)
        .environmentObject(Sideproject.ExternalAccountStore.shared)
        .searchable(text: $searchText, placement: .toolbar)
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Picker(selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.description)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .onSubmit(of: .search) {
            Task {
                do {
                    try await attemptDownload(for: searchText, using: Sideproject.ExternalAccountStore.shared)
                } catch {
                    print(error)
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    @discardableResult
    func attemptDownload(for searchText: String, using accountStore: Sideproject.ExternalAccountStore) async throws -> URL? {
        var urlString = searchText
        guard urlString.contains("huggingface") else { return nil }
        
        if !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }
        
        guard let url = URL(string: urlString) else { return nil }
        var components = url.pathComponents
        
        components.removeAll { $0 == "/" }
        let name = components.joined(separator: "/")
        
        if !modelStore.models.map({ $0.name }).contains(name) {
            return nil
        }
        
        return try await modelStore.download(modelNamed: name, using: accountStore)
    }
}

#Preview {
    ModelSearchView()
}


extension ModelSearchView {
    enum Tab {
        case discover
        case downloaded
        
        var keyPath: KeyPath<ModelStore, [ModelStore.Model]> {
            switch self {
                case .discover: return \ModelStore.models
                case .downloaded: return \ModelStore.downloadedModels
            }
        }
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
