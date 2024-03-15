//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Foundation
import Swallow

public protocol LTAccountTypeDescription {
    var icon: Image? { get }
    var title: String { get }
    
    var accountType: LTAccountTypeIdentifier { get }
    var credentialType: any LTAccountCredential.Type { get }
}

// MARK: - Implemented Conformances

public enum LTAccountTypeDescriptions {
    
}

extension LTAccountTypeDescriptions {
    @HadeanIdentifier("nakar-butod-jozav-bazom")
    public struct Anthropic: LTAccountTypeDescription, _StaticInstance {
        public var accountType: LTAccountTypeIdentifier {
            "com.vmanot.anthropic"
        }
        
        public var credentialType: any LTAccountCredential.Type {
            _LTAccountCredential.APIKey.self
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
    public struct HuggingFace: LTAccountTypeDescription, _StaticInstance {
        public var accountType: LTAccountTypeIdentifier {
            "com.vmanot.huggingface"
        }
        
        public var credentialType: any LTAccountCredential.Type {
            _LTAccountCredential.APIKey.self
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
    public struct Mistral: LTAccountTypeDescription, _StaticInstance {
        public var accountType: LTAccountTypeIdentifier {
            "com.vmanot.mistral"
        }
        
        public var credentialType: any LTAccountCredential.Type {
            _LTAccountCredential.APIKey.self
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
    public struct Notion: LTAccountTypeDescription, _StaticInstance {
        public var accountType: LTAccountTypeIdentifier {
            "com.vmanot.notion"
        }
        
        public var credentialType: any LTAccountCredential.Type {
            _LTAccountCredential.APIKey.self
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
    public struct OpenAI: LTAccountTypeDescription, _StaticInstance {
        public var accountType: LTAccountTypeIdentifier {
            "com.vmanot.openai"
        }
        
        public var credentialType: any LTAccountCredential.Type {
            _LTAccountCredential.APIKey.self
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
    public struct Perplexity: LTAccountTypeDescription, _StaticInstance {
        public var accountType: LTAccountTypeIdentifier {
            "com.vmanot.perplexity"
        }
        
        public var credentialType: any LTAccountCredential.Type {
            _LTAccountCredential.APIKey.self
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
    public struct Replicate: LTAccountTypeDescription, _StaticInstance {
        public var accountType: LTAccountTypeIdentifier {
            "com.vmanot.replicate"
        }
        
        public var credentialType: any LTAccountCredential.Type {
            _LTAccountCredential.APIKey.self
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
}

