//
// Copyright (c) Vatsal Manot
//

import Anthropic
import CoreMI
import LargeLanguageModels
import Mistral
import Ollama
import OpenAI
import Swallow

public enum _ChatModel: CaseIterable, Hashable, Sendable {
    @_SpecializedArrayBuilder<Self>
    public static var allCases: [Self] {
        Anthropic.Model.allCases
            .filter({ !$0.isPointerToLatestVersion })
            .map(_ChatModel.anthropic)
        
        Array(Ollama.shared._allKnownModels ?? [])
            .map({ Self.ollama($0) })
        
        Array([
            Mistral.Model.mistral_medium,
            Mistral.Model.mistral_small,
            Mistral.Model.mistral_tiny
        ])
        .map({ Self.mistral($0) })
        
        Array([
            OpenAI.Model.chat(.gpt_3_5_turbo),
            OpenAI.Model.chat(.gpt_4),
            OpenAI.Model.chat(.gpt_4_1106_preview),
            OpenAI.Model.chat(.gpt_4_vision_preview),
            OpenAI.Model.chat(.gpt_4o),
            OpenAI.Model.chat(.gpt_4o_mini)
        ])
        .map({ Self.openai($0) })
    }
    
    case anthropic(Anthropic.Model)
    case mistral(Mistral.Model)
    case ollama(Ollama.Model)
    case openai(OpenAI.Model)
    
    public var provider: String {
        switch self {
            case .anthropic:
                return "Anthropic"
            case .mistral:
                return "Mistral"
            case .ollama:
                return "Ollama"
            case .openai:
                return "OpenAI"
        }
    }
    
    public var debugDescription: String {
        switch self {
            case .anthropic(let model):
                return model.debugDescription
            case .mistral(let model):
                return model.name
            case .ollama(let model):
                return model.name
            case .openai(let model):
                return model.name
        }
    }
}

extension _ChatModel: ModelIdentifierConvertible {
    public func __conversion() throws -> ModelIdentifier {
        do {
            switch self {
                case .anthropic(let model):
                    return try ModelIdentifier(description: model.rawValue).unwrap()
                case .mistral(let model):
                    return try ModelIdentifier(description: model.rawValue).unwrap()
                case .ollama(let model):
                    return try model.__conversion()
                case .openai(let model):
                    return try ModelIdentifier(description: model.rawValue).unwrap()
            }
        } catch {
            throw CustomStringError("Failed to convert \(self) to a \(ModelIdentifier.self).")
        }
    }
}

// MARK: - Supplementary

extension ModelIdentifier {
    public func _name(
        for type: _ChatModel.Type
    ) -> String {
        _ChatModel.allCases.first(where: { (try? $0.__conversion()) == self })?.debugDescription ?? self.description
    }
}
