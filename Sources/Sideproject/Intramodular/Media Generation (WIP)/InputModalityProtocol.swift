//
//  InputModalityProtocol.swift
//  Sideproject
//
//  Created by Jared Davidson on 1/10/25.
//

import SwiftUI
import AVFoundation
import Media

public enum InputModality {
    public static let text = AnyInputModality(TextInputModality())
    public static let audio = AnyInputModality(AudioInputModality(description: "Audio"))
    public static let image = AnyInputModality(FileInputModality<ImageFile>(description: "Image"))
    public static let video = AnyInputModality(FileInputModality<VideoFile>(description: "Video"))
}

extension AnyInputModality {
    public static var text: Self { InputModality.text }
    public static var audio: Self { InputModality.audio }
    public static var image: Self { InputModality.image }
    public static var video: Self { InputModality.video }
}

extension MediaGenerationView {
    public func inputModality(_ modality: AnyInputModality) -> Self {
        MediaGenerationView(
            mediaType: self.mediaType,
            inputModality: modality,
            configuration: self.configuration,
            onComplete: self.onComplete
        )
    }
}

public struct AnyInputModality {
    private let _description: String
    private let _makeInputView: (Binding<Any?>, String) -> AnyView
    private let _validate: (Any?) -> Bool
    private let _type: Any.Type
    
    public var description: String { _description }
    public var inputType: Any.Type { _type }
    
    public init<T: InputModalityConfiguration>(_ modality: T) {
        self._description = modality.description
        self._type = T.InputType.self
        self._makeInputView = { binding, placeholder in
            let typedBinding = Binding<T.InputType?>(
                get: { binding.wrappedValue as? T.InputType },
                set: { binding.wrappedValue = $0 }
            )
            return modality.makeInputView(inputBinding: typedBinding, placeholderText: placeholder)
        }
        self._validate = { input in
            guard let typedInput = input as? T.InputType else { return false }
            return modality.validate(typedInput)
        }
    }
    
    public func makeInputView(binding: Binding<Any?>, placeholderText: String = "") -> AnyView {
        _makeInputView(binding, placeholderText)
    }
    
    public func validate(_ input: Any?) -> Bool {
        _validate(input)
    }
}

public protocol InputModalityConfiguration {
    associatedtype InputType
    var description: String { get }
    func makeInputView(inputBinding: Binding<InputType?>, placeholderText: String) -> AnyView
    func validate(_ input: InputType?) -> Bool
}
