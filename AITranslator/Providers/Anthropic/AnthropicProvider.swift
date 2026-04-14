//
//  AnthropicProvider.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation

/// Anthropic Claude LLM provider implementation.
/// Uses the Messages API with SSE streaming support.
final class AnthropicProvider: LLMProvider {
    
    let id = "anthropic"
    let displayName = "Anthropic"
    let requiresAPIKey = true
    
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let apiVersion = "2023-06-01"
    private let settingsManager: SettingsManager
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    // MARK: - Available Models
    
    func availableModels() -> [LLMModel] {
        [
            LLMModel(id: "claude-sonnet-4-20250514", name: "Claude Sonnet 4", providerId: id),
            LLMModel(id: "claude-3-7-sonnet-20250219", name: "Claude 3.7 Sonnet", providerId: id),
            LLMModel(id: "claude-3-5-haiku-20241022", name: "Claude 3.5 Haiku", providerId: id),
            LLMModel(id: "claude-3-5-sonnet-20241022", name: "Claude 3.5 Sonnet", providerId: id),
            LLMModel(id: "claude-3-opus-20240229", name: "Claude 3 Opus", providerId: id),
        ]
    }
    
    // MARK: - Translation (Non-streaming)
    
    func translate(
        text: String,
        from sourceLanguage: Language,
        to targetLanguage: Language,
        model: String,
        customPrompt: String?
    ) async throws -> String {
        let apiKey = try getAPIKey()
        let prompts = PromptBuilder.build(text: text, from: sourceLanguage, to: targetLanguage, customPrompt: customPrompt)
        
        let request = AnthropicMessagesRequest(
            model: model,
            system: prompts.system,
            messages: [.user(prompts.user)],
            stream: false
        )
        let urlRequest = try buildURLRequest(apiKey: apiKey, body: request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        try validateHTTPResponse(response, data: data)
        
        let messagesResponse = try JSONDecoder().decode(AnthropicMessagesResponse.self, from: data)
        
        guard let textBlock = messagesResponse.content.first(where: { $0.type == "text" }),
              let text = textBlock.text else {
            throw LLMProviderError.invalidResponse
        }
        
        return text
    }
    
    // MARK: - Translation (Streaming)
    
    func translateStream(
        text: String,
        from sourceLanguage: Language,
        to targetLanguage: Language,
        model: String,
        customPrompt: String?
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let apiKey = try getAPIKey()
                    let prompts = PromptBuilder.build(text: text, from: sourceLanguage, to: targetLanguage, customPrompt: customPrompt)
                    
                    let request = AnthropicMessagesRequest(
                        model: model,
                        system: prompts.system,
                        messages: [.user(prompts.user)],
                        stream: true
                    )
                    let urlRequest = try buildURLRequest(apiKey: apiKey, body: request)
                    
                    let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
                    
                    // Validate HTTP response
                    if let httpResponse = response as? HTTPURLResponse {
                        guard (200...299).contains(httpResponse.statusCode) else {
                            var errorBody = ""
                            for try await line in bytes.lines {
                                errorBody += line
                            }
                            if let data = errorBody.data(using: .utf8),
                               let errorResponse = try? JSONDecoder().decode(AnthropicErrorResponse.self, from: data) {
                                throw LLMProviderError.httpError(
                                    statusCode: httpResponse.statusCode,
                                    message: errorResponse.error.message
                                )
                            }
                            throw LLMProviderError.httpError(
                                statusCode: httpResponse.statusCode,
                                message: "Unknown error"
                            )
                        }
                    }
                    
                    // Parse SSE stream
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        
                        let jsonString = String(line.dropFirst(6))
                        guard let jsonData = jsonString.data(using: .utf8) else { continue }
                        
                        do {
                            let event = try JSONDecoder().decode(AnthropicStreamEvent.self, from: jsonData)
                            
                            switch event.type {
                            case "content_block_delta":
                                if let text = event.delta?.text {
                                    continuation.yield(text)
                                }
                            case "message_stop":
                                break
                            case "error":
                                throw LLMProviderError.streamingError(message: "Stream error from Anthropic")
                            default:
                                continue
                            }
                        } catch let error as LLMProviderError {
                            throw error  // Re-throw original error
                        } catch {
                            // Skip malformed chunks
                            continue
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func getAPIKey() throws -> String {
        guard let apiKey = settingsManager.getAPIKey(for: id), !apiKey.isEmpty else {
            throw LLMProviderError.apiKeyMissing
        }
        return apiKey
    }
    

    
    private func buildURLRequest(apiKey: String, body: AnthropicMessagesRequest) throws -> URLRequest {
        guard let url = URL(string: baseURL) else {
            throw LLMProviderError.unknown("Invalid API URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        request.httpBody = try JSONEncoder().encode(body)
        
        return request
    }
    
    private func validateHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMProviderError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 429 {
                throw LLMProviderError.rateLimited
            }
            
            if let errorResponse = try? JSONDecoder().decode(AnthropicErrorResponse.self, from: data) {
                throw LLMProviderError.httpError(
                    statusCode: httpResponse.statusCode,
                    message: errorResponse.error.message
                )
            }
            
            throw LLMProviderError.httpError(
                statusCode: httpResponse.statusCode,
                message: "Request failed with status \(httpResponse.statusCode)"
            )
        }
    }
}
