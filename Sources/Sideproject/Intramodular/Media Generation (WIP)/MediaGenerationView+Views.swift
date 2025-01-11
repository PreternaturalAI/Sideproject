//
//  MediaGenerationView+Views.swift
//  Sideproject
//
//  Created by Jared Davidson on 1/10/25.
//

import SwiftUI
import ElevenLabs
import AI
import Media

extension MediaGenerationView {
    var inputView: some View {
        inputModality.makeInputView(
            binding: $viewModel.currentInput,
            placeholderText: getPlaceholderText()
        )
    }
    
    private func getPlaceholderText() -> String {
        if case .video = mediaType, inputModality.inputType == URL.self {
            return "Describe how you want to transform the video..."
        }
        switch inputModality.inputType {
            case is String.Type:
                return "Enter your text here..."
            case is URL.Type:
                return "Drop files here"
            default:
                return ""
        }
    }
    
    var clientSelectionView: some View {
        VStack(alignment: .leading, spacing: 20) {
            if mediaType == .speech {
                Picker("Select Speech Client", selection: $viewModel.speechClient) {
                    ForEach(viewModel.availableSpeechClients, id: \.self) { client in
                        Text(client.displayName)
                            .tag(client as AnySpeechSynthesisRequestHandling?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            } else if mediaType == .video {
                Picker("Select Video Client", selection: $viewModel.videoClient) {
                    ForEach(viewModel.availableVideoClients, id: \.self) { client in
                        Text("Video Client")
                            .tag(client as AnyVideoGenerationRequestHandling?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
    
    var modelSelectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch mediaType {
                case .speech:
                    if !viewModel.availableVoices.isEmpty {
                        Picker("Voice", selection: $viewModel.selectedVoice) {
                            Text("Select a voice").tag(Optional<ElevenLabs.Voice.ID>.none)
                            ForEach(viewModel.availableVoices) { voice in
                                Text(voice.name)
                                    .tag(Optional(voice.id))
                            }
                        }
                    }
                    
                case .video:
                    if !viewModel.availableModels.isEmpty {
                        Picker("Model", selection: $viewModel.selectedVideoModel) {
                            Text("Select a model").tag(Optional<VideoModel.ID>.none)
                            ForEach(viewModel.availableModels) { model in
                                Text(model.name)
                                    .tag(Optional(model.id))
                            }
                        }
                    }
            }
        }
    }
    
    var promptInputView: some View {
        Group {
            if case .video = mediaType, inputModality.inputType == URL.self {
                inputModality.makeInputView(
                    binding: $viewModel.currentInput,
                    placeholderText: "Describe how you want to transform the video..."
                )
            } else {
                EmptyView()
            }
        }
    }
    
    var controlsView: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await viewModel.generate(
                        viewModel.speechClient?.base,
                        viewModel.videoClient?.base
                    )
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Text("Generate")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading || !isGenerateEnabled)
        }
    }
}
