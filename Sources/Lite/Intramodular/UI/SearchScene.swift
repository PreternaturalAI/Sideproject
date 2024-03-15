//
// Copyright (c) Vatsal Manot
//

import SwiftUIZ

public struct SearchScene: View {
    @StateObject var model: SearchSceneModel
    
    public init(store: LTDocumentStore) {
        self._model = .init(wrappedValue: SearchSceneModel(parent: store))
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
        @EnvironmentObject var dataStore: LTDocumentStore
        
        let result: LTDocumentStore.SearchResult
        
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
                    DocumentDetail(document: result.fragment.document)
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
            let fragment: LTDocument.RetrievedFragment = result.fragment
            
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
