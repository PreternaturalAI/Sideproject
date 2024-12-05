//
// Copyright (c) Vatsal Manot
//

import SideprojectCore
import Merge
import SwiftUIX

public class _SearchViewModel: _CancellablesProviding, ObservableObject  {
    unowned let parent: Sideproject.FileStore
    
    @Published var searchText: String = ""
    @Published var searchResults: [Sideproject.FileStore.SearchResult]?
    
    public init(parent: Sideproject.FileStore) {
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
