//
//  LLMProvider.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation

/// Protocol defining the interface for LLM translation providers.
///
/// To add a new provider (e.g., Google Gemini, Anthropic Claude):
/// 1. Create a new class conforming to `LLMProvider`
/// 2. Register it in `ProviderRegistry`
///
/// That's it — no other code changes needed.
protocol LLMProvider: AnyObject {
    /// Unique identifier for this provider (e.g., "openai", "gemini")
    var id: String { get }
    
    /// Human-readable name (e.g., "OpenAI", "Google Gemini")
    var displayName: String { get }
    
    /// Whether this provider requires an API key
    var requiresAPIKey: Bool { get }
    
    /// Translate text (non-streaming, returns full result)
    func translate(
        text: String,
        from sourceLanguage: Language,
        to targetLanguage: Language,
        model: String,
        customPrompt: String?
    ) async throws -> String
    
    /// Translate text with streaming (returns chunks as they arrive)
    func translateStream(
        text: String,
        from sourceLanguage: Language,
        to targetLanguage: Language,
        model: String,
        customPrompt: String?
    ) -> AsyncThrowingStream<String, Error>
    
    /// List of models available from this provider
    func availableModels() -> [LLMModel]
}

// MARK: - Provider Errors

/// Errors that can occur during LLM provider operations
enum LLMProviderError: LocalizedError {
    case apiKeyMissing
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case networkError(underlying: Error)
    case decodingError(underlying: Error)
    case streamingError(message: String)
    case rateLimited
    case modelNotFound(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "API key is not configured. Please add your API key in Settings."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .httpError(let code, let message):
            return "HTTP Error \(code): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .streamingError(let message):
            return "Streaming error: \(message)"
        case .rateLimited:
            return "Rate limited. Please wait a moment and try again."
        case .modelNotFound(let model):
            return "Model '\(model)' is not available."
        case .unknown(let message):
            return message
        }
    }
}
