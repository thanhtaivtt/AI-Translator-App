//
//  OpenAIModels.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation

// MARK: - Request Models

/// OpenAI Chat Completions API request body
struct OpenAIChatRequest: Encodable {
    let model: String
    let messages: [OpenAIChatMessage]
    let stream: Bool
    let temperature: Double
    
    init(model: String, messages: [OpenAIChatMessage], stream: Bool = true, temperature: Double = 0.3) {
        self.model = model
        self.messages = messages
        self.stream = stream
        self.temperature = temperature
    }
}

/// A single message in the chat conversation
struct OpenAIChatMessage: Codable {
    let role: String
    let content: String
    
    static func system(_ content: String) -> OpenAIChatMessage {
        OpenAIChatMessage(role: "system", content: content)
    }
    
    static func user(_ content: String) -> OpenAIChatMessage {
        OpenAIChatMessage(role: "user", content: content)
    }
}

// MARK: - Response Models (Non-streaming)

/// Full response from OpenAI Chat Completions API
struct OpenAIChatResponse: Decodable {
    let id: String
    let choices: [OpenAIChatChoice]
    let usage: OpenAIUsage?
}

struct OpenAIChatChoice: Decodable {
    let index: Int
    let message: OpenAIChatMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index
        case message
        case finishReason = "finish_reason"
    }
}

struct OpenAIUsage: Decodable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Streaming Response Models (SSE)

/// A single chunk from the streaming response
struct OpenAIStreamChunk: Decodable {
    let id: String
    let choices: [OpenAIStreamChoice]
}

struct OpenAIStreamChoice: Decodable {
    let index: Int
    let delta: OpenAIStreamDelta
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index
        case delta
        case finishReason = "finish_reason"
    }
}

struct OpenAIStreamDelta: Decodable {
    let role: String?
    let content: String?
}

// MARK: - Error Response

/// Error response from OpenAI API
struct OpenAIErrorResponse: Decodable {
    let error: OpenAIErrorDetail
}

struct OpenAIErrorDetail: Decodable {
    let message: String
    let type: String?
    let code: String?
}
