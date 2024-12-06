//
// Copyright (c) Vatsal Manot
//

import SideprojectCore
import SwiftUIX
import UniformTypeIdentifiers

public struct _DocumentListView: View {
    @EnvironmentObject var dataStore: Sideproject.FileStore
    
    @State public var selection: Set<Sideproject.File.ID> = []
    
    public var body: some View {
        List(selection: $selection) {
            ForEach(dataStore.documents) { document in
                Cell(document: document)
                    .contextMenu {                        
                        Button("Delete") {
                            try! dataStore.remove(document)
                        }
                    }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
        .contextMenu(forSelectionType: Sideproject.File.ID.self) { identifiers in
            Button("Delete \(identifiers.count) document(s)") {
                for identifier in identifiers {
                    if let document = dataStore[identifier] {
                        try? dataStore.remove(document)
                    }
                }
            }
        }
        .frame(minWidth: 256)
    }
    
    private func handleDrop(
        providers: [NSItemProvider]
    ) -> Bool {
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    Task { @MainActor in
                        try! dataStore.addDocument(url.unwrap())
                    }
                }
            }
        }
        return true
    }
}

extension _DocumentListView {
    public struct Cell: View {
        @ObservedObject var document: Sideproject.File
        
        public var body: some View {
            PresentationLink {
                _FileDetailView(document: document)
            } label: {
                HStack {
                    _DocumentLabelView(item: document)
                    
                    Spacer()
                    
                    Sideproject.DocumentIndexingIntervalDisclosure(item: document)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

extension _DocumentListView {
    public struct _DocumentLabelView: View {
        @ObservedObject public var item: Sideproject.File
        
        public var body: some View {
            EditableText(text: $item.metadata.displayName)
                .font(.title3)
                .foregroundColor(.primary)
        }
    }
}
