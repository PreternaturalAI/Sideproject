//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Foundation
import Swallow

extension Sideproject {
    public protocol ExternalAccountTypeDescriptor {
        var icon: Image? { get }
        var title: String { get }
        
        var accountType: Sideproject.ExternalAccountTypeIdentifier { get }
        var credentialType: any Sideproject.ExternalAccountCredential.Type { get }
    }
}

// MARK: - Implemented Conformances

extension Sideproject {
    public enum ExternalAccountTypeDescriptors {
        
    }
}

extension Sideproject.ExternalAccountTypeDescriptors {
    @HadeanIdentifier("nakar-butod-jozav-bazom")
    public struct Anthropic: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
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
    public struct HuggingFace: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
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
    public struct Mistral: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
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
    public struct Notion: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
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
    public struct OpenAI: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
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
    public struct Perplexity: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
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
    public struct Replicate: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
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
    public struct Groq: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
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
    public struct ElevenLabs: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
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

// MARK: - Supplementary

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.Anthropic
{
    public static var anthropic: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.ElevenLabs
{
    public static var elevenLabs: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.Groq
{
    public static var groq: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.OpenAI
{
    public static var openAI: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.Mistral
{
    public static var mistral: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.HuggingFace
{
    public static var huggingFace: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.Notion
{
    public static var notion: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.Perplexity
{
    public static var perplexity: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.Replicate
{
    public static var replicate: Self {
        Self()
    }
}

// MARK: - Deprecated

extension Sideproject {
    @available(*, deprecated, renamed: "ExternalAccountTypeDescriptor")
    public typealias ExternalAccountTypeDescription = ExternalAccountTypeDescriptor
}
