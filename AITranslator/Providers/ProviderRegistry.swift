//
//  ProviderRegistry.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation

/// Central registry for all LLM providers.
///
/// To add a new provider:
/// 1. Create a class conforming to `LLMProvider`
/// 2. Register it in `ProviderRegistry.registerDefaults()`
///
/// Usage:
/// ```swift
/// let registry = ProviderRegistry.shared
/// let provider = registry.provider(for: "openai")
/// ```
@Observable
final class ProviderRegistry {
    
    static let shared = ProviderRegistry()
    
    /// All registered providers, keyed by their id
    private(set) var providers: [String: LLMProvider] = [:]
    
    private init() {}
    
    /// Register default providers. Call this once at app startup.
    func registerDefaults(settingsManager: SettingsManager) {
        register(OpenAIProvider(settingsManager: settingsManager))
        // Future providers:
        // register(GeminiProvider(settingsManager: settingsManager))
        // register(AnthropicProvider(settingsManager: settingsManager))
    }
    
    /// Register a provider
    func register(_ provider: LLMProvider) {
        providers[provider.id] = provider
    }
    
    /// Get a specific provider by ID
    func provider(for id: String) -> LLMProvider? {
        providers[id]
    }
    
    /// All registered providers as an array (sorted by display name)
    var allProviders: [LLMProvider] {
        providers.values.sorted { $0.displayName < $1.displayName }
    }
    
    /// Get the default provider
    var defaultProvider: LLMProvider? {
        providers[AppDefaults.providerId]
    }
}
