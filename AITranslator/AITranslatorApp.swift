//
//  AITranslatorApp.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import SwiftUI
import SwiftData

// MARK: - App Delegate

/// Handles macOS application lifecycle events.
/// Intercepts window close to hide instead of destroy (menu bar app pattern).
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    
    /// Reference to the main SwiftUI window
    weak var mainWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Listen for "open main window" requests from the menu bar popover
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenMainWindow),
            name: .openMainWindow,
            object: nil
        )
        
        // Capture the main window after SwiftUI creates it
        DispatchQueue.main.async { [weak self] in
            self?.captureMainWindow()
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showMainWindow()
        }
        return true
    }
    
    /// Prevent app from terminating when last window closes (keep menu bar alive)
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    // MARK: - NSWindowDelegate
    
    /// Hide the window instead of destroying it
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)  // Hide, don't destroy
        return false
    }
    
    // MARK: - Window Management
    
    private func captureMainWindow() {
        guard mainWindow == nil else { return }
        
        if let window = NSApp.windows.first(where: { window in
            window.canBecomeKey &&
            !(window is NSPanel) &&
            !window.className.contains("StatusBar")
        }) {
            mainWindow = window
            window.delegate = self
            window.isReleasedWhenClosed = false
        }
    }
    
    @objc private func handleOpenMainWindow() {
        showMainWindow()
    }
    
    func showMainWindow() {
        // Try to recapture if lost
        if mainWindow == nil {
            captureMainWindow()
        }
        
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

// MARK: - App

@main
struct AITranslatorApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    // Core dependencies
    private let settingsManager = SettingsManager.shared
    private let registry = ProviderRegistry.shared
    
    // SwiftData container
    private let modelContainer: ModelContainer
    
    // Menu bar
    @State private var menuBarManager = MenuBarManager()
    
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
        // Main window
        WindowGroup {
            ContentView(
                settingsManager: settingsManager,
                registry: registry,
                modelContext: modelContainer.mainContext
            )
            .onAppear {
                setupMenuBar()
            }
        }
        .modelContainer(modelContainer)
        .windowStyle(.automatic)
        .defaultSize(width: 900, height: 650)
    }
    
    // MARK: - Menu Bar Setup
    
    private func setupMenuBar() {
        let translationService = TranslationService(
            registry: registry,
            settingsManager: settingsManager
        )
        let historyStore = HistoryStore(modelContext: modelContainer.mainContext)
        
        let quickVM = TranslationViewModel(
            translationService: translationService,
            settingsManager: settingsManager,
            historyStore: historyStore
        )
        
        let quickView = QuickTranslateView(viewModel: quickVM)
        menuBarManager.setup(with: quickView)
    }
}
