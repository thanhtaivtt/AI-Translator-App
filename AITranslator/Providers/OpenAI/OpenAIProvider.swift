//
//  OpenAIProvider.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation

/// OpenAI LLM provider implementation.
/// Uses the Chat Completions API with SSE streaming support.
final class OpenAIProvider: LLMProvider {
    
    let id = "openai"
    let displayName = "OpenAI"
    let requiresAPIKey = true
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let settingsManager: SettingsManager
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    // MARK: - Available Models
    
    func availableModels() -> [LLMModel] {
        [
            LLMModel(id: "gpt-4o", name: "GPT-4o", providerId: id),
            LLMModel(id: "gpt-4o-mini", name: "GPT-4o Mini", providerId: id),
            LLMModel(id: "gpt-4.1", name: "GPT-4.1", providerId: id),
            LLMModel(id: "gpt-4.1-mini", name: "GPT-4.1 Mini", providerId: id),
            LLMModel(id: "gpt-4.1-nano", name: "GPT-4.1 Nano", providerId: id),
            LLMModel(id: "gpt-3.5-turbo", name: "GPT-3.5 Turbo", providerId: id),
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
        let messages: [OpenAIChatMessage] = [.system(prompts.system), .user(prompts.user)]
        
        let request = OpenAIChatRequest(model: model, messages: messages, stream: false)
        let urlRequest = try buildURLRequest(apiKey: apiKey, body: request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        try validateHTTPResponse(response, data: data)
        
        let chatResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        
        guard let content = chatResponse.choices.first?.message.content else {
            throw LLMProviderError.invalidResponse
        }
        
        return content
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
                    let messages: [OpenAIChatMessage] = [.system(prompts.system), .user(prompts.user)]
                    let request = OpenAIChatRequest(model: model, messages: messages, stream: true)
                    let urlRequest = try buildURLRequest(apiKey: apiKey, body: request)
                    
                    let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
                    
                    // Validate HTTP response
                    if let httpResponse = response as? HTTPURLResponse {
                        guard (200...299).contains(httpResponse.statusCode) else {
                            // Try to read error body
                            var errorBody = ""
                            for try await line in bytes.lines {
                                errorBody += line
                            }
                            if let data = errorBody.data(using: .utf8),
                               let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
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
                        // SSE format: "data: {json}" or "data: [DONE]"
                        guard line.hasPrefix("data: ") else { continue }
                        
                        let jsonString = String(line.dropFirst(6))
                        
                        if jsonString == "[DONE]" {
                            break
                        }
                        
                        guard let jsonData = jsonString.data(using: .utf8) else { continue }
                        
                        do {
                            let chunk = try JSONDecoder().decode(OpenAIStreamChunk.self, from: jsonData)
                            if let content = chunk.choices.first?.delta.content {
                                continuation.yield(content)
                            }
                        } catch {
                            // Skip malformed chunks silently
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
    

    
    private func buildURLRequest(apiKey: String, body: OpenAIChatRequest) throws -> URLRequest {
        guard let url = URL(string: baseURL) else {
            throw LLMProviderError.unknown("Invalid API URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        
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
            
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
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
