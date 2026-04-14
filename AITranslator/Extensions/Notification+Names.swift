//
//  Notification+Names.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import Foundation

/// Centralized notification names used across the app (BUG-5 fix).
extension Notification.Name {
    /// Posted when the menu bar popover requests opening the main window.
    static let openMainWindow = Notification.Name("openMainWindow")
}
