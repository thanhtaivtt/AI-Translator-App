//
//  AnthropicModels.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation

// MARK: - Request Models

/// Anthropic Messages API request body
struct AnthropicMessagesRequest: Encodable {
    let model: String
    let maxTokens: Int
    let system: String?
    let messages: [AnthropicMessage]
    let stream: Bool
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
        case stream
        case temperature
    }
    
    init(model: String, system: String? = nil, messages: [AnthropicMessage],
         stream: Bool = true, maxTokens: Int = 4096, temperature: Double = 0.3) {
        self.model = model
        self.maxTokens = maxTokens
        self.system = system
        self.messages = messages
        self.stream = stream
        self.temperature = temperature
    }
}

/// A single message in the Anthropic conversation
struct AnthropicMessage: Codable {
    let role: String
    let content: String
    
    static func user(_ content: String) -> AnthropicMessage {
        AnthropicMessage(role: "user", content: content)
    }
    
    static func assistant(_ content: String) -> AnthropicMessage {
        AnthropicMessage(role: "assistant", content: content)
    }
}

// MARK: - Response Models (Non-streaming)

/// Full response from Anthropic Messages API
struct AnthropicMessagesResponse: Decodable {
    let id: String
    let content: [AnthropicContentBlock]
    let model: String
    let stopReason: String?
    let usage: AnthropicUsage?
    
    enum CodingKeys: String, CodingKey {
        case id, content, model
        case stopReason = "stop_reason"
        case usage
    }
}

struct AnthropicContentBlock: Decodable {
    let type: String
    let text: String?
}

struct AnthropicUsage: Decodable {
    let inputTokens: Int
    let outputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

// MARK: - Streaming Response Models (SSE)

/// Streaming event from Anthropic Messages API
struct AnthropicStreamEvent: Decodable {
    let type: String
    let index: Int?
    let delta: AnthropicStreamDelta?
    let contentBlock: AnthropicContentBlock?
    
    enum CodingKeys: String, CodingKey {
        case type, index, delta
        case contentBlock = "content_block"
    }
}

struct AnthropicStreamDelta: Decodable {
    let type: String?
    let text: String?
    let stopReason: String?
    
    enum CodingKeys: String, CodingKey {
        case type, text
        case stopReason = "stop_reason"
    }
}

// MARK: - Error Response

/// Error response from Anthropic API
struct AnthropicErrorResponse: Decodable {
    let type: String
    let error: AnthropicErrorDetail
}

struct AnthropicErrorDetail: Decodable {
    let type: String
    let message: String
}
