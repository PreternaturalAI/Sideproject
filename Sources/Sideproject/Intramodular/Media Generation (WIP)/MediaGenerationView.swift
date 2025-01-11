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
    
    internal let mediaType: MediaType
    internal let inputModality: InputModality
    internal var configuration: Configuration
    internal let onComplete: ((AnyMediaFile) -> Void)?
    
    @StateObject internal var viewModel: GenerationViewModel
    
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
            
            if let mediaFile = viewModel.generatedFile {
                MediaFileView(file: mediaFile.file)
            }
            
            inputView
            clientSelectionView
            modelSelectionView
            
            if case .video = viewModel.mediaType, case .video = viewModel.inputModality {
                promptInputView
            }
            
            controlsView
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
    
    internal var isGenerateEnabled: Bool {
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
