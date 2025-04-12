//
//  InputModalityConfiguration.swift
//  Sideproject
//
//  Created by Jared Davidson on 4/12/25.
//

import SwiftUI

public protocol InputModalityConfiguration {
    associatedtype InputType
    var description: String { get }
    func makeInputView(inputBinding: Binding<InputType?>, placeholderText: String) -> AnyView
    func validate(_ input: InputType?) -> Bool
}
