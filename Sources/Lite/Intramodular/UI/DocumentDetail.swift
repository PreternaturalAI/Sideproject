//
// Copyright (c) Vatsal Manot
//

import Cataphyl
import SwiftUIX

public struct DocumentDetail: View {
    @ObservedObject public var document: LTDocument
    
    public init(document: LTDocument) {
        self.document = document
    }
    
    public var body: some View {
        NavigationStack {
            Group {
                editableText
            }
            .toolbar {
                ToolbarItemGroup {
                    DocumentLabel(document: document)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
        }
        .frame(
            minWidth: 512,
            idealWidth: 768,
            maxWidth: 768,
            minHeight: 512,
            maxHeight: 768
        )
    }
    
    private var editableText: some View {
        ScrollView {
            Group {
                if document.rawText != nil {
                    TextEditor(
                        text: $document.rawText.withDefaultValue(PlainTextDocument(text: "")).text
                    )
                } else {
                    ContentUnavailableView("Text Unavailable", image: "textformat")
                }
            }
            .font(.body)
            .padding(.large)
        }
        ._scrollBounceBehaviorBasedOnSizeIfAvailable()
    }
}
