//
//  MediaGenerationView.swift
//  Sideproject
//
//  Created by Jared Davidson on 1/10/25.
//

import SwiftUI
import ElevenLabs
import SwallowUI
import Media
import AVFoundation
import SideprojectCore
import AI
import Runtime

public enum MediaType {
    case speech
    case video
}

public enum InputModality: String {
    case text
    case audio
    case image
    case video
    
    var description: String {
        rawValue.capitalized
    }
}

public struct MediaGenerationView: View {
    public struct Configuration: Equatable {
        public static func == (lhs: MediaGenerationView.Configuration, rhs: MediaGenerationView.Configuration) -> Bool {
            return lhs.textToSpeechModel == rhs.textToSpeechModel &&
            lhs.speechToSpeechModel == rhs.speechToSpeechModel
        }
        
        public var textToSpeechModel: String
        public var speechToSpeechModel: String
        public var voiceSettings: AbstractVoiceSettings
        public var videoSettings: VideoGenerationSettings
        
        public init(
            textToSpeechModel: String = ElevenLabs.Model.EnglishV1.rawValue,
            speechToSpeechModel: String = ElevenLabs.Model.EnglishSTSV2.rawValue,
            voiceSettings: AbstractVoiceSettings = .init(),
            videoSettings: VideoGenerationSettings = .init()
        ) {
            self.textToSpeechModel = textToSpeechModel
            self.speechToSpeechModel = speechToSpeechModel
            self.voiceSettings = voiceSettings
            self.videoSettings = videoSettings
        }
    }
    
    private let mediaType: MediaType
    private let inputModality: InputModality
    private var configuration: Configuration
    private let onComplete: ((AnyMediaFile) -> Void)?
    
    @StateObject private var viewModel: GenerationViewModel
    
    @State var speechClient: AnySpeechSynthesisRequestHandling? = nil
    @State var videoClient: AnyVideoGenerationRequestHandling? = nil
    
    public init(
        mediaType: MediaType,
        inputModality: InputModality,
        configuration: Configuration = .init(),
        onComplete: ((AnyMediaFile) -> Void)? = nil
    ) {
        self.mediaType = mediaType
        self.inputModality = inputModality
        self.configuration = configuration
        self.onComplete = onComplete
        
        let viewModel = GenerationViewModel(
            mediaType: mediaType,
            inputModality: inputModality,
            configuration: configuration,
            onComplete: onComplete
        )
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            InputView(viewModel: viewModel)
            
            ClientSelectionView(
                mediaType: mediaType,
                viewModel: viewModel
            )
            
            ModelSelectionView(viewModel: viewModel)
            
            if case .video = viewModel.mediaType, case .video = viewModel.inputModality {
                PromptInputView(inputText: $viewModel.inputText)
            }
            
            ControlsView(viewModel: viewModel)
            
            if viewModel.onComplete == nil {
                GeneratedFilesView(files: viewModel.generatedFiles)
            }
        }
        .padding()
        .task {
            Task {
                await loadClients()
                await viewModel.loadResources(
                    viewModel.speechClient?.base(),
                    viewModel.videoClient?.base()
                )
            }
        }
    }
    
    private func loadClients() async {
        do {
            let services = try await Sideproject.shared.services
            
            print(services)
            
            self.viewModel.availableSpeechClients = services.compactMap { service in
                let originalService = service
                if let client = service as? (any SpeechSynthesisRequestHandling) {
                    return AnySpeechSynthesisRequestHandling(client, service: originalService)
                }
                return nil
            }
            
            self.viewModel.availableVideoClients = services.compactMap { service in
                let originalService = service
                
                if let client = service as? (any VideoGenerationRequestHandling) {
                    return AnyVideoGenerationRequestHandling(client, service: originalService)
                }
                return nil
            }
            
            self.viewModel.speechClient = self.viewModel.availableSpeechClients.first
            self.viewModel.videoClient = self.viewModel.availableVideoClients.first
        } catch {
            print("Error loading clients: \(error)")
        }
    }
}

struct ClientSelectionView: View {
    let mediaType: MediaType
    
    @ObservedObject var viewModel: GenerationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if mediaType == .speech {
                Picker("Select Speech Client", selection: $viewModel.speechClient) {
                    ForEach(viewModel.availableSpeechClients, id: \.self) { client in
                        Text("Speech Client \(client.hashValue)") // Customize this display
                            .tag(client as AnySpeechSynthesisRequestHandling?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            } else if mediaType == .video {
                Picker("Select Video Client", selection: $viewModel.videoClient) {
                    ForEach(viewModel.availableVideoClients, id: \.self) { client in
                        Text("Video Client \(client.hashValue)") // Customize this display
                            .tag(client as AnyVideoGenerationRequestHandling?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
}

struct InputView: View {
    @ObservedObject var viewModel: GenerationViewModel
    
    var body: some View {
        Group {
            switch viewModel.inputModality {
                case .text:
                    TextInputView(text: $viewModel.inputText)
                case .audio, .image, .video:
                    MediaInputView(viewModel: viewModel)
            }
        }
    }
}

struct TextInputView: View {
    @Binding var text: String
    
    var body: some View {
        TextEditor(text: $text)
            .frame(height: 100)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2))
            )
            .overlay(
                Group {
                    if text.isEmpty {
                        Text("Enter your text here...")
                            .foregroundColor(.gray)
                            .padding(.leading, 4)
                    }
                },
                alignment: .topLeading
            )
    }
}

struct MediaInputView: View {
    @ObservedObject var viewModel: GenerationViewModel
    
    var body: some View {
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

struct ResourceLoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading resources...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ResourceErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text("Failed to load resources")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button("Try Again", action: retryAction)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

enum GenerationError: Error {
    case invalidVideoData
    case clientNotAvailable
    case resourceLoadingFailed
}


// MARK: - Model Selection View
struct ModelSelectionView: View {
    @ObservedObject var viewModel: GenerationViewModel
    
    var body: some View {
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
}

// MARK: - Prompt Input View
struct PromptInputView: View {
    @Binding var inputText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter Prompt")
                .font(.headline)
            
            TextEditor(text: $inputText)
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2))
                )
                .overlay(
                    Group {
                        if inputText.isEmpty {
                            Text("Describe how you want to transform the video...")
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                        }
                    },
                    alignment: .topLeading
                )
        }
    }
}

// MARK: - Controls View
struct ControlsView: View {
    @ObservedObject var viewModel: GenerationViewModel
    
    @Environment(\.speechSynthesizer) var speechClient
    @Environment(\.videoClient) var videoClient
    
    var body: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await viewModel.generate(
                        speechClient,
                        videoClient
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
    
    private var isGenerateEnabled: Bool {
        switch viewModel.mediaType {
            case .speech:
                switch viewModel.inputModality {
                    case .text:
                        return !viewModel.inputText.isEmpty && viewModel.selectedVoice != nil
                    case .audio:
                        return viewModel.selectedAudioFile != nil && viewModel.selectedVoice != nil
                    default:
                        return false
                }
            case .video:
                switch viewModel.inputModality {
                    case .text:
                        return !viewModel.inputText.isEmpty && viewModel.selectedVideoModel != nil
                    case .image:
                        return viewModel.selectedImage != nil && viewModel.selectedVideoModel != nil
                    case .video:
                        return viewModel.selectedVideo != nil && viewModel.selectedVideoModel != nil
                    default:
                        return false
                }
        }
    }
}

// MARK: - Generated Files View
struct GeneratedFilesView: View {
    let files: [AnyMediaFile]
    
    var body: some View {
        if !files.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Generated Files")
                    .font(.headline)
                
                MediaFileListView(files)
            }
        }
    }
}
