//
// Copyright (c) Vatsal Manot
//

import SwiftUIX
import UniformTypeIdentifiers

public struct DocumentLabel: View {
    public let document: LTDocument
    
    public var body: some View {
        Label {
            Text(document.metadata.displayName)
        } icon: {
            Image(systemName: .docFill)
        }
    }
}
