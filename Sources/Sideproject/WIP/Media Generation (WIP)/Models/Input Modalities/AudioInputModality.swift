//
//  AudioInputModality.swift
//  Sideproject
//
//  Created by Jared Davidson on 1/14/25.
//

import Media
import SwiftUI

public struct AudioInputModality: InputModalityConfiguration {
    public typealias InputType = AudioFile
    
    public var description: String
    public var variants: AudioVariant
    
    public init(
        description: String,
        variants: AudioVariant = .all
    ) {
        self.description = description
        self.variants = variants
    }
    
    public func makeInputView(inputBinding: Binding<AudioFile?>, placeholderText: String) -> AnyView {
        AnyView(
            AudioInputView(
                audioFile: inputBinding,
                variants: variants
            )
        )
    }
    
    public func validate(_ input: AudioFile?) -> Bool {
        input != nil
    }
}
