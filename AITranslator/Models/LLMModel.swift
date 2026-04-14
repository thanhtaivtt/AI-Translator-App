//
//  LLMModel.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation

/// Represents an LLM model available from a provider.
struct LLMModel: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let providerId: String
    
    /// Human-readable description of the model
    var displayName: String {
        name
    }
}
