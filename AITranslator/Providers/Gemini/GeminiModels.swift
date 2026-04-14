//
//  GeminiModels.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation

// MARK: - Request Models

/// Google Gemini generateContent request body
struct GeminiGenerateRequest: Encodable {
    let contents: [GeminiContent]
    let systemInstruction: GeminiContent?
    let generationConfig: GeminiGenerationConfig?
    
    enum CodingKeys: String, CodingKey {
        case contents
        case systemInstruction = "system_instruction"
        case generationConfig = "generationConfig"
    }
}

struct GeminiContent: Codable {
    let role: String?
    let parts: [GeminiPart]
    
    static func user(_ text: String) -> GeminiContent {
        GeminiContent(role: "user", parts: [GeminiPart(text: text)])
    }
    
    static func model(_ text: String) -> GeminiContent {
        GeminiContent(role: "model", parts: [GeminiPart(text: text)])
    }
    
    static func system(_ text: String) -> GeminiContent {
        GeminiContent(role: nil, parts: [GeminiPart(text: text)])
    }
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerationConfig: Encodable {
    let temperature: Double
    let maxOutputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case temperature
        case maxOutputTokens = "maxOutputTokens"
    }
    
    init(temperature: Double = 0.3, maxOutputTokens: Int = 4096) {
        self.temperature = temperature
        self.maxOutputTokens = maxOutputTokens
    }
}

// MARK: - Response Models (Non-streaming)

/// Full response from Gemini generateContent API
struct GeminiGenerateResponse: Decodable {
    let candidates: [GeminiCandidate]?
    let usageMetadata: GeminiUsageMetadata?
    let error: GeminiErrorDetail?
}

struct GeminiCandidate: Decodable {
    let content: GeminiContent?
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case content
        case finishReason = "finishReason"
    }
}

struct GeminiUsageMetadata: Decodable {
    let promptTokenCount: Int?
    let candidatesTokenCount: Int?
    let totalTokenCount: Int?
}

// MARK: - Error Response

struct GeminiErrorResponse: Decodable {
    let error: GeminiErrorDetail
}

struct GeminiErrorDetail: Decodable {
    let code: Int?
    let message: String
    let status: String?
}
