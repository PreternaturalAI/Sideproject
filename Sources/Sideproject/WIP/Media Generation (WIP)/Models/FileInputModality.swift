//
//  FileInputModality.swift
//  Sideproject
//
//  Created by Jared Davidson on 1/10/25.
//

import Media
import SwiftUI

public struct FileInputModality<T: MediaFile>: InputModalityConfiguration {
    public typealias InputType = T
    
    public var description: String
    
    public init(description: String) {
        self.description = description
    }
    
    public func makeInputView(inputBinding: Binding<T?>, placeholderText: String) -> AnyView {
        AnyView(
            FileDropView { files in
                inputBinding.wrappedValue = files.first?.cast(to: T.self)
            } content: { files in
                if !files.isEmpty {
                    MediaFileListView(files)
                }
            }
        )
    }
    
    public func validate(_ input: T?) -> Bool {
        input != nil
    }
}
