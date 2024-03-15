//
// Copyright (c) Vatsal Manot
//

import SwiftUIX
import UniformTypeIdentifiers

struct DocumentsPicker: View {
    public let data: IdentifierIndexingArrayOf<LTDocument>
    
    @Binding public var selection: Set<LTDocument.ID>
    
    public var body: some View {
        Picker(selection: $selection) {
            ForEach(data) { item in
                DocumentLabel(document: item)
                    .tag(item.id)
            }
        } label: {
            Label {
                Text("Documents")
            } icon: {
                Image(systemName: .doc)
            }
        }
        .pickerStyle(.menu)
    }
}
