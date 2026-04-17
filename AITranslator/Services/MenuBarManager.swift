//
//  MenuBarManager.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import SwiftUI
import AppKit

/// Manages the menu bar (status bar) icon and popover for quick translation.
@Observable
final class MenuBarManager: NSObject {
    
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var contextMenu: NSMenu?
    private var eventMonitor: Any?
    
    var isPopoverShown: Bool = false
    
    func setup(with contentView: some View) {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            // Use the app icon for the menu bar
            if let appIcon = NSImage(named: "AppIcon") {
                let resized = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
                    appIcon.draw(in: rect)
                    return true
                }
                resized.isTemplate = false
                button.image = resized
            } else {
                // Fallback to SF Symbol if app icon not found
                button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "AI Translator")
                button.image?.size = NSSize(width: 18, height: 18)
            }
            button.action = #selector(handleClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Create right-click context menu
        let menu = NSMenu()
        menu.addItem(withTitle: "Show Window", action: #selector(showMainWindow), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit AI Translator", action: #selector(quitApp), keyEquivalent: "q")
        for item in menu.items { item.target = self }
        self.contextMenu = menu
        
        // Create popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 520, height: 420)
        popover.behavior = .transient
        popover.animates = true
        
        let hostingController = NSHostingController(rootView: contentView)
        popover.contentViewController = hostingController
        
        self.popover = popover
        
        // Monitor clicks outside popover to close it
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }
    
    @objc private func handleClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == .rightMouseUp {
            // Right-click: show context menu
            closePopover()
            statusItem?.menu = contextMenu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil  // Reset so left-click works again
        } else {
            togglePopover()
        }
    }
    
    @objc private func togglePopover() {
        if let popover = popover, let button = statusItem?.button {
            if popover.isShown {
                closePopover()
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                isPopoverShown = true
                
                // Bring app to front
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    @objc private func showMainWindow() {
        closePopover()
        NotificationCenter.default.post(name: .openMainWindow, object: nil)
    }
    
    @objc private func quitApp() {
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.shouldReallyQuit = true
        }
        NSApp.terminate(nil)
    }
    
    func closePopover() {
        popover?.performClose(nil)
        isPopoverShown = false
    }
    
    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
