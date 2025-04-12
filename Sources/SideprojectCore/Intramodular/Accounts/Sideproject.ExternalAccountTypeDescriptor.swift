//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Foundation
import Swallow
import SwiftUI

extension Sideproject {
    public protocol ExternalAccountTypeDescriptor: Hashable {
        var icon: SwiftUI.Image? { get }
        var title: String { get }
        
        var accountType: Sideproject.ExternalAccountTypeIdentifier { get }
        var credentialType: any Sideproject.ExternalAccountCredential.Type { get }
    }
}

// MARK: - Conformees

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
    
    @HadeanIdentifier("povar-firul-milij-jopat")
    public struct FalAI: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.falai"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/fal", bundle: .module)
        }
        
        public var title: String {
            "Fal"
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
    
    @HadeanIdentifier("jatap-jogaz-ritiz-vibok")
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
    
    @HadeanIdentifier("titav-sijag-ruhid-vubim")
    public struct ValTown: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.valtown"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/valtown", bundle: .module)
        }
        
        public var title: String {
            "ValTown"
        }
                
        public init() {
            
        }
    }
    
    @HadeanIdentifier("vuvor-johud-bojam-vofoh")
    public struct Jina: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.jina"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/jina", bundle: .module)
        }
        
        public var title: String {
            "Jina"
        }
                
        public init() {
            
        }
    }
    
    @HadeanIdentifier("bifur-gozik-dubig-naruj")
    public struct VoyageAI: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.voyageAI"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/voyageAI", bundle: .module)
        }
        
        public var title: String {
            "VoyageAI"
        }
                
        public init() {
            
        }
    }
    
    @HadeanIdentifier("tabam-pojik-gizoj-rigoh")
    public struct Cohere: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.cohere"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/Cohere", bundle: .module)
        }
        
        public var title: String {
            "Cohere"
        }
                
        public init() {
            
        }
    }
    
    @HadeanIdentifier("fomol-pifol-fonid-gasad")
    public struct TogetherAI: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.togetherAI"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/togetherAI", bundle: .module)
        }
        
        public var title: String {
            "TogetherAI"
        }
                
        public init() {
            
        }
    }
    
    @HadeanIdentifier("jimas-nufon-pulub-vubam")
    public struct Marginalia: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.marginalia"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/marginalia", bundle: .module)
        }
        
        public var title: String {
            "Marginalia"
        }
                
        public init() {
            
        }
    }
    
    @HadeanIdentifier("foluv-jufuk-zuhok-hofid")
    public struct PlayHT: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.playHT"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/playHT", bundle: .module)
        }
        
        public var title: String {
            "PlayHT"
        }
        
        public init() {
            
        }
    }
    
    @HadeanIdentifier("tohaz-zivir-bosov-minog")
    public struct Rime: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.rime"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/rime", bundle: .module)
        }
        
        public var title: String {
            "Rime"
        }
        
        public init() {
            
        }
    }
    
    @HadeanIdentifier("kinot-tugug-rojum-sinis")
    public struct HumeAI: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.humeAI"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/humeAI", bundle: .module)
        }
        
        public var title: String {
            "HumeAI"
        }
        
        public init() {
            
        }
    }
    
    @HadeanIdentifier("tabut-fozak-tajah-bagaj")
    public struct NeetsAI: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.neetsAI"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/neetsAI", bundle: .module)
        }
        
        public var title: String {
            "NeetsAI"
        }
        
        public init() {
            
        }
    }
    
    @HadeanIdentifier("jahov-batom-ruhof-fubom")
    public struct xAI: Sideproject.ExternalAccountTypeDescriptor, _StaticInstance {
        public var accountType: Sideproject.ExternalAccountTypeIdentifier {
            "com.vmanot.xAI"
        }
        
        public var credentialType: any Sideproject.ExternalAccountCredential.Type {
            Sideproject.ExternalAccountCredentialTypes.APIKey.self
        }
        
        public var icon: Image? {
            Image("logo/xAI", bundle: .module)
        }
        
        public var title: String {
            "xAI"
        }
        
        public init() {
            
        }
    }
}

// MARK: - Supplementary

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.Anthropic {
    public static var anthropic: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.Cohere {
    public static var cohere: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.ElevenLabs {
    public static var elevenLabs: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.FalAI {
    public static var fal: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.Groq {
    public static var groq: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.HuggingFace {
    public static var huggingFace: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.Jina {
    public static var jina: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.Marginalia {
    public static var marginalia: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.Mistral {
    public static var mistral: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.Notion {
    public static var notion: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.OpenAI {
    public static var openAI: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.Perplexity {
    public static var perplexity: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.Replicate {
    public static var replicate: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.TogetherAI {
    public static var togetherAI: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.ValTown {
    public static var valtown: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.VoyageAI {
    public static var voyageAI: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.PlayHT {
    public static var playHT: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.Rime {
    public static var rime: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.HumeAI {
    public static var humeAI: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.NeetsAI {
    public static var neetsAI: Self {
        Self()
    }
}

extension Sideproject.ExternalAccountTypeDescriptor where Self == Sideproject.ExternalAccountTypeDescriptors.xAI {
    public static var xAI: Self {
        Self()
    }
}

// MARK: - Deprecated

extension Sideproject {
    @available(*, deprecated, renamed: "ExternalAccountTypeDescriptor")
    public typealias ExternalAccountTypeDescription = ExternalAccountTypeDescriptor
}
