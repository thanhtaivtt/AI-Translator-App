//
//  AppSettings.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation

/// Translation mode: auto-translate on typing or manual button press
enum TranslationMode: String, Codable, CaseIterable {
    case auto = "auto"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .auto: return "Auto (on typing)"
        case .manual: return "Manual (button)"
        }
    }
}

/// Keys for UserDefaults storage
enum SettingsKey: String {
    case selectedProviderId = "selectedProviderId"
    case selectedModelId = "selectedModelId"
    case sourceLanguage = "sourceLanguage"
    case targetLanguage = "targetLanguage"
    case translationMode = "translationMode"
    case customSystemPrompt = "customSystemPrompt"
    case autoTranslateDelay = "autoTranslateDelay"
}

/// Default values for app settings
struct AppDefaults {
    static let providerId = "openai"
    static let modelId = "gpt-4o-mini"
    static let sourceLanguage = Language.auto
    static let targetLanguage = Language.vietnamese
    static let translationMode = TranslationMode.manual
    static let autoTranslateDelay: TimeInterval = 0.8
    static let customSystemPrompt = ""
    
    /// Default translation system prompt used when custom prompt is empty
    static let defaultSystemPrompt = """
    You are a professional translator. Translate the given text accurately and naturally. \
    Preserve the original formatting, tone, and meaning. \
    Only output the translated text without any explanations or notes.
    """
}
