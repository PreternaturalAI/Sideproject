//
// Copyright (c) Vatsal Manot
//

import Cataphyl
import Merge
import SideprojectCore
import SwiftUIX
import SwiftUIZ
import UniformTypeIdentifiers

extension Sideproject {
    public struct DocumentsView: View {
        @EnvironmentObject var dataStore: Sideproject.FileStore
        
        public init() {
            
        }
        
        public var body: some View {
            VStack {
                HStack {
                    _DocumentListView()
                    
                    SideprojectSearchView(store: dataStore)
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
                    try await dataStore.embedPendingDocuments()
                } label: { (status: ObservableTaskStatus) in
                    indexButton(status: status)
                }
            }
        }
        
        @ViewBuilder
        private func indexButton(status: ObservableTaskStatus<Void, Swift.Error>) -> some View {
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
            .animation(.default, value: ObservableTaskStatusDescription(status))
        }
    }
}

extension Sideproject {
    public struct DocumentIndexingIntervalDisclosure: View {
        @ObservedObject var item: Sideproject.File
        
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
}
