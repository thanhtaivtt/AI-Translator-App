//
//  SettingsManager.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation
import Security

/// Manages app settings via UserDefaults and API keys via Keychain.
@Observable
final class SettingsManager {
    
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    private let keychainService = "me.taivt.AITranslator"
    
    // MARK: - Published Settings
    
    var selectedProviderId: String {
        didSet { defaults.set(selectedProviderId, forKey: SettingsKey.selectedProviderId.rawValue) }
    }
    
    var selectedModelId: String {
        didSet { defaults.set(selectedModelId, forKey: SettingsKey.selectedModelId.rawValue) }
    }
    
    var sourceLanguage: Language {
        didSet { defaults.set(sourceLanguage.rawValue, forKey: SettingsKey.sourceLanguage.rawValue) }
    }
    
    var targetLanguage: Language {
        didSet { defaults.set(targetLanguage.rawValue, forKey: SettingsKey.targetLanguage.rawValue) }
    }
    
    var translationMode: TranslationMode {
        didSet { defaults.set(translationMode.rawValue, forKey: SettingsKey.translationMode.rawValue) }
    }
    
    var customSystemPrompt: String {
        didSet { defaults.set(customSystemPrompt, forKey: SettingsKey.customSystemPrompt.rawValue) }
    }
    
    var autoTranslateDelay: TimeInterval {
        didSet { defaults.set(autoTranslateDelay, forKey: SettingsKey.autoTranslateDelay.rawValue) }
    }
    
    // MARK: - Init
    
    private init() {
        self.selectedProviderId = defaults.string(forKey: SettingsKey.selectedProviderId.rawValue)
            ?? AppDefaults.providerId
        
        self.selectedModelId = defaults.string(forKey: SettingsKey.selectedModelId.rawValue)
            ?? AppDefaults.modelId
        
        if let langCode = defaults.string(forKey: SettingsKey.sourceLanguage.rawValue),
           let lang = Language(rawValue: langCode) {
            self.sourceLanguage = lang
        } else {
            self.sourceLanguage = AppDefaults.sourceLanguage
        }
        
        if let langCode = defaults.string(forKey: SettingsKey.targetLanguage.rawValue),
           let lang = Language(rawValue: langCode) {
            self.targetLanguage = lang
        } else {
            self.targetLanguage = AppDefaults.targetLanguage
        }
        
        if let modeStr = defaults.string(forKey: SettingsKey.translationMode.rawValue),
           let mode = TranslationMode(rawValue: modeStr) {
            self.translationMode = mode
        } else {
            self.translationMode = AppDefaults.translationMode
        }
        
        self.customSystemPrompt = defaults.string(forKey: SettingsKey.customSystemPrompt.rawValue)
            ?? AppDefaults.customSystemPrompt
        
        let delay = defaults.double(forKey: SettingsKey.autoTranslateDelay.rawValue)
        self.autoTranslateDelay = delay > 0 ? delay : AppDefaults.autoTranslateDelay
    }
    
    // MARK: - Keychain API Key Management
    
    /// Save an API key to Keychain for a given provider.
    /// Returns true if save succeeded, false otherwise.
    @discardableResult
    func saveAPIKey(_ key: String, for providerId: String) -> Bool {
        let account = "apikey-\(providerId)"
        
        // Delete existing key first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new key
        guard let data = key.data(using: .utf8) else { return false }
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            print("[Keychain] Failed to save API key for \(providerId): OSStatus \(status)")
        }
        return status == errSecSuccess
    }
    
    /// Retrieve an API key from Keychain for a given provider
    func getAPIKey(for providerId: String) -> String? {
        let account = "apikey-\(providerId)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    /// Delete an API key from Keychain
    func deleteAPIKey(for providerId: String) {
        let account = "apikey-\(providerId)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    /// Check if an API key exists for a provider
    func hasAPIKey(for providerId: String) -> Bool {
        getAPIKey(for: providerId) != nil
    }
    
    /// Get the effective system prompt (custom if set, otherwise default)
    var effectiveSystemPrompt: String {
        customSystemPrompt.isEmpty ? AppDefaults.defaultSystemPrompt : customSystemPrompt
    }
}
