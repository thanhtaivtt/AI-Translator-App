//
//  ContentView.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import SwiftUI
import SwiftData

/// Root content view with TabView navigation.
struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    // Dependencies
    private let settingsManager: SettingsManager
    private let registry: ProviderRegistry
    
    // ViewModels
    @State private var translationVM: TranslationViewModel
    @State private var historyVM: HistoryViewModel
    @State private var settingsVM: SettingsViewModel
    
    init(settingsManager: SettingsManager, registry: ProviderRegistry, modelContext: ModelContext) {
        self.settingsManager = settingsManager
        self.registry = registry
        
        let translationService = TranslationService(registry: registry, settingsManager: settingsManager)
        let historyStore = HistoryStore(modelContext: modelContext)
        
        _translationVM = State(initialValue: TranslationViewModel(
            translationService: translationService,
            settingsManager: settingsManager,
            historyStore: historyStore
        ))
        _historyVM = State(initialValue: HistoryViewModel(historyStore: historyStore))
        _settingsVM = State(initialValue: SettingsViewModel(
            settingsManager: settingsManager,
            registry: registry
        ))
    }
    
    var body: some View {
        TabView {
            // Tab 1: Translate
            TranslateView(viewModel: translationVM)
                .tabItem {
                    Label("Translate", systemImage: "globe")
                }
            
            // Tab 2: History
            HistoryView(viewModel: historyVM)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            
            // Tab 3: Settings
            SettingsView(viewModel: settingsVM)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}
