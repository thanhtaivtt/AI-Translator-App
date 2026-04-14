//
//  QuickTranslateView.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import SwiftUI

/// Compact translation view shown in the menu bar popover.
/// Designed for quick, instant translations without opening the full app.
struct QuickTranslateView: View {
    
    @Bindable var viewModel: TranslationViewModel
    @FocusState private var isSourceFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Language bar
            languageBar
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            
            // Source input
            sourceInput
                .padding(.horizontal, 16)
            
            // Divider with translate button
            translateBar
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            // Translation output
            translationOutput
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            
            // Footer
            footer
        }
        .frame(width: 520, height: 420)
        .background(Color.surfaceElevated)
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.accentPrimary)
                Text("AI Translator")
                    .font(.system(.headline, design: .rounded))
            }
            
            Spacer()
            
            Button(action: openMainWindow) {
                Image(systemName: "arrow.up.forward.square")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
            }
            .buttonStyle(.borderless)
            .help("Open main window")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Language Bar
    
    private var languageBar: some View {
        HStack(spacing: 12) {
            LanguagePicker(
                title: "Source",
                selection: $viewModel.sourceLanguage,
                languages: Language.sourceLanguages
            )
            
            Button(action: viewModel.swapLanguages) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentPrimary)
                    .frame(width: 28, height: 28)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.sourceLanguage == .auto)
            .opacity(viewModel.sourceLanguage == .auto ? 0.4 : 1.0)
            
            LanguagePicker(
                title: "Target",
                selection: $viewModel.targetLanguage,
                languages: Language.targetLanguages
            )
            
            Spacer()
        }
    }
    
    // MARK: - Source Input
    
    private var sourceInput: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $viewModel.sourceText)
                .font(.system(.body, design: .default))
                .scrollContentBackground(.hidden)
                .focused($isSourceFocused)
                .onChange(of: viewModel.sourceText) { _, _ in
                    viewModel.sourceTextDidChange()
                }
            
            if viewModel.sourceText.isEmpty {
                Text("Type or paste text to translate...")
                    .font(.system(.body, design: .default))
                    .foregroundStyle(Color.textTertiary)
                    .padding(.top, 1)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: 100)
        .padding(10)
        .background(Color.surfacePrimary, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isSourceFocused ? Color.accentPrimary.opacity(0.5) : Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - Translate Bar
    
    private var translateBar: some View {
        HStack {
            // Paste button
            Button(action: {
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
            
            // Translate button
            Button(action: viewModel.translateNow) {
                HStack(spacing: 5) {
                    if viewModel.isTranslating {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 12))
                    }
                    Text("Translate")
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.brandGradient, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canTranslate)
            .opacity(viewModel.canTranslate ? 1.0 : 0.5)
            .keyboardShortcut(.return, modifiers: .command)
        }
    }
    
    // MARK: - Translation Output
    
    private var translationOutput: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                ScrollView {
                    Text(viewModel.translatedText)
                        .font(.system(.body, design: .default))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(10)
                }
                
                if viewModel.translatedText.isEmpty && !viewModel.isTranslating {
                    Text("Translation...")
                        .font(.system(.body, design: .default))
                        .foregroundStyle(Color.textTertiary)
                        .padding(10)
                        .padding(.top, 1)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
                
                if viewModel.isTranslating && viewModel.translatedText.isEmpty {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Translating...")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Color.accentPrimary)
                    }
                    .padding(10)
                }
            }
            .frame(height: 100)
            .background(Color.surfacePrimary, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
            
            // Output actions
            HStack(spacing: 8) {
                Button(action: viewModel.copyTranslation) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.system(.caption, design: .rounded))
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.translatedText.isEmpty)
                
                Spacer()
                
                if let time = viewModel.formattedTranslationTime {
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                        Text(time)
                            .font(.system(.caption2, design: .monospaced))
                    }
                    .foregroundStyle(Color.textTertiary)
                }
                
                Text("⌘↵")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(Color.textTertiary)
            }
            
            // Error
            if let error = viewModel.errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.warning)
                    Text(error)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(Color.destructive)
                        .lineLimit(2)
                }
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.destructive.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.success)
                    .frame(width: 5, height: 5)
                Text(viewModel.currentProviderName)
                    .font(.system(.caption2, design: .rounded))
            }
            
            Text("·")
            
            HStack(spacing: 3) {
                Image(systemName: "cpu")
                    .font(.system(size: 8))
                Text(viewModel.currentModelName)
                    .font(.system(.caption2, design: .rounded))
            }
            
            Spacer()
        }
        .foregroundStyle(Color.textTertiary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Actions
    
    private func openMainWindow() {
        // Close the popover first
        NSApp.activate(ignoringOtherApps: true)
        
        // Find an existing main window (filter out status bar windows, panels, popovers)
        let mainWindow = NSApp.windows.first(where: { window in
            window.canBecomeKey &&
            !(window is NSPanel) &&
            !window.className.contains("StatusBar")
        })
        
        if let window = mainWindow {
            // Main window exists — bring it to front
            window.makeKeyAndOrderFront(nil)
        } else {
            // Main window was closed — post notification to reopen
            NotificationCenter.default.post(name: .openMainWindow, object: nil)
        }
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let openMainWindow = Notification.Name("openMainWindow")
}
