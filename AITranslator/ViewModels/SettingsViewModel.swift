//
//  SettingsViewModel.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation

/// ViewModel for the settings tab.
@Observable
final class SettingsViewModel {
    
    let settingsManager: SettingsManager
    let registry: ProviderRegistry
    
    /// Temporary API key input (not persisted until save)
    var apiKeyInput: String = ""
    var showAPIKey: Bool = false
    var apiKeySaveStatus: String? = nil
    
    init(settingsManager: SettingsManager = .shared, registry: ProviderRegistry = .shared) {
        self.settingsManager = settingsManager
        self.registry = registry
        
        // Load existing API key (masked)
        if settingsManager.hasAPIKey(for: settingsManager.selectedProviderId) {
            apiKeyInput = "••••••••••••••••••••"
        }
    }
    
    /// Currently selected provider
    var selectedProvider: LLMProvider? {
        registry.provider(for: settingsManager.selectedProviderId)
    }
    
    /// Available models for the current provider
    var availableModels: [LLMModel] {
        selectedProvider?.availableModels() ?? []
    }
    
    /// Save the API key to Keychain
    func saveAPIKey() {
        let key = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, !key.hasPrefix("••") else {
            apiKeySaveStatus = "Please enter a valid API key"
            return
        }
        
        settingsManager.saveAPIKey(key, for: settingsManager.selectedProviderId)
        apiKeyInput = "••••••••••••••••••••"
        apiKeySaveStatus = "✓ API key saved securely"
        
        // Clear status after 3 seconds
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            apiKeySaveStatus = nil
        }
    }
    
    /// Delete the API key
    func deleteAPIKey() {
        settingsManager.deleteAPIKey(for: settingsManager.selectedProviderId)
        apiKeyInput = ""
        apiKeySaveStatus = "API key removed"
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            apiKeySaveStatus = nil
        }
    }
    
    /// Called when provider selection changes
    func providerDidChange() {
        // Update API key input for new provider
        if settingsManager.hasAPIKey(for: settingsManager.selectedProviderId) {
            apiKeyInput = "••••••••••••••••••••"
        } else {
            apiKeyInput = ""
        }
        showAPIKey = false
        apiKeySaveStatus = nil
        
        // Reset model to first available
        if let firstModel = availableModels.first {
            settingsManager.selectedModelId = firstModel.id
        }
    }
    
    /// Reset custom prompt to default
    func resetPromptToDefault() {
        settingsManager.customSystemPrompt = ""
    }
}
