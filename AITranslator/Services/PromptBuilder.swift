//
//  PromptBuilder.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation

/// Shared prompt builder for all LLM providers.
/// Eliminates duplicate buildPrompts() logic across providers (DRY-1 fix).
enum PromptBuilder {
    
    /// Build system and user prompts for translation.
    /// - Parameters:
    ///   - text: Source text to translate
    ///   - sourceLanguage: Source language (or .auto for auto-detect)
    ///   - targetLanguage: Target language
    ///   - customPrompt: Optional custom system prompt override
    /// - Returns: Tuple of (systemPrompt, userPrompt)
    static func build(
        text: String,
        from sourceLanguage: Language,
        to targetLanguage: Language,
        customPrompt: String?
    ) -> (system: String, user: String) {
        let systemPrompt: String
        if let custom = customPrompt, !custom.isEmpty {
            systemPrompt = custom
        } else {
            systemPrompt = AppDefaults.defaultSystemPrompt
        }
        
        let sourceDesc = sourceLanguage == .auto
            ? "the source language (auto-detect it)"
            : sourceLanguage.englishName
        
        let userPrompt = """
        Translate the following text from \(sourceDesc) to \(targetLanguage.englishName):
        
        \(text)
        """
        
        return (systemPrompt, userPrompt)
    }
}
