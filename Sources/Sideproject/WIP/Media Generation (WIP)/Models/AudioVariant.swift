//
//  AudioVariant.swift
//  Sideproject
//
//  Created by Jared Davidson on 4/12/25.
//

import SwiftUI

public struct AudioVariant: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let fileDrop = AudioVariant(rawValue: 1 << 0)
    public static let recorder = AudioVariant(rawValue: 1 << 1)
    public static let recorderWithTranscription = AudioVariant(rawValue: 1 << 2)
    
    public static let all: AudioVariant = [.fileDrop, .recorder, .recorderWithTranscription]
}
