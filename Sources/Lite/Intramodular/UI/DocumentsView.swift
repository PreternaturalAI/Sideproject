//
// Copyright (c) Vatsal Manot
//

import SwiftUIZ
import UniformTypeIdentifiers

public struct LTDocumentsView: View {
    @EnvironmentObject var dataStore: LTDocumentStore
        
    public init() {
        
    }
    
    public var body: some View {
        VStack {
            HStack {
                DocumentList()
                
                SearchScene(store: dataStore)
            }
            
            VStack {
                HStack {
                    Text("Embeddings File:")
                    
                    #if os(macOS)
                    PathControl(url: try! dataStore.$textEmbeddings.url)
                    #endif
                }
                
                HStack {
                    Text("Documents File:")
                    
                    #if os(macOS)
                    PathControl(url: try! dataStore.$documents.url)
                    #endif
                }
            }
        }
        .modify {
#if os(macOS)
            $0.listStyle(.inset(alternatesRowBackgrounds: true))
#endif
        }
        .toolbar {
            TaskButton {
                try await dataStore.embedAllDocuments()
            } label: { (status: TaskStatus) in
                indexButton(status: status)
            }
        }
    }
    
    @ViewBuilder
    private func indexButton(status: TaskStatus<Void, Error>) -> some View {
        Label {
            Text("Index")
        } icon: {
            Group {
                if status == .active {
                    ActivityIndicator()
                } else {
                    Image(systemName: "chevron.forward.to.line")
                }
            }
        }
        .font(.headline)
        .labelStyle(.titleAndIcon)
        .animation(.default, value: TaskStatusDescription(status))
    }
}

public struct DocumentIndexingIntervalDisclosure: View {
    @ObservedObject var item: LTDocument
    
    public var body: some View {
        Group {
            if let indexingInterval = item.indexingInterval {
                switch indexingInterval {
                    case .assessing:
                        ProgressView()
                            .controlSize(.small)
                            .progressViewStyle(.circular)
                    case .preparing:
                        _UnimplementedView()
                    case .indexing:
                        Text("Indexing")
                }
            } else {
                if item.rawText != nil {
                    Text("Indexed")
                        .foregroundColor(.secondary)
                } else {
                    indexButton
                }
            }
        }
        .font(.subheadline.smallCaps())
        .textCase(.uppercase)
    }
    
    private var indexButton: some View {
        Button("Index") {
            Task {
                try await item.ingest()
            }
        }
        .foregroundColor(.secondary)
        .controlSize(.regular)
    }
}
