//
//  TranslateView.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import SwiftUI

/// Main translation view with split-panel layout.
/// Left panel: source text input | Right panel: translated text output
struct TranslateView: View {
    
    @Bindable var viewModel: TranslationViewModel
    @FocusState private var isSourceFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Language selector bar
            languageBar
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
            
            // Split panels
            HSplitView {
                sourcePanel
                    .frame(minWidth: 280)
                targetPanel
                    .frame(minWidth: 280)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            // Status bar
            statusBar
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
    }
    
    // MARK: - Language Bar
    
    private var languageBar: some View {
        HStack(spacing: 16) {
            LanguagePicker(
                title: "Source",
                selection: $viewModel.sourceLanguage,
                languages: Language.sourceLanguages
            )
            
            // Swap button
            Button(action: viewModel.swapLanguages) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.accentPrimary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(Color.accentPrimary.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.sourceLanguage == .auto)
            .opacity(viewModel.sourceLanguage == .auto ? 0.4 : 1.0)
            .help("Swap languages")
            
            LanguagePicker(
                title: "Target",
                selection: $viewModel.targetLanguage,
                languages: Language.targetLanguages
            )
            
            Spacer()
            
            // Translate button (visible in manual mode)
            translateButton
        }
    }
    
    // MARK: - Source Panel
    
    private var sourcePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Source", systemImage: "text.cursor")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.textSecondary)
                
                Spacer()
                
                if !viewModel.sourceText.isEmpty {
                    Text("\(viewModel.sourceText.count) chars")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.textTertiary)
                }
            }
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.sourceText)
                    .font(.system(.body, design: .default))
                    .scrollContentBackground(.hidden)
                    .focused($isSourceFocused)
                    .onChange(of: viewModel.sourceText) { _, _ in
                        viewModel.sourceTextDidChange()
                    }
                
                if viewModel.sourceText.isEmpty {
                    Text("Enter text to translate...")
                        .font(.system(.body, design: .default))
                        .foregroundStyle(.textTertiary)
                        .padding(.top, 1)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSourceFocused ? Color.accentPrimary.opacity(0.5) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
            
            // Source actions
            HStack(spacing: 8) {
                Button(action: {
                    // Paste from clipboard
                    if let text = NSPasteboard.general.string(forType: .string) {
                        viewModel.sourceText = text
                        viewModel.sourceTextDidChange()
                    }
                }) {
                    Label("Paste", systemImage: "doc.on.clipboard")
                        .font(.system(.caption, design: .rounded))
                }
                .buttonStyle(.borderless)
                
                Button(action: viewModel.clearAll) {
                    Label("Clear", systemImage: "xmark.circle")
                        .font(.system(.caption, design: .rounded))
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.sourceText.isEmpty)
                
                Spacer()
            }
        }
        .padding(8)
    }
    
    // MARK: - Target Panel
    
    private var targetPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Translation", systemImage: "text.quote")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.textSecondary)
                
                Spacer()
                
                if viewModel.isTranslating {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 4)
                    
                    Text("Translating...")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.accentPrimary)
                }
            }
            
            ZStack(alignment: .topLeading) {
                // Translated text (read-only, selectable)
                ScrollView {
                    Text(viewModel.translatedText)
                        .font(.system(.body, design: .default))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if viewModel.translatedText.isEmpty && !viewModel.isTranslating {
                    Text("Translation will appear here...")
                        .font(.system(.body, design: .default))
                        .foregroundStyle(.textTertiary)
                        .padding(12)
                        .padding(.top, 1)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
            
            // Target actions
            HStack(spacing: 8) {
                Button(action: viewModel.copyTranslation) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.system(.caption, design: .rounded))
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.translatedText.isEmpty)
                
                if viewModel.isTranslating {
                    Button(action: viewModel.stopTranslation) {
                        Label("Stop", systemImage: "stop.circle")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.destructive)
                    }
                    .buttonStyle(.borderless)
                }
                
                Spacer()
                
                if let time = viewModel.formattedTranslationTime {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(time)
                            .font(.system(.caption2, design: .monospaced))
                    }
                    .foregroundStyle(.textTertiary)
                }
            }
            
            // Error display
            if let error = viewModel.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.warning)
                    Text(error)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.destructive)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.destructive.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(8)
    }
    
    // MARK: - Translate Button
    
    @ViewBuilder
    private var translateButton: some View {
        Button(action: viewModel.translateNow) {
            HStack(spacing: 6) {
                if viewModel.isTranslating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 14))
                }
                Text("Translate")
                    .font(.system(.body, design: .rounded, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.brandGradient, in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canTranslate)
        .opacity(viewModel.canTranslate ? 1.0 : 0.5)
        .keyboardShortcut(.return, modifiers: .command)
    }
    
    // MARK: - Status Bar
    
    private var statusBar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.success)
                    .frame(width: 6, height: 6)
                Text(viewModel.currentProviderName)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.textSecondary)
            }
            
            Divider()
                .frame(height: 12)
            
            HStack(spacing: 6) {
                Image(systemName: "cpu")
                    .font(.caption2)
                    .foregroundStyle(.textTertiary)
                Text(viewModel.currentModelName)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.textSecondary)
            }
            
            Spacer()
            
            Text("⌘↵ Translate")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.textTertiary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
