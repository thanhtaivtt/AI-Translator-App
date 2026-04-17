//
//  TranslationViewModel.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for the main translation view.
/// Manages source/target text, language selection, and translation state.
@Observable
final class TranslationViewModel {
    
    // MARK: - State
    
    var sourceText: String = ""
    var translatedText: String = ""
    var sourceLanguage: Language
    var targetLanguage: Language
    
    var isTranslating: Bool = false
    var errorMessage: String? = nil
    var translationTime: TimeInterval? = nil
    
    // MARK: - Dependencies
    
    private let translationService: TranslationService
    private let settingsManager: SettingsManager
    private let historyStore: HistoryStore?
    
    // MARK: - Debounce
    
    private var debounceTask: Task<Void, Never>?
    private var translationTask: Task<Void, Never>?
    
    // MARK: - Init
    
    init(
        translationService: TranslationService,
        settingsManager: SettingsManager = .shared,
        historyStore: HistoryStore? = nil
    ) {
        self.translationService = translationService
        self.settingsManager = settingsManager
        self.historyStore = historyStore
        self.sourceLanguage = settingsManager.sourceLanguage
        self.targetLanguage = settingsManager.targetLanguage
    }
    
    // MARK: - Actions
    
    /// Called when source text changes. Handles debounce for auto-translate mode.
    func sourceTextDidChange() {
        errorMessage = nil
        
        guard settingsManager.translationMode == .auto else { return }
        
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(settingsManager.autoTranslateDelay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await performTranslation()
        }
    }
    
    /// Manually triggered translation
    func translateNow() {
        Task { @MainActor in
            await performTranslation()
        }
    }
    
    /// Swap source and target languages (and texts if applicable)
    func swapLanguages() {
        if sourceLanguage != .auto {
            let tempLang = sourceLanguage
            sourceLanguage = targetLanguage
            targetLanguage = tempLang
            settingsManager.sourceLanguage = sourceLanguage
            settingsManager.targetLanguage = targetLanguage
        }
        
        // Always swap texts
        let tempText = sourceText
        sourceText = translatedText
        translatedText = tempText
    }
    
    /// Clear both source and translated text
    func clearAll() {
        sourceText = ""
        translatedText = ""
        errorMessage = nil
        translationTime = nil
    }
    
    /// Copy translated text to clipboard
    func copyTranslation() {
        guard !translatedText.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(translatedText, forType: .string)
    }
    
    /// Stop any ongoing translation
    func stopTranslation() {
        translationTask?.cancel()
        translationTask = nil
        isTranslating = false
    }
    
    // MARK: - Translation Logic
    
    @MainActor
    private func performTranslation() async {
        let text = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            translatedText = ""
            translationTime = nil
            return
        }
        
        // Cancel any existing translation
        translationTask?.cancel()
        
        isTranslating = true
        errorMessage = nil
        translatedText = ""
        
        let startTime = Date()
        
        translationTask = Task { @MainActor in
            do {
                let stream = translationService.translateStream(
                    text: text,
                    from: sourceLanguage,
                    to: targetLanguage
                )
                
                for try await chunk in stream {
                    guard !Task.isCancelled else { return }
                    translatedText += chunk
                }
                
                translationTime = Date().timeIntervalSince(startTime)
                isTranslating = false
                
                // Save to history
                historyStore?.save(
                    sourceText: text,
                    translatedText: translatedText,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage,
                    providerName: currentProviderName,
                    modelName: currentModelName,
                    duration: translationTime
                )
                
            } catch {
                guard !Task.isCancelled else { return }
                isTranslating = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Computed
    
    var currentModelName: String {
        let provider = translationService.activeProvider
        let model = provider?.availableModels().first { $0.id == settingsManager.selectedModelId }
        return model?.displayName ?? settingsManager.selectedModelId
    }
    
    var currentProviderName: String {
        translationService.activeProvider?.displayName ?? "Not configured"
    }
    
    var canTranslate: Bool {
        !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isTranslating
    }
    
    var formattedTranslationTime: String? {
        guard let time = translationTime else { return nil }
        return String(format: "%.1fs", time)
    }
}
