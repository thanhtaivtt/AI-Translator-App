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
    /// When true, ⌘Q actually quits instead of hiding
    var shouldReallyQuit = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Enforce single instance: disable "New Window" menu item
        NSApp.mainMenu?.item(withTitle: "File")?.submenu?.item(withTitle: "New Window")?.isHidden = true
        
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
    
    /// Intercept ⌘Q — hide app instead of quitting (tray stays alive)
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if shouldReallyQuit { return .terminateNow }
        hideApp()
        return .terminateCancel
    }
    
    /// Block ⌘N — redirect to showing existing window
    @objc func newWindowForTab(_ sender: Any?) {
        showMainWindow()
    }
    
    // MARK: - NSWindowDelegate
    
    /// Hide the window and remove from ⌘Tab instead of destroying it
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hideApp()
        return false
    }
    
    // MARK: - Window Management
    
    /// Hide window and switch to accessory mode (removes from ⌘Tab, keeps tray)
    func hideApp() {
        mainWindow?.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
    }
    
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
            // Restore in ⌘Tab and show window
            NSApp.setActivationPolicy(.regular)
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
    
    // Shared services (BUG-1 fix: single instances shared across main window & menu bar)
    private let translationService: TranslationService
    private let historyStore: HistoryStore
    
    // Shared ViewModels
    @State private var translationVM: TranslationViewModel
    @State private var historyVM: HistoryViewModel
    @State private var settingsVM: SettingsViewModel
    
    // Menu bar
    @State private var menuBarManager = MenuBarManager()
    
    // Update checker
    @State private var updateChecker = UpdateChecker()
    
    init() {
        let settings = SettingsManager.shared
        let reg = ProviderRegistry.shared
        
        // Initialize SwiftData
        let container: ModelContainer
        do {
            let schema = Schema([TranslationRecord.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to initialize SwiftData: \(error)")
        }
        self.modelContainer = container
        
        // Register LLM providers
        reg.registerDefaults(settingsManager: settings)
        
        // Create shared services — single instances used by both main window and menu bar
        let service = TranslationService(registry: reg, settingsManager: settings)
        let store = HistoryStore(modelContext: container.mainContext)
        self.translationService = service
        self.historyStore = store
        
        // Create shared ViewModels
        _translationVM = State(initialValue: TranslationViewModel(
            translationService: service,
            settingsManager: settings,
            historyStore: store
        ))
        _historyVM = State(initialValue: HistoryViewModel(historyStore: store))
        _settingsVM = State(initialValue: SettingsViewModel(
            settingsManager: settings,
            registry: reg
        ))
    }
    
    var body: some Scene {
        // Main window
        WindowGroup {
            ContentView(
                translationVM: translationVM,
                historyVM: historyVM,
                settingsVM: settingsVM
            )
            .onAppear {
                setupMenuBar()
                checkForUpdates()
            }
        }
        .modelContainer(modelContainer)
        .windowStyle(.automatic)
        .defaultSize(width: 900, height: 650)
        .commands {
            // Remove "New Window" (⌘N) — single window app
            CommandGroup(replacing: .newItem) { }
        }
    }
    
    // MARK: - Menu Bar Setup
    
    private func setupMenuBar() {
        // Menu bar gets its own TranslationViewModel (separate state)
        // but shares the same service & history store — no duplicate instances
        let quickVM = TranslationViewModel(
            translationService: translationService,
            settingsManager: settingsManager,
            historyStore: historyStore
        )
        
        let quickView = QuickTranslateView(viewModel: quickVM)
        menuBarManager.setup(with: quickView)
    }
    
    // MARK: - Update Check
    
    private func checkForUpdates() {
        updateChecker.checkForUpdates()
        
        // Show alert after a short delay to let the UI settle
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            updateChecker.showUpdateAlertIfNeeded()
        }
    }
}
