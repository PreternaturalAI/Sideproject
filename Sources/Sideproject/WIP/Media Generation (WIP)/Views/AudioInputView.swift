//
//  AudioInputView.swift
//  Sideproject
//
//  Created by Jared Davidson on 1/14/25.
//

import SwiftUI
import Media
import LargeLanguageModels

public struct AudioInputView: View {
    @Binding var audioFile: AudioFile?
    let variants: AudioVariant
    
    public var body: some View {
        VStack(spacing: 16) {
            if let audioFile = audioFile {
                HStack {
                    Button {
                        self.audioFile = nil
                    } label: {
                        Image(systemName: .arrowCounterclockwiseCircle)
                    }
                }
                
                MediaFileView(file: audioFile)
            } else {
                if variants.contains(.fileDrop) {
                    FileDropView { files in
                        audioFile = files.first?.cast(to: AudioFile.self)
                    } content: { files in
                        EmptyView()
                    }
                    
                    if variants.contains(.recorder) {
                        Text("or")
                            .foregroundStyle(.secondary)
                    }
                }
                
                if variants.contains(.recorder) || variants.contains(.recorderWithTranscription) {
                    AudioRecorderView(configuration: AudioRecorderViewConfiguration(
                        enableSpeechRecognition: variants.contains(.recorderWithTranscription)
                    )) { recordedAudio in
                        audioFile = recordedAudio
                    } content: { media in
                        if let media {
                            AudioFileView(file: media)
                        }
                    }
                }
            }
        }
    }
}
