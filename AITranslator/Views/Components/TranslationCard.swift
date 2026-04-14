//
//  TranslationCard.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import SwiftUI

/// Card component displaying a single translation history entry.
struct TranslationCard: View {
    
    let record: TranslationRecord
    let isSelected: Bool
    let onCopySource: () -> Void
    let onCopyTranslation: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: languages + timestamp
            HStack {
                HStack(spacing: 4) {
                    Text(record.sourceLanguage?.flag ?? "🔍")
                    Text(record.sourceLanguage?.displayName ?? record.sourceLanguageCode)
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.textTertiary)
                    
                    Text(record.targetLanguage?.flag ?? "")
                    Text(record.targetLanguage?.displayName ?? record.targetLanguageCode)
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                }
                .foregroundStyle(.textSecondary)
                
                Spacer()
                
                Text(record.formattedDate)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.textTertiary)
            }
            
            // Source text preview
            Text(record.sourcePreview)
                .font(.system(.callout, design: .default))
                .foregroundStyle(.textPrimary)
                .lineLimit(2)
            
            // Translation preview
            Text(record.translatedText.prefix(80) + (record.translatedText.count > 80 ? "…" : ""))
                .font(.system(.callout, design: .default))
                .foregroundStyle(.accentPrimary)
                .lineLimit(2)
            
            // Footer: provider + actions
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "cpu")
                        .font(.system(size: 9))
                    Text("\(record.providerName) · \(record.modelName)")
                        .font(.system(.caption2, design: .rounded))
                }
                .foregroundStyle(.textTertiary)
                
                Spacer()
                
                if isHovered || isSelected {
                    HStack(spacing: 8) {
                        Button(action: onCopySource) {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .help("Copy source")
                        
                        Button(action: onCopyTranslation) {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.caption)
                                .foregroundStyle(.accentPrimary)
                        }
                        .buttonStyle(.borderless)
                        .help("Copy translation")
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.destructive)
                        }
                        .buttonStyle(.borderless)
                        .help("Delete")
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentPrimary.opacity(0.08) : Color.surfacePrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isSelected ? Color.accentPrimary.opacity(0.3) : Color.white.opacity(0.06),
                    lineWidth: 1
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
