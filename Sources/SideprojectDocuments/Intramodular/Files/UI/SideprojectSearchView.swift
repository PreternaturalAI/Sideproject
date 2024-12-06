//
// Copyright (c) Vatsal Manot
//

import SideprojectCore
import SwiftUIZ

public struct SideprojectSearchView: View {
    @StateObject var model: _SearchViewModel
    
    public init(store: Sideproject.FileStore) {
        self._model = .init(wrappedValue: _SearchViewModel(parent: store))
    }
    
    public var body: some View {
        XStack {
            VStack {
                SearchBar(text: $model.searchText)
                    .controlSize(.large)
                    .padding()
                
                searchResults
                    .modify {
                        #if os(macOS)
                        $0
                            .listStyle(.bordered)
                            .alternatingRowBackgrounds()
                        #endif
                    }
                    .padding()
            }
        }
    }
    
    var searchResults: some View {
        List {
            ForEach(model.searchResults ?? []) { result in
                Cell(result: result)
            }
            
            if model.searchResults.isNilOrEmpty {
                ContentUnavailableView(
                    "Search",
                    systemImage: "magnifyingglass",
                    description: Text("No Items")
                )
            }
        }
        .listStyle(.plain)
    }
    
    struct Cell: View {
        @EnvironmentObject var dataStore: Sideproject.FileStore
        
        let result: Sideproject.FileStore.SearchResult
        
        var body: some View {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    header
                    fragmentView
                }
            }
        }
        
        private var header: some View {
            HStack {
                PresentationLink {
                    _FileDetailView(document: result.fragment.document)
                } label: {
                    Text(result.fragment.document.metadata.displayName)
                        .font(.headline)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(String(format: "%.3f", result.score))
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .monospaced()
            }
        }
        
        @ViewBuilder
        private var fragmentView: some View {
            let fragment: Sideproject.File.RetrievedFragment = result.fragment
            
            LabeledContent {
                Text(fragment.rawText)
                    .font(.body)
                    .foregroundStyle(.secondary)
            } label: {
                Text("Retrieved Text")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            .padding(.extraSmall)
        }
    }
}
