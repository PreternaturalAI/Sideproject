//
// Copyright (c) Vatsal Manot
//

import SwiftUIX

public class SearchSceneModel: _CancellablesProviding, ObservableObject  {
    unowned let parent: LTDocumentStore
    
    @Published var searchText: String = ""
    @Published var searchResults: [LTDocumentStore.SearchResult]?
    
    public init(parent: LTDocumentStore) {
        self.parent = parent
        
        $searchText
            .handleOutput({ _ in self.searchResults = nil })
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink {
                self.search($0)
            }
            .store(in: self.cancellables)
    }
    
    private var searchTask: Task<Void, Error>? {
        didSet {
            searchTask?.cancel()
        }
    }
    
    public func search(_ text: String) {
        guard !text.isEmpty else {
            searchResults = []
            
            return
        }
        
        searchTask = Task { @MainActor in
            self.searchResults = try await parent.relevantMatches(for: text)
        }
    }
}
