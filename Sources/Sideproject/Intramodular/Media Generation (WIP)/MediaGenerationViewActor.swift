//
//  MediaGenerationViewActor.swift
//  Sideproject
//
//  Created by Jared Davidson on 1/10/25.
//

import ElevenLabs
import AI
import Media
import SwiftUI
import SwiftUIX

final class GenerationViewModel: ObservableObject {
    @Published var availableVoices: [ElevenLabs.Voice] = []
    @Published var availableModels: [VideoModel] = []
    @Published var currentInput: Any?
    @Published var isLoading = false
    @Published var selectedVoice: ElevenLabs.Voice.ID?
    @Published var generatedFile: AnyMediaFile?
    @Published var selectedVideoModel: VideoModel.ID?
    @Published var speechClient: AnySpeechSynthesisRequestHandling?
    @Published var videoClient: AnyVideoGenerationRequestHandling?
    @Published var availableSpeechClients: [AnySpeechSynthesisRequestHandling] = []
    @Published var availableVideoClients: [AnyVideoGenerationRequestHandling] = []
    
    internal let mediaType: MediaType
    internal let inputModality: AnyInputModality
    internal var configuration: MediaGenerationView.Configuration
    internal let onComplete: ((AnyMediaFile) -> Void)?
    
    init(
        mediaType: MediaType,
        inputModality: AnyInputModality,
        configuration: MediaGenerationView.Configuration,
        onComplete: ((AnyMediaFile) -> Void)?
    ) {
        self.mediaType = mediaType
        self.inputModality = inputModality
        self.configuration = configuration
        self.onComplete = onComplete
    }
    
    @MainActor
    internal func loadResources(
        _ speechClient: (any SpeechSynthesisRequestHandling)?,
        _ videoClient: (any VideoGenerationRequestHandling)?
    ) async throws {
        switch mediaType {
            case .speech:
                availableVoices = try await (speechClient?.availableVoices() ?? []).map({try ElevenLabs.Voice(voice: $0)})
                configuration.voiceSettings = .init()
                
            case .video:
                availableModels = try await videoClient?.availableModels() ?? []
                configuration.videoSettings = .init()
        }
    }
    
    @MainActor
    internal func generate(
        _ speechClient: (any SpeechSynthesisRequestHandling)?,
        _ videoClient: (any VideoGenerationRequestHandling)?
    ) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            switch mediaType {
                case .speech:
                    try await generateSpeech(speechClient)
                case .video:
                    try await generateVideo(videoClient)
            }
        } catch {
            print("Error generating media: \(error)")
        }
    }
    
    @MainActor
    private func generateSpeech(
        _ speechClient: (any SpeechSynthesisRequestHandling)?
    ) async throws {
        guard let speechClient = speechClient else {
            throw GenerationError.clientNotAvailable
        }
        
        let audioData: Data?
        
        switch inputModality.inputType {
            case is AudioFile.Type:
                guard let audioFile = currentInput as? AudioFile else { return }
                audioData = try await speechClient.speechToSpeech(
                    inputAudioURL: audioFile.url,
                    voiceID: selectedVoice?.id.rawValue ?? "",
                    voiceSettings: configuration.voiceSettings,
                    model: configuration.speechToSpeechModel
                )
                
            case is URL.Type:
                guard let audioURL = currentInput as? URL else { return }
                audioData = try await speechClient.speechToSpeech(
                    inputAudioURL: audioURL,
                    voiceID: selectedVoice?.id.rawValue ?? "",
                    voiceSettings: configuration.voiceSettings,
                    model: configuration.speechToSpeechModel
                )
                
            case is String.Type:
                guard let text = currentInput as? String else { return }
                audioData = try await speechClient.speech(
                    for: text,
                    voiceID: selectedVoice?.id.rawValue ?? "",
                    voiceSettings: configuration.voiceSettings,
                    model: configuration.textToSpeechModel
                )
                
            default:
                fatalError(.unimplemented)
        }
        
        guard let audioData = audioData else { return }
        
        let audioFile = try await AudioFile(
            data: audioData,
            name: UUID().uuidString,
            id: .random()
        )
        
        generatedFile = .init(audioFile)
        
        if let onComplete = onComplete {
            onComplete(AnyMediaFile(audioFile))
        }
    }
    
    @MainActor
    private func generateVideo(
        _ videoClient: (any VideoGenerationRequestHandling)?
    ) async throws {
        guard let videoClient = videoClient else {
            throw GenerationError.clientNotAvailable
        }
        
        guard let modelID = selectedVideoModel,
              let model = availableModels.first(where: { $0.id == modelID }) else {
            throw GenerationError.modelNotSelected
        }
        
        let videoData: Data?
        
        switch inputModality.inputType {
            case is String.Type:
                guard let text = currentInput as? String else { return }
                videoData = try await videoClient.textToVideo(
                    text: text,
                    model: model,
                    settings: configuration.videoSettings
                )
                
            case is AppKitOrUIKitImage.Type:
                guard let image = currentInput as? AppKitOrUIKitImage else { return }
                let imageURL = try await saveImageTemporarily(image)
                videoData = try await videoClient.imageToVideo(
                    imageURL: imageURL,
                    model: model,
                    settings: configuration.videoSettings
                )
                
            case is URL.Type:
                guard let videoURL = currentInput as? URL else { return }
                videoData = try await videoClient.videoToVideo(
                    videoURL: videoURL,
                    prompt: "", // Note: Would need to add prompt handling
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
        generatedFile = .init(videoFile)
        
        if let onComplete = onComplete {
            onComplete(AnyMediaFile(videoFile))
        }
    }

    
    private func saveImageTemporarily(_ image: AppKitOrUIKitImage) async throws -> URL {
        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        
        guard let imageData = image.pngData() else {
            throw GenerationError.invalidVideoData
        }
        
        try imageData.write(to: temporaryURL)
        return temporaryURL
    }
}

fileprivate enum GenerationError: Error {
    case invalidVideoData
    case clientNotAvailable
    case modelNotSelected
    case resourceLoadingFailed
}
