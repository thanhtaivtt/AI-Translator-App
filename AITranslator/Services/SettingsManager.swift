//
//  SettingsManager.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation
import CryptoKit
import IOKit

/// Manages app settings via UserDefaults and API keys via encrypted file storage.
///
/// API keys are AES-256-GCM encrypted and stored in the app's sandboxed
/// Application Support directory. The encryption key is derived from a
/// device-stable identifier, ensuring keys are only readable on this machine.
@Observable
final class SettingsManager {
    
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    private let storageDir: URL
    
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
        // Setup encrypted storage directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.storageDir = appSupport.appendingPathComponent("AITranslator/keys", isDirectory: true)
        try? FileManager.default.createDirectory(at: storageDir, withIntermediateDirectories: true)
        
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
    
    // MARK: - Encrypted API Key Storage
    
    /// Save an API key (encrypted) for a given provider.
    @discardableResult
    func saveAPIKey(_ key: String, for providerId: String) -> Bool {
        guard let plaintext = key.data(using: .utf8) else { return false }
        do {
            let sealed = try AES.GCM.seal(plaintext, using: encryptionKey())
            guard let combined = sealed.combined else { return false }
            try combined.write(to: fileURL(for: providerId))
            return true
        } catch {
            print("[KeyStore] Failed to save API key for \(providerId): \(error)")
            return false
        }
    }
    
    /// Retrieve a decrypted API key for a given provider.
    func getAPIKey(for providerId: String) -> String? {
        let url = fileURL(for: providerId)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let box = try AES.GCM.SealedBox(combined: data)
            let decrypted = try AES.GCM.open(box, using: encryptionKey())
            return String(data: decrypted, encoding: .utf8)
        } catch {
            print("[KeyStore] Failed to read API key for \(providerId): \(error)")
            return nil
        }
    }
    
    /// Delete an API key.
    func deleteAPIKey(for providerId: String) {
        try? FileManager.default.removeItem(at: fileURL(for: providerId))
    }
    
    /// Check if an API key exists for a provider.
    func hasAPIKey(for providerId: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: providerId).path)
    }
    
    /// Get the effective system prompt (custom if set, otherwise default)
    var effectiveSystemPrompt: String {
        customSystemPrompt.isEmpty ? AppDefaults.defaultSystemPrompt : customSystemPrompt
    }
    
    // MARK: - Private
    
    private func fileURL(for providerId: String) -> URL {
        storageDir.appendingPathComponent("\(providerId).key")
    }
    
    /// Derive a stable encryption key from machine-specific data.
    /// The key is deterministic per-machine so it survives app restarts.
    private func encryptionKey() -> SymmetricKey {
        // Use hardware UUID as seed — unique per Mac, stable across reboots
        let seed = machineID()
        let salt = "me.taivt.AITranslator.keystore"
        let keyMaterial = SHA256.hash(data: Data((seed + salt).utf8))
        return SymmetricKey(data: keyMaterial)
    }
    
    /// Get a stable machine identifier (hardware UUID).
    private func machineID() -> String {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(service) }
        if let uuid = IORegistryEntryCreateCFProperty(service, "IOPlatformUUID" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String {
            return uuid
        }
        return "fallback-\(ProcessInfo.processInfo.hostName)"
    }
}
