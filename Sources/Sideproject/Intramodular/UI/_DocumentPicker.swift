//
// Copyright (c) Vatsal Manot
//

import SwiftUIX
import UniformTypeIdentifiers

struct _DocumentPicker: View {
    public let data: IdentifierIndexingArrayOf<Sideproject.File>
    
    @Binding public var selection: Set<Sideproject.File.ID>
    
    public var body: some View {
        Picker(selection: $selection) {
            ForEach(data) { item in
                _DocumentLabelView(document: item)
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
