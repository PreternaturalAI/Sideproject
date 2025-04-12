//
//  MediaGenerationView+AnyInputModality.swift
//  Sideproject
//
//  Created by Jared Davidson on 4/12/25.
//

import SwiftUI

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
