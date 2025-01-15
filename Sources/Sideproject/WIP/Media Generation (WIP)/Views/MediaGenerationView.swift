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

public struct MediaGenerationView: View {
    public struct Configuration: Equatable {
        public var textToSpeechModel: String
        public var speechToSpeechModel: String
        public var voiceSettings: AbstractVoiceSettings
        public var videoSettings: VideoGenerationSettings
        
        // FIXME: - This should not be defaulting to ElevenLabs. Should be detached to an AbstractModel instead.
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
    
    internal let mediaType: MediaType
    internal let inputModality: AnyInputModality
    internal var configuration: Configuration
    internal let onComplete: ((AnyMediaFile) -> Void)?
    
    @StateObject internal var viewActor: MediaGenerationViewActor
    
    public init(
        mediaType: MediaType,
        configuration: Configuration = .init(),
        onComplete: ((AnyMediaFile) -> Void)? = nil
    ) {
        // Default to text modality
        self.init(
            mediaType: mediaType,
            inputModality: .text,
            configuration: configuration,
            onComplete: onComplete
        )
    }
    
    internal init(
        mediaType: MediaType,
        inputModality: AnyInputModality,
        configuration: Configuration = .init(),
        onComplete: ((AnyMediaFile) -> Void)? = nil
    ) {
        self.mediaType = mediaType
        self.inputModality = inputModality
        self.configuration = configuration
        self.onComplete = onComplete
        
        let viewActor = MediaGenerationViewActor(
            mediaType: mediaType,
            inputModality: inputModality,
            configuration: configuration,
            onComplete: onComplete
        )
        _viewActor = StateObject(wrappedValue: viewActor)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let mediaFile = viewActor.generatedFile {
                MediaFileView(file: mediaFile.file)
            }
            
            inputModality.makeInputView(binding: $viewActor.currentInput)
            clientSelectionView
            modelSelectionView
            
            if case .video = mediaType, inputModality.inputType == URL.self {
                promptInputView
            }
            
            controlsView
        }
        .padding()
        .task {
            await loadClients()
            try? await viewActor.loadResources(
                viewActor.speechClient?.base,
                viewActor.videoClient?.base
            )
        }
        .onChange(of: viewActor.speechClient) {
            oldValue,
            newValue in
            Task {
                try? await viewActor.loadResources(
                    viewActor.speechClient?.base,
                    viewActor.videoClient?.base
                )
            }
        }
    }
    
    private func loadClients() async {
        do {
            let services = try await Sideproject.shared.services
            
            self.viewActor.availableSpeechClients = services.compactMap { service in
                if let service = service as? (any CoreMI._ServiceClientProtocol & SpeechSynthesisRequestHandling) {
                    return AnySpeechSynthesisRequestHandling(service)
                }
                return nil
            }
            
            self.viewActor.availableVideoClients = services.compactMap { service in
                if let service = service as? (any CoreMI._ServiceClientProtocol & VideoGenerationRequestHandling) {
                    return AnyVideoGenerationRequestHandling(service)
                }
                return nil
            }
            
            self.viewActor.speechClient = self.viewActor.availableSpeechClients.first
            self.viewActor.videoClient = self.viewActor.availableVideoClients.first
        } catch {
            print("Error loading clients: \(error)")
        }
    }
    
    internal var isGenerateEnabled: Bool {
        let isInputValid = inputModality.validate(viewActor.currentInput)
        
        let isModelSelected = switch mediaType {
            case .speech: viewActor.selectedVoice != nil
            case .video: viewActor.selectedVideoModel != nil
        }
        
        return isInputValid && isModelSelected
    }
}
