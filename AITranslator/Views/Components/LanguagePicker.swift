//
//  LanguagePicker.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import SwiftUI

/// Reusable language selection dropdown with flag emoji display.
struct LanguagePicker: View {
    let title: String
    @Binding var selection: Language
    let languages: [Language]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundStyle(.textTertiary)
            
            Menu {
            ForEach(languages) { language in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = language
                    }
                }) {
                    HStack(spacing: 8) {
                        Text("\(language.flag) \(language.code.uppercased())")
                        Text(language.displayName)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(selection.flag)
                    .font(.title3)
                Text(selection.displayName)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        }
    }
}

#Preview {
    @Previewable @State var lang = Language.english
    LanguagePicker(
        title: "Source",
        selection: $lang,
        languages: Language.sourceLanguages
    )
    .padding()
}
