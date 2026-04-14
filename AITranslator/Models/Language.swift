//
//  Language.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation

/// Enum representing supported languages for translation.
/// Each case includes a display name and flag emoji for UI rendering.
enum Language: String, CaseIterable, Identifiable, Codable {
    case auto = "auto"
    case vietnamese = "vi"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"
    case chinese = "zh"
    case french = "fr"
    case german = "de"
    case spanish = "es"
    case thai = "th"
    case portuguese = "pt"
    case russian = "ru"
    case italian = "it"
    
    var id: String { rawValue }
    
    var code: String { rawValue }
    
    var displayName: String {
        switch self {
        case .auto: return "Auto Detect"
        case .vietnamese: return "Tiếng Việt"
        case .english: return "English"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .chinese: return "中文"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .spanish: return "Español"
        case .thai: return "ไทย"
        case .portuguese: return "Português"
        case .russian: return "Русский"
        case .italian: return "Italiano"
        }
    }
    
    var flag: String {
        switch self {
        case .auto: return "🔍"
        case .vietnamese: return "🇻🇳"
        case .english: return "🇺🇸"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .chinese: return "🇨🇳"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .spanish: return "🇪🇸"
        case .thai: return "🇹🇭"
        case .portuguese: return "🇧🇷"
        case .russian: return "🇷🇺"
        case .italian: return "🇮🇹"
        }
    }
    
    /// All languages available as source (includes auto detect)
    static var sourceLanguages: [Language] {
        Language.allCases
    }
    
    /// All languages available as target (excludes auto detect)
    static var targetLanguages: [Language] {
        Language.allCases.filter { $0 != .auto }
    }
    
    /// Returns the language name in English for use in prompts
    var englishName: String {
        switch self {
        case .auto: return "Auto Detect"
        case .vietnamese: return "Vietnamese"
        case .english: return "English"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .chinese: return "Chinese"
        case .french: return "French"
        case .german: return "German"
        case .spanish: return "Spanish"
        case .thai: return "Thai"
        case .portuguese: return "Portuguese"
        case .russian: return "Russian"
        case .italian: return "Italian"
        }
    }
}
