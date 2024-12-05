//
// Copyright (c) Vatsal Manot
//

import SideprojectCore
import SwiftUIX
import UniformTypeIdentifiers

public struct _DocumentLabelView: View {
    public let document: Sideproject.File
    
    public var body: some View {
        Label {
            Text(document.metadata.displayName)
        } icon: {
            Image(systemName: .docFill)
        }
    }
}
