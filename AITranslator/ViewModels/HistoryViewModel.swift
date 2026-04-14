//
//  HistoryViewModel.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation
import SwiftData
import AppKit

/// ViewModel for the history tab.
@Observable
final class HistoryViewModel {
    
    var searchText: String = ""
    var selectedRecord: TranslationRecord? = nil
    
    private let historyStore: HistoryStore
    
    init(historyStore: HistoryStore) {
        self.historyStore = historyStore
    }
    
    /// Delete a record
    func delete(_ record: TranslationRecord) {
        if selectedRecord == record {
            selectedRecord = nil
        }
        historyStore.delete(record)
    }
    
    /// Delete all records
    func deleteAll() {
        selectedRecord = nil
        historyStore.deleteAll()
    }
    
    /// Copy translated text to clipboard
    func copyTranslation(_ record: TranslationRecord) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(record.translatedText, forType: .string)
    }
    
    /// Copy source text to clipboard
    func copySource(_ record: TranslationRecord) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(record.sourceText, forType: .string)
    }
}
