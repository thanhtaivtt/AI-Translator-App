//
//  GeminiProvider.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation

/// Google Gemini LLM provider implementation.
/// Uses the Generative Language API with SSE streaming support.
final class GeminiProvider: LLMProvider {
    
    let id = "gemini"
    let displayName = "Google Gemini"
    let requiresAPIKey = true
    
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    private let settingsManager: SettingsManager
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    // MARK: - Available Models
    
    func availableModels() -> [LLMModel] {
        [
            LLMModel(id: "gemini-2.5-flash-preview-04-17", name: "Gemini 2.5 Flash", providerId: id),
            LLMModel(id: "gemini-2.5-pro-preview-03-25", name: "Gemini 2.5 Pro", providerId: id),
            LLMModel(id: "gemini-2.0-flash", name: "Gemini 2.0 Flash", providerId: id),
            LLMModel(id: "gemini-2.0-flash-lite", name: "Gemini 2.0 Flash Lite", providerId: id),
            LLMModel(id: "gemini-1.5-pro", name: "Gemini 1.5 Pro", providerId: id),
            LLMModel(id: "gemini-1.5-flash", name: "Gemini 1.5 Flash", providerId: id),
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
        
        let request = GeminiGenerateRequest(
            contents: [.user(prompts.user)],
            systemInstruction: .system(prompts.system),
            generationConfig: GeminiGenerationConfig()
        )
        
        // ⚠️ Gemini API requires key in URL query string.
        // Do NOT log request URLs. Consider OAuth2 for production.
        let url = "\(baseURL)/\(model):generateContent?key=\(apiKey)"
        let urlRequest = try buildURLRequest(url: url, body: request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        try validateHTTPResponse(response, data: data)
        
        let geminiResponse = try JSONDecoder().decode(GeminiGenerateResponse.self, from: data)
        
        if let error = geminiResponse.error {
            throw LLMProviderError.httpError(statusCode: error.code ?? 500, message: error.message)
        }
        
        guard let candidate = geminiResponse.candidates?.first,
              let content = candidate.content,
              let text = content.parts.first?.text else {
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
                    
                    let request = GeminiGenerateRequest(
                        contents: [.user(prompts.user)],
                        systemInstruction: .system(prompts.system),
                        generationConfig: GeminiGenerationConfig()
                    )
                    
                    // ⚠️ Gemini API requires key in URL query string.
                    // Do NOT log request URLs. Consider OAuth2 for production.
                    let url = "\(baseURL)/\(model):streamGenerateContent?alt=sse&key=\(apiKey)"
                    let urlRequest = try buildURLRequest(url: url, body: request)
                    
                    let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
                    
                    // Validate HTTP response
                    if let httpResponse = response as? HTTPURLResponse {
                        guard (200...299).contains(httpResponse.statusCode) else {
                            var errorBody = ""
                            for try await line in bytes.lines {
                                errorBody += line
                            }
                            if let data = errorBody.data(using: .utf8),
                               let errorResponse = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data) {
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
                    // Gemini SSE format: "data: {json}\n\n"
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        
                        let jsonString = String(line.dropFirst(6))
                        guard let jsonData = jsonString.data(using: .utf8) else { continue }
                        
                        do {
                            let chunkResponse = try JSONDecoder().decode(GeminiGenerateResponse.self, from: jsonData)
                            
                            if let error = chunkResponse.error {
                                throw LLMProviderError.streamingError(message: error.message)
                            }
                            
                            if let candidate = chunkResponse.candidates?.first,
                               let content = candidate.content,
                               let text = content.parts.first?.text {
                                continuation.yield(text)
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
    

    
    private func buildURLRequest(url: String, body: GeminiGenerateRequest) throws -> URLRequest {
        guard let requestURL = URL(string: url) else {
            throw LLMProviderError.unknown("Invalid API URL")
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
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
            
            if let errorResponse = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data) {
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
