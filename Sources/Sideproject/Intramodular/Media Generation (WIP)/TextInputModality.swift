//
//  TextInputModality.swift
//  Sideproject
//
//  Created by Jared Davidson on 1/10/25.
//

import SwiftUI

public struct TextInputModality: InputModalityConfiguration {
    public typealias InputType = String
    
    public var description: String { "Text" }
    
    public func makeInputView(inputBinding: Binding<String?>, placeholderText: String) -> AnyView {
        AnyView(
            TextEditor(text: Binding(
                get: { inputBinding.wrappedValue ?? "" },
                set: { inputBinding.wrappedValue = $0.isEmpty ? nil : $0 }
            ))
            .frame(height: 100)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2))
            )
            .overlay(
                Group {
                    if inputBinding.wrappedValue?.isEmpty ?? true {
                        Text(placeholderText)
                            .foregroundColor(.gray)
                            .padding(.leading, 4)
                    }
                },
                alignment: .topLeading
            )
        )
    }
    
    public func validate(_ input: String?) -> Bool {
        !(input ?? "").isEmpty
    }
}
