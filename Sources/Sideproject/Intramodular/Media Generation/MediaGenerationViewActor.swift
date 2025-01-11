//
//  MediaGenerationViewActor.swift
//  Sideproject
//
//  Created by Jared Davidson on 1/10/25.
//

import AI
import Media
import SwiftUI
import ElevenLabs

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
    @Published var speechClient: AnySpeechSynthesisRequestHandling?
    @Published var videoClient: AnyVideoGenerationRequestHandling?
    @Published var availableSpeechClients: [AnySpeechSynthesisRequestHandling] = []
    @Published var availableVideoClients: [AnyVideoGenerationRequestHandling] = []
    
    internal let mediaType: MediaType
    internal let inputModality: InputModality
    internal var configuration: MediaGenerationView.Configuration
    internal let onComplete: ((AnyMediaFile) -> Void)?
    
    init(
        mediaType: MediaType,
        inputModality: InputModality,
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
    ) async {
        isLoadingResources = true
        loadingError = nil
        
        do {
            switch mediaType {
                case .speech:
                    availableVoices = try await speechClient?.availableVoices() ?? []
                    configuration.voiceSettings = .init()
                    
                case .video:
                    availableModels = try await videoClient?.availableModels() ?? []
                    configuration.videoSettings = .init()
            }
        } catch {
            loadingError = error
        }
        
        isLoadingResources = false
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
        
        switch inputModality {
            case .audio:
                audioData = try await convertSpeechToSpeech(speechClient)
            case .text:
                audioData = try await convertTextToSpeech(speechClient)
            default:
                return
        }
        
        guard let audioData = audioData else { return }
        
        let audioFile = try await AudioFile(
            data: audioData,
            name: UUID().uuidString,
            id: .random()
        )
        generatedAudioFile = audioFile
       
        let mediaFile = AnyMediaFile(audioFile)
        if let onComplete = onComplete {
            onComplete(mediaFile)
        } else {
            generatedFiles.append(mediaFile)
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
    private func convertSpeechToSpeech(
        _ speechClient: (any SpeechSynthesisRequestHandling)?
    ) async throws -> Data? {
        guard let voiceID = selectedVoice,
              let voice = availableVoices.first(where: { $0.id == voiceID }),
              let audioFile = selectedAudioFile else {
            return nil
        }
        
        return try await speechClient?.speechToSpeech(
            inputAudioURL: audioFile.url,
            voiceID: voice.voiceID,
            voiceSettings: ElevenLabs.VoiceSettings(settings: configuration.voiceSettings),
            model: .init(rawValue: configuration.speechToSpeechModel)! // FIXME: - Will Crash
        )
    }
    
    @MainActor
    private func convertTextToSpeech(
        _ speechClient: (any SpeechSynthesisRequestHandling)?
    ) async throws -> Data? {
        guard let voiceID = selectedVoice,
              !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        
        print(speechClient)
        print(voiceID)
        
        let audio = try await speechClient?.speech(
            for: inputText,
            voiceID: voiceID.id.rawValue,
            voiceSettings: ElevenLabs.VoiceSettings(settings: configuration.voiceSettings), //FIXME: - This should just accept AbstractVoiceSettings
            model: .init(rawValue: configuration.textToSpeechModel)! // FIXME: - Will Crash
        )
        return audio
    }
}
