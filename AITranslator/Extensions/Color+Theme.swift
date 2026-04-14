//
//  Color+Theme.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import SwiftUI

extension Color {
    
    // MARK: - Primary Palette
    
    /// Main accent color — vibrant blue-purple gradient start
    static let accentPrimary = Color(hue: 0.65, saturation: 0.75, brightness: 0.90)
    
    /// Secondary accent — complementary warm tone
    static let accentSecondary = Color(hue: 0.55, saturation: 0.60, brightness: 0.85)
    
    /// Tertiary accent — for highlights and micro-interactions
    static let accentTertiary = Color(hue: 0.80, saturation: 0.55, brightness: 0.85)
    
    // MARK: - Surface Colors
    
    /// Card/panel background
    static let surfacePrimary = Color(nsColor: .controlBackgroundColor)
    
    /// Slightly elevated surface
    static let surfaceElevated = Color(nsColor: .windowBackgroundColor)
    
    /// Grouped content background
    static let surfaceGrouped = Color(nsColor: .underPageBackgroundColor)
    
    // MARK: - Text Colors
    
    /// Primary text
    static let textPrimary = Color(nsColor: .labelColor)
    
    /// Secondary / muted text
    static let textSecondary = Color(nsColor: .secondaryLabelColor)
    
    /// Tertiary / placeholder text
    static let textTertiary = Color(nsColor: .tertiaryLabelColor)
    
    // MARK: - Semantic Colors
    
    /// Success / completed
    static let success = Color(hue: 0.38, saturation: 0.70, brightness: 0.72)
    
    /// Warning
    static let warning = Color(hue: 0.10, saturation: 0.75, brightness: 0.90)
    
    /// Error / destructive
    static let destructive = Color(hue: 0.0, saturation: 0.70, brightness: 0.85)
    
    // MARK: - Gradient Presets
    
    /// App brand gradient
    static let brandGradient = LinearGradient(
        colors: [accentPrimary, accentSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Subtle background gradient
    static let subtleGradient = LinearGradient(
        colors: [
            Color(hue: 0.65, saturation: 0.08, brightness: 0.98),
            Color(hue: 0.55, saturation: 0.06, brightness: 0.96)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - ShapeStyle Convenience
// Allows using .foregroundStyle(.textSecondary) etc. without Color. prefix

extension ShapeStyle where Self == Color {
    
    // Primary Palette
    static var accentPrimary: Color { Color.accentPrimary }
    static var accentSecondary: Color { Color.accentSecondary }
    static var accentTertiary: Color { Color.accentTertiary }
    
    // Surface Colors
    static var surfacePrimary: Color { Color.surfacePrimary }
    static var surfaceElevated: Color { Color.surfaceElevated }
    static var surfaceGrouped: Color { Color.surfaceGrouped }
    
    // Text Colors
    static var textPrimary: Color { Color.textPrimary }
    static var textSecondary: Color { Color.textSecondary }
    static var textTertiary: Color { Color.textTertiary }
    
    // Semantic Colors
    static var success: Color { Color.success }
    static var warning: Color { Color.warning }
    static var destructive: Color { Color.destructive }
}

// MARK: - View Modifiers

extension View {
    /// Apply a glassmorphism card style
    func glassCard(cornerRadius: CGFloat = 12) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
    }
    
    /// Subtle shadow for elevated elements
    func softShadow() -> some View {
        self.shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}
