//
//  HistoryStore.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation
import SwiftData

/// Manages CRUD operations for translation history using SwiftData.
@Observable
final class HistoryStore {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Save a new translation record
    func save(
        sourceText: String,
        translatedText: String,
        sourceLanguage: Language,
        targetLanguage: Language,
        providerName: String,
        modelName: String,
        duration: TimeInterval?
    ) {
        let record = TranslationRecord(
            sourceText: sourceText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            providerName: providerName,
            modelName: modelName,
            translationDuration: duration
        )
        modelContext.insert(record)
        try? modelContext.save()
    }
    
    /// Delete a specific record
    func delete(_ record: TranslationRecord) {
        modelContext.delete(record)
        try? modelContext.save()
    }
    
    /// Delete all records
    func deleteAll() {
        do {
            try modelContext.delete(model: TranslationRecord.self)
            try modelContext.save()
        } catch {
            print("Failed to delete all records: \(error)")
        }
    }
}
