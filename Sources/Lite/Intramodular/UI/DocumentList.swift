//
// Copyright (c) Vatsal Manot
//

import SwiftUIX
import UniformTypeIdentifiers

public struct DocumentList: View {
    @EnvironmentObject var dataStore: LTDocumentStore
    
    @State public var selection: Set<LTDocument.ID> = []
    
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
        .contextMenu(forSelectionType: LTDocument.ID.self) { identifiers in
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

extension DocumentList {
    public struct Cell: View {
        @ObservedObject var document: LTDocument
        
        public var body: some View {
            PresentationLink {
                DocumentDetail(document: document)
            } label: {
                HStack {
                    DocumentLabel(item: document)
                    
                    Spacer()
                    
                    DocumentIndexingIntervalDisclosure(item: document)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

extension DocumentList {
    public struct DocumentLabel: View {
        @ObservedObject public var item: LTDocument
        
        public var body: some View {
            EditableText(text: $item.metadata.displayName)
                .font(.title3)
                .foregroundColor(.primary)
        }
    }
}
