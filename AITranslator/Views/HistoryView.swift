//
//  HistoryView.swift
//  AITranslator
//
//  Created by TaiVT on 14/4/26.
//

import SwiftUI
import SwiftData

/// History tab showing all past translations with search and detail view.
struct HistoryView: View {
    
    @Bindable var viewModel: HistoryViewModel
    @Query(sort: \TranslationRecord.timestamp, order: .reverse) private var records: [TranslationRecord]
    @State private var showDeleteAllConfirmation = false
    
    private var filteredRecords: [TranslationRecord] {
        guard !viewModel.searchText.isEmpty else { return records }
        let search = viewModel.searchText.lowercased()
        return records.filter {
            $0.sourceText.lowercased().contains(search) ||
            $0.translatedText.lowercased().contains(search)
        }
    }
    
    var body: some View {
        HSplitView {
            // List panel
            listPanel
                .frame(minWidth: 320, idealWidth: 380)
            
            // Detail panel
            detailPanel
                .frame(minWidth: 300)
        }
    }
    
    // MARK: - List Panel
    
    private var listPanel: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundStyle(.textTertiary)
                    
                    TextField("Search translations...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .rounded))
                }
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                
                if !records.isEmpty {
                    Button(action: { showDeleteAllConfirmation = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundStyle(.destructive)
                    }
                    .buttonStyle(.borderless)
                    .help("Delete all history")
                    .alert("Delete All History?", isPresented: $showDeleteAllConfirmation) {
                        Button("Delete All", role: .destructive) {
                            viewModel.deleteAll()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will permanently delete all \(records.count) translation records.")
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            if filteredRecords.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredRecords) { record in
                            TranslationCard(
                                record: record,
                                isSelected: viewModel.selectedRecord == record,
                                onCopySource: { viewModel.copySource(record) },
                                onCopyTranslation: { viewModel.copyTranslation(record) },
                                onDelete: { viewModel.delete(record) }
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectedRecord = record
                                }
                            }
                        }
                    }
                    .padding(12)
                }
            }
        }
    }
    
    // MARK: - Detail Panel
    
    private var detailPanel: some View {
        Group {
            if let record = viewModel.selectedRecord {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(record.sourceLanguage?.flag ?? "🔍")
                                    Text(record.sourceLanguage?.displayName ?? record.sourceLanguageCode)
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                    Text(record.targetLanguage?.flag ?? "")
                                    Text(record.targetLanguage?.displayName ?? record.targetLanguageCode)
                                }
                                .font(.system(.headline, design: .rounded))
                                
                                Text(record.formattedDate)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.textSecondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "cpu")
                                    .font(.caption2)
                                Text("\(record.providerName) · \(record.modelName)")
                                    .font(.system(.caption, design: .rounded))
                            }
                            .foregroundStyle(.textTertiary)
                        }
                        
                        Divider()
                        
                        // Source text
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Source Text", systemImage: "text.cursor")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundStyle(.textSecondary)
                            
                            Text(record.sourceText)
                                .font(.system(.body, design: .default))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.surfacePrimary, in: RoundedRectangle(cornerRadius: 10))
                        }
                        
                        // Translated text
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Translation", systemImage: "text.quote")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundStyle(.textSecondary)
                            
                            Text(record.translatedText)
                                .font(.system(.body, design: .default))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.accentPrimary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                        }
                        
                        // Actions
                        HStack(spacing: 12) {
                            Button(action: { viewModel.copySource(record) }) {
                                Label("Copy Source", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.borderless)
                            
                            Button(action: { viewModel.copyTranslation(record) }) {
                                Label("Copy Translation", systemImage: "doc.on.doc.fill")
                            }
                            .buttonStyle(.borderless)
                            
                            Spacer()
                            
                            Button(action: { viewModel.delete(record) }) {
                                Label("Delete", systemImage: "trash")
                                    .foregroundStyle(.destructive)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(24)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(.textTertiary)
                    Text("Select a translation to view details")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.textTertiary)
            
            Text(viewModel.searchText.isEmpty ? "No translations yet" : "No results found")
                .font(.system(.title3, design: .rounded, weight: .medium))
                .foregroundStyle(.textSecondary)
            
            Text(viewModel.searchText.isEmpty
                 ? "Your translation history will appear here"
                 : "Try a different search term")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
