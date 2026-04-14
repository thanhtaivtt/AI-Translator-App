//
//  AITranslatorApp.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import SwiftUI
import SwiftData

@main
struct AITranslatorApp: App {
    
    // Core dependencies
    private let settingsManager = SettingsManager.shared
    private let registry = ProviderRegistry.shared
    
    // SwiftData container
    private let modelContainer: ModelContainer
    
    init() {
        // Initialize SwiftData
        do {
            let schema = Schema([TranslationRecord.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to initialize SwiftData: \(error)")
        }
        
        // Register LLM providers
        registry.registerDefaults(settingsManager: settingsManager)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                settingsManager: settingsManager,
                registry: registry,
                modelContext: modelContainer.mainContext
            )
        }
        .modelContainer(modelContainer)
        .windowStyle(.automatic)
        .defaultSize(width: 900, height: 650)
    }
}
