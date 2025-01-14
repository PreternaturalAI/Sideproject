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
    public var enableTranscription: Bool
    
    public init(
        description: String,
        enableTranscription: Bool = false
    ) {
        self.description = description
        self.enableTranscription = enableTranscription
    }
    
    public func makeInputView(inputBinding: Binding<AudioFile?>, placeholderText: String) -> AnyView {
        AnyView(
            CombinedAudioInputView(
                audioFile: inputBinding,
                enableTranscription: enableTranscription
            )
        )
    }
    
    public func validate(_ input: AudioFile?) -> Bool {
        input != nil
    }
}

private struct CombinedAudioInputView: View {
    @Binding var audioFile: AudioFile?
    let enableTranscription: Bool
    
    @State private var showingRecorder = false
    
    var body: some View {
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
                FileDropView { files in
                    audioFile = files.first?.cast(to: AudioFile.self)
                } content: { files in
                    EmptyView()
                }
                
                Text("or")
                    .foregroundStyle(.secondary)
                
                AudioRecorderView(configuration: AudioRecorderViewConfiguration(
                    enableSpeechRecognition: enableTranscription
                )) { recordedAudio in
                    audioFile = recordedAudio
                    showingRecorder = false
                } content: { media in
                    if let media {
                        AudioFileView(file: media)
                    }
                }
            }
        }
    }
}
