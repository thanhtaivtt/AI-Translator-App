//
//  TranslationService.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation

/// Orchestrates translation requests through the active LLM provider.
/// Acts as a facade between ViewModels and LLM providers.
final class TranslationService {
    
    private let registry: ProviderRegistry
    private let settingsManager: SettingsManager
    
    init(registry: ProviderRegistry = .shared, settingsManager: SettingsManager = .shared) {
        self.registry = registry
        self.settingsManager = settingsManager
    }
    
    /// Get the currently active provider based on settings
    var activeProvider: LLMProvider? {
        registry.provider(for: settingsManager.selectedProviderId)
    }
    
    /// Translate text using the active provider (non-streaming)
    func translate(
        text: String,
        from source: Language,
        to target: Language
    ) async throws -> String {
        guard let provider = activeProvider else {
            throw LLMProviderError.unknown("No translation provider configured")
        }
        
        return try await provider.translate(
            text: text,
            from: source,
            to: target,
            model: settingsManager.selectedModelId,
            customPrompt: settingsManager.effectiveSystemPrompt
        )
    }
    
    /// Translate text using the active provider (streaming)
    func translateStream(
        text: String,
        from source: Language,
        to target: Language
    ) -> AsyncThrowingStream<String, Error> {
        guard let provider = activeProvider else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: LLMProviderError.unknown("No translation provider configured"))
            }
        }
        
        return provider.translateStream(
            text: text,
            from: source,
            to: target,
            model: settingsManager.selectedModelId,
            customPrompt: settingsManager.effectiveSystemPrompt
        )
    }
}
