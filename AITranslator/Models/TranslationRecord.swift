//
//  TranslationRecord.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation
import SwiftData

/// SwiftData model representing a saved translation record.
@Model
final class TranslationRecord {
    var sourceText: String
    var translatedText: String
    var sourceLanguageCode: String
    var targetLanguageCode: String
    var providerName: String
    var modelName: String
    var timestamp: Date
    var translationDuration: TimeInterval?
    
    init(
        sourceText: String,
        translatedText: String,
        sourceLanguage: Language,
        targetLanguage: Language,
        providerName: String,
        modelName: String,
        translationDuration: TimeInterval? = nil
    ) {
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.sourceLanguageCode = sourceLanguage.rawValue
        self.targetLanguageCode = targetLanguage.rawValue
        self.providerName = providerName
        self.modelName = modelName
        self.timestamp = Date()
        self.translationDuration = translationDuration
    }
    
    /// Computed: source language enum
    var sourceLanguage: Language? {
        Language(rawValue: sourceLanguageCode)
    }
    
    /// Computed: target language enum
    var targetLanguage: Language? {
        Language(rawValue: targetLanguageCode)
    }
    
    /// Cached date formatter (BUG-3 fix: avoid creating new instance per call)
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
    
    /// Formatted timestamp
    var formattedDate: String {
        Self.dateFormatter.string(from: timestamp)
    }
    
    /// Short preview of source text (for list display)
    var sourcePreview: String {
        let limit = 80
        if sourceText.count <= limit { return sourceText }
        return String(sourceText.prefix(limit)) + "…"
    }
}
