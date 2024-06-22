//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Foundation
import Swallow

extension Sideproject {
    public protocol ExternalAccountTypeDescription {
        var icon: Image? { get }
        var title: String { get }
        
        var accountType: Sideproject.ExternalAccountTypeIdentifier { get }
        var credentialType: any Sideproject.ExternalAccountCredential.Type { get }
    }
}

// MARK: - Implemented Conformances

extension Sideproject {
    public enum ExternalAccountTypeDescriptions {
        
    }
}

extension Sideproject.ExternalAccountTypeDescriptions {
    @HadeanIdentifier("nakar-butod-jozav-bazom")
    public struct Anthropic: Sideproject.ExternalAccountTypeDescription, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.anthropic"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/Anthropic", bundle: .module)
        }
        
        public var title: String {
            "Anthropic"
        }
        
        public init() {
            
        }
    }
    
    @HadeanIdentifier("foriz-gavat-dabog-vuvuz")
    public struct HuggingFace: Sideproject.ExternalAccountTypeDescription, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.huggingface"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/HuggingFace", bundle: .module)
        }
        
        public var title: String {
            "Hugging Face"
        }
        
        public init() {
            
        }
    }

    
    @HadeanIdentifier("mukar-lijok-kakus-zivah")
    public struct Mistral: Sideproject.ExternalAccountTypeDescription, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.mistral"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/Mistral", bundle: .module)
        }
        
        public var title: String {
            "Mistral"
        }
                
        public init() {
            
        }
    }
    
    @HadeanIdentifier("kosin-bafop-fadok-hamuf")
    public struct Notion: Sideproject.ExternalAccountTypeDescription, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.notion"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/Notion", bundle: .module)
        }
        
        public var title: String {
            "Notion"
        }
        
        public init() {
            
        }
    }

    @HadeanIdentifier("sakuj-sifol-tisub-rihug")
    public struct OpenAI: Sideproject.ExternalAccountTypeDescription, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.openai"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/GPT-3", bundle: .module)
        }
        
        public var title: String {
            "OpenAI"
        }
                
        public init() {
            
        }
    }
    
    @HadeanIdentifier("dusig-rikin-gilit-gopuj")
    public struct Perplexity: Sideproject.ExternalAccountTypeDescription, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.perplexity"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/Perplexity", bundle: .module)
        }
        
        public var title: String {
            "Perplexity"
        }
        
        public init() {
            
        }
    }

    @HadeanIdentifier("nivun-ralib-zotuv-kiniv")
    public struct Replicate: Sideproject.ExternalAccountTypeDescription, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.replicate"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/Replicate", bundle: .module)
        }
        
        public var title: String {
            "Replicate"
        }
        
        public init() {
            
        }
    }
    
    @HadeanIdentifier("nupis-honig-zutor-vuliv")
    public struct Groq: Sideproject.ExternalAccountTypeDescription, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.groq"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/groq", bundle: .module)
        }
        
        public var title: String {
            "Groq"
        }
                
        public init() {
            
        }
    }
    
    @HadeanIdentifier("fisul-tapos-hotak-nonov")
    public struct ElevenLabs: Sideproject.ExternalAccountTypeDescription, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.elevenlabs"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/elevenlabs", bundle: .module)
        }
        
        public var title: String {
            "ElevenLabs"
        }
                
        public init() {
            
        }
    }
}

extension Sideproject.ExternalAccountTypeDescription where Self == Sideproject.ExternalAccountTypeDescriptions.Groq
{
    public static var groq: Self {
        .init()
    }
}

extension Sideproject.ExternalAccountTypeDescription where Self == Sideproject.ExternalAccountTypeDescriptions.Mistral
{
    public static var mistral: Self {
        .init()
    }
}

extension Sideproject.ExternalAccountTypeDescription where Self == Sideproject.ExternalAccountTypeDescriptions.OpenAI
{
    public static var openAI: Self {
        .init()
    }
}

extension Sideproject.ExternalAccountTypeDescription where Self == Sideproject.ExternalAccountTypeDescriptions.Anthropic
{
    public static var anthropic: Self {
        .init()
    }
}

extension Sideproject.ExternalAccountTypeDescription where Self == Sideproject.ExternalAccountTypeDescriptions.HuggingFace
{
    public static var huggingFace: Self {
        .init()
    }
}

extension Sideproject.ExternalAccountTypeDescription where Self == Sideproject.ExternalAccountTypeDescriptions.Notion
{
    public static var notion: Self {
        .init()
    }
}

extension Sideproject.ExternalAccountTypeDescription where Self == Sideproject.ExternalAccountTypeDescriptions.Perplexity
{
    public static var perplexity: Self {
        .init()
    }
}

extension Sideproject.ExternalAccountTypeDescription where Self == Sideproject.ExternalAccountTypeDescriptions.Replicate
{
    public static var replicate: Self {
        .init()
    }
}

extension Sideproject.ExternalAccountTypeDescription where Self == Sideproject.ExternalAccountTypeDescriptions.ElevenLabs
{
    public static var elevenLabs: Self {
        .init()
    }
}
