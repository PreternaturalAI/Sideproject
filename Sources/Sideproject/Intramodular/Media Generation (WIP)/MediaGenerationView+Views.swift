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
                        Text("Video Client") // Customize this display
                            .tag(client as AnyVideoGenerationRequestHandling?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
    
    var inputView: some View {
        Group {
            switch viewModel.inputModality {
                case .text:
                    TextEditor(text: $viewModel.inputText)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2))
                        )
                        .overlay(
                            Group {
                                if viewModel.inputText.isEmpty {
                                    Text("Enter your text here...")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 4)
                                }
                            },
                            alignment: .topLeading
                        )
                case .audio, .image, .video:
                    FileDropView { files in
                        switch viewModel.inputModality {
                            case .audio:
                                viewModel.selectedAudioFile = files.first?.audioFile
                            case .image:
                                viewModel.selectedImage = files.first?.imageFile
                            case .video:
                                viewModel.selectedVideo = files.first?.videoFile
                            default:
                                break
                        }
                    } content: { files in
                        if !files.isEmpty {
                            MediaFileListView(files)
                        }
                    }
            }
        }
    }
    
    // MARK: - Model Selection View
    var modelSelectionView: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            switch viewModel.mediaType {
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter Prompt")
                .font(.headline)
            
            TextEditor(text: $viewModel.inputText)
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2))
                )
                .overlay(
                    Group {
                        if viewModel.inputText.isEmpty {
                            Text("Describe how you want to transform the video...")
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                        }
                    },
                    alignment: .topLeading
                )
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
