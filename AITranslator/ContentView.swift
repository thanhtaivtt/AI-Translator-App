//
//  ContentView.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import SwiftUI
import SwiftData

/// Root content view with TabView navigation.
/// BUG-1 fix: Receives pre-built ViewModels instead of creating its own service instances.
struct ContentView: View {
    
    // ViewModels (injected from AITranslatorApp)
    @State private var translationVM: TranslationViewModel
    @State private var historyVM: HistoryViewModel
    @State private var settingsVM: SettingsViewModel
    
    init(
        translationVM: TranslationViewModel,
        historyVM: HistoryViewModel,
        settingsVM: SettingsViewModel
    ) {
        _translationVM = State(initialValue: translationVM)
        _historyVM = State(initialValue: historyVM)
        _settingsVM = State(initialValue: settingsVM)
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
