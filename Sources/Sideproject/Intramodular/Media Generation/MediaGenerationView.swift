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
import AI

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

// MARK: - Main View
struct GenerateMediaView: View {
    public struct Configuration: Equatable {
        public static func == (lhs: GenerateMediaView.Configuration, rhs: GenerateMediaView.Configuration) -> Bool {
            return lhs.textToSpeechModel == rhs.textToSpeechModel &&
            lhs.speechToSpeechModel == rhs.speechToSpeechModel
        }
        
        public var textToSpeechModel: String
        public var speechToSpeechModel: String
        public var voiceSettings: AbstractVoiceSettings
        public var videoSettings: VideoGenerationSettings
        public var speechClient: (any SpeechSynthesisRequestHandling)?
        public var videoClient: (any VideoGenerationRequestHandling)?
        
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
    
    init(
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if viewModel.isLoadingResources {
                ResourceLoadingView()
            } else if let error = viewModel.loadingError {
                ResourceErrorView(error: error) {
                    Task { await viewModel.loadResources() }
                }
            } else {
                GenerationContentView(viewModel: viewModel)
            }
        }
        .padding()
        .task {
            await viewModel.loadResources()
        }
    }
}

// MARK: - View Model
final class GenerationViewModel: ObservableObject {
    @Published var availableVoices: [ElevenLabs.Voice] = []
    @Published var availableModels: [VideoModel] = []
    @Published var isLoadingResources = false
    @Published var loadingError: Error?
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var showingPreview = false
    @Published var selectedVoice: ElevenLabs.Voice.ID?
    @Published var selectedAudioFile: AudioFile?
    @Published var generatedAudioFile: AudioFile?
    @Published var selectedVideoModel: VideoModel.ID?
    @Published var selectedImage: ImageFile?
    @Published var selectedVideo: VideoFile?
    @Published var generatedVideoFile: VideoFile?
    @Published var generatedFiles: [AnyMediaFile] = []
    
    internal let mediaType: MediaType
    internal let inputModality: InputModality
    internal var configuration: GenerateMediaView.Configuration
    internal let onComplete: ((AnyMediaFile) -> Void)?
    
    init(
        mediaType: MediaType,
        inputModality: InputModality,
        configuration: GenerateMediaView.Configuration,
        onComplete: ((AnyMediaFile) -> Void)?
    ) {
        self.mediaType = mediaType
        self.inputModality = inputModality
        self.configuration = configuration
        self.onComplete = onComplete
    }
    
    @MainActor
    internal func loadResources() async {
        isLoadingResources = true
        loadingError = nil
        
        do {
            switch mediaType {
                case .speech:
                    availableVoices = try await configuration.speechClient?.availableVoices() ?? []
                    configuration.voiceSettings = .init()
                    
                case .video:
                    availableModels = try await configuration.videoClient?.availableModels() ?? []
                    configuration.videoSettings = .init()
            }
        } catch {
            loadingError = error
        }
        
        isLoadingResources = false
    }
    
    @MainActor
    internal func generate() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            switch mediaType {
                case .speech:
                    try await generateSpeech()
                case .video:
                    try await generateVideo()
            }
        } catch {
            print("Error generating media: \(error)")
        }
    }
    
    @MainActor
    private func generateSpeech() async throws {
        guard let speechClient = configuration.speechClient else {
            throw GenerationError.clientNotAvailable
        }
        
        let audioData: Data?
        
        switch inputModality {
            case .audio:
                audioData = try await convertSpeechToSpeech()
            case .text:
                audioData = try await convertTextToSpeech()
            default:
                return
        }
        
        guard let audioData = audioData else { return }
        
        let name = switch inputModality {
            case .audio: selectedAudioFile?.name ?? "Converted Audio"
            case .text: inputText.prefix(30).trimmingCharacters(in: .whitespacesAndNewlines)
            default: "Generated Audio"
        }
        
        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        try audioData.write(to: temporaryURL)
        
        let audioFile = try await AudioFile(url: temporaryURL)
        generatedAudioFile = audioFile
        
        if let audioFile = generatedAudioFile {
            let mediaFile = AnyMediaFile(audioFile)
            if let onComplete = onComplete {
                onComplete(mediaFile)
            } else {
                generatedFiles.append(mediaFile)
            }
        }
    }
    
    @MainActor
    private func generateVideo() async throws {
        guard let videoClient = configuration.videoClient else {
            throw GenerationError.clientNotAvailable
        }
        
        guard let modelID = selectedVideoModel,
              let model = availableModels.first(where: { $0.id == modelID }) else { return }
        
        let videoData: Data?
        
        switch inputModality {
            case .text:
                videoData = try await videoClient.textToVideo(
                    text: inputText,
                    model: model,
                    settings: configuration.videoSettings
                )
            case .image:
                guard let imageURL = selectedImage?.url else { return }
                videoData = try await videoClient.imageToVideo(
                    imageURL: imageURL,
                    model: model,
                    settings: configuration.videoSettings
                )
            case .video:
                guard let videoURL = selectedVideo?.url else { return }
                videoData = try await videoClient.videoToVideo(
                    videoURL: videoURL,
                    prompt: inputText,
                    model: model,
                    settings: configuration.videoSettings
                )
            default:
                return
        }
        
        guard let videoData = videoData else {
            throw GenerationError.invalidVideoData
        }
        
        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        try videoData.write(to: temporaryURL)
        
        let videoFile = try await VideoFile(url: temporaryURL)
        generatedVideoFile = videoFile
        
        let mediaFile = AnyMediaFile(videoFile)
        if let onComplete = onComplete {
            onComplete(mediaFile)
        } else {
            generatedFiles.append(mediaFile)
        }
        
        showingPreview = true
    }
    
    @MainActor
    private func convertSpeechToSpeech() async throws -> Data? {
        guard let voiceID = selectedVoice,
              let voice = availableVoices.first(where: { $0.id == voiceID }),
              let audioFile = selectedAudioFile else {
            return nil
        }
        
        return try await configuration.speechClient?.speechToSpeech(
            inputAudioURL: audioFile.url,
            voiceID: voice.voiceID,
            voiceSettings: ElevenLabs.VoiceSettings(settings: configuration.voiceSettings),
            model: .init(rawValue: configuration.speechToSpeechModel)! // FIXME: - Will Crash
        )
    }
    
    @MainActor
    private func convertTextToSpeech() async throws -> Data? {
        guard let voiceID = selectedVoice,
              !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        
        return try await configuration.speechClient?.speech(
            for: inputText,
            voiceID: voiceID.id.rawValue,
            voiceSettings: ElevenLabs.VoiceSettings(settings: configuration.voiceSettings), //FIXME: - This should just accept AbstractVoiceSettings
            model: .init(rawValue: configuration.textToSpeechModel)! // FIXME: - Will Crash
        )
    }
}

// MARK: - Content Views
struct GenerationContentView: View {
    @ObservedObject var viewModel: GenerationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HeaderView(mediaType: viewModel.mediaType)
            
            InputView(viewModel: viewModel)
            
            ModelSelectionView(viewModel: viewModel)
            
            if case .video = viewModel.mediaType, case .video = viewModel.inputModality {
                PromptInputView(inputText: $viewModel.inputText)
            }
            
            ControlsView(viewModel: viewModel)
            
            if viewModel.onComplete == nil {
                GeneratedFilesView(files: viewModel.generatedFiles)
            }
        }
    }
}

// MARK: - Supporting Views
struct HeaderView: View {
    let mediaType: MediaType
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(mediaType == .speech ? "Speech Synthesis" : "Video Generation")
                .font(.title)
            
            Text(mediaType == .speech ?
                 "Generate realistic speech using advanced AI technology" :
                    "Create stunning videos using AI")
            .foregroundColor(.secondary)
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
                    Text("Select Voice")
                        .font(.headline)
                    
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
                    Text("Select Model")
                        .font(.headline)
                    
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
    
    var body: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await viewModel.generate()
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
