//
//  SettingsView.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import SwiftUI

/// Settings tab with provider configuration, model selection, and preferences.
struct SettingsView: View {
    
    @Bindable var viewModel: SettingsViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Provider Section
                providerSection
                
                Divider()
                
                // API Key Section
                apiKeySection
                
                Divider()
                
                // Model Section
                modelSection
                
                Divider()
                
                // Default Languages Section
                languagesSection
                
                Divider()
                
                // Translation Mode Section
                translationModeSection
                
                Divider()
                
                // Custom Prompt Section
                customPromptSection
            }
            .padding(32)
        }
        .frame(maxWidth: 640)
    }
    
    // MARK: - Provider Section
    
    private var providerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            settingHeader(title: "Translation Provider", icon: "server.rack", description: "Select which AI service to use for translations")
            
            Picker("Provider", selection: Binding(
                get: { viewModel.settingsManager.selectedProviderId },
                set: { newValue in
                    viewModel.settingsManager.selectedProviderId = newValue
                    viewModel.providerDidChange()
                }
            )) {
                ForEach(viewModel.registry.allProviders, id: \.id) { provider in
                    Text(provider.displayName).tag(provider.id)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    // MARK: - API Key Section
    
    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            settingHeader(title: "API Key", icon: "key.fill", description: "Stored securely in your Mac's Keychain")
            
            HStack(spacing: 10) {
                Group {
                    if viewModel.showAPIKey {
                        TextField("Enter API key...", text: $viewModel.apiKeyInput)
                    } else {
                        SecureField("Enter API key...", text: $viewModel.apiKeyInput)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                
                Button(action: { viewModel.showAPIKey.toggle() }) {
                    Image(systemName: viewModel.showAPIKey ? "eye.slash" : "eye")
                        .font(.system(size: 14))
                }
                .buttonStyle(.borderless)
                .help(viewModel.showAPIKey ? "Hide API key" : "Show API key")
                
                Button("Save") {
                    viewModel.saveAPIKey()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                if viewModel.settingsManager.hasAPIKey(for: viewModel.settingsManager.selectedProviderId) {
                    Button(action: viewModel.deleteAPIKey) {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.destructive)
                    }
                    .buttonStyle(.borderless)
                    .help("Remove API key")
                }
            }
            
            if let status = viewModel.apiKeySaveStatus {
                Text(status)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(status.contains("✓") ? Color.success : Color.warning)
                    .transition(.opacity)
            }
        }
    }
    
    // MARK: - Model Section
    
    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            settingHeader(title: "Model", icon: "cpu", description: "Choose the AI model for translations")
            
            Picker("Model", selection: Binding(
                get: { viewModel.settingsManager.selectedModelId },
                set: { viewModel.settingsManager.selectedModelId = $0 }
            )) {
                ForEach(viewModel.availableModels) { model in
                    Text(model.displayName).tag(model.id)
                }
            }
            .pickerStyle(.radioGroup)
        }
    }
    
    // MARK: - Languages Section
    
    private var languagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            settingHeader(title: "Default Languages", icon: "globe", description: "Languages selected when the app starts")
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Source")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                    Picker("Source Language", selection: Binding(
                        get: { viewModel.settingsManager.sourceLanguage },
                        set: { viewModel.settingsManager.sourceLanguage = $0 }
                    )) {
                        ForEach(Language.sourceLanguages) { lang in
                            Text("\(lang.flag) \(lang.displayName)").tag(lang)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 180)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Target")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                    Picker("Target Language", selection: Binding(
                        get: { viewModel.settingsManager.targetLanguage },
                        set: { viewModel.settingsManager.targetLanguage = $0 }
                    )) {
                        ForEach(Language.targetLanguages) { lang in
                            Text("\(lang.flag) \(lang.displayName)").tag(lang)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 180)
                }
            }
        }
    }
    
    // MARK: - Translation Mode Section
    
    private var translationModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            settingHeader(title: "Translation Mode", icon: "gearshape.2", description: "How translation is triggered")
            
            Picker("Mode", selection: Binding(
                get: { viewModel.settingsManager.translationMode },
                set: { viewModel.settingsManager.translationMode = $0 }
            )) {
                ForEach(TranslationMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 300)
            
            if viewModel.settingsManager.translationMode == .auto {
                HStack(spacing: 12) {
                    Text("Delay:")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                    
                    Slider(
                        value: Binding(
                            get: { viewModel.settingsManager.autoTranslateDelay },
                            set: { viewModel.settingsManager.autoTranslateDelay = $0 }
                        ),
                        in: 0.3...3.0,
                        step: 0.1
                    )
                    .frame(width: 200)
                    
                    Text(String(format: "%.1fs", viewModel.settingsManager.autoTranslateDelay))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 40)
                }
            }
        }
    }
    
    // MARK: - Custom Prompt Section
    
    private var customPromptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                settingHeader(title: "Custom System Prompt", icon: "text.bubble", description: "Customize how the AI translates (leave empty for default)")
                
                Spacer()
                
                if !viewModel.settingsManager.customSystemPrompt.isEmpty {
                    Button("Reset to Default") {
                        viewModel.resetPromptToDefault()
                    }
                    .buttonStyle(.borderless)
                    .font(.system(.caption, design: .rounded))
                }
            }
            
            TextEditor(text: Binding(
                get: { viewModel.settingsManager.customSystemPrompt },
                set: { viewModel.settingsManager.customSystemPrompt = $0 }
            ))
                .font(.system(.body, design: .monospaced, weight: .regular))
                .scrollContentBackground(.hidden)
                .frame(height: 100)
                .padding(10)
                .background(Color.surfacePrimary, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
            
            if viewModel.settingsManager.customSystemPrompt.isEmpty {
                Text("Default: \"\(AppDefaults.defaultSystemPrompt.prefix(80))...\"")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(Color.textTertiary)
                    .lineLimit(2)
            }
        }
    }
    
    // MARK: - Helper
    
    private func settingHeader(title: String, icon: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.system(.headline, design: .rounded))
            
            Text(description)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Color.textSecondary)
        }
    }
}
