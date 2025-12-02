//
//  FullVerseView.swift
//  Vani
//
//  Detail view showing complete verse with all text layers.
//

import SwiftUI

struct FullVerseView: View {
    
    let verse: Verse
    let chapter: Chapter?
    
    @EnvironmentObject private var settings: SettingsManager
    @Environment(\.dismiss) private var dismiss
    
    private var theme: AppTheme { settings.appTheme }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with verse reference
                headerSection
                    .transition(.move(edge: .top).combined(with: .opacity))
                
                // Sanskrit Section
                textSection(
                    title: "Sanskrit",
                    subtitle: "संस्कृत",
                    content: verse.sanskrit,
                    font: .system(size: 22, weight: .regular, design: theme.fontDesign),
                    color: theme.sanskritTextColor
                )
                .transition(.move(edge: .leading).combined(with: .opacity))
                
                // Transliteration Section
                textSection(
                    title: "Transliteration",
                    subtitle: "IAST",
                    content: verse.transliteration,
                    font: .system(size: 17, weight: .regular, design: theme.fontDesign).italic(),
                    color: theme.primaryTextColor.opacity(0.9)
                )
                .transition(.move(edge: .leading).combined(with: .opacity))
                
                // Translation Section
                textSection(
                    title: "Translation",
                    subtitle: "English",
                    content: verse.translationFull,
                    font: .system(size: 16, weight: theme.bodyFontWeight, design: theme.fontDesign),
                    color: theme.primaryTextColor
                )
                .transition(.move(edge: .leading).combined(with: .opacity))
                
                // Key Concepts
                if !verse.keyConcepts.isEmpty {
                    conceptsSection
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Vocative Info (if applicable)
                if verse.hasVocative && !verse.vocativeTerms.isEmpty {
                    vocativeSection
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(
            LinearGradient(
                colors: theme.gradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: verse.id)
        .navigationTitle("Verse \(verse.id)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.backgroundColor, for: .navigationBar)
        .toolbarColorScheme(theme.isLightTheme ? .light : .dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(theme.accentColor)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bhagavad Gita")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.accentColor)
                    
                    Text("Chapter \(String(verse.id.split(separator: ".").first ?? "")), Verse \(verse.verseNumber)")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(theme.primaryTextColor)
                }
                
                Spacer()
                
                // Speaker badge
                Text(verse.speaker)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(theme.isLightTheme ? .white : theme.backgroundColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(theme.accentColor)
                    )
            }
            
            if let chapter = chapter {
                Text(chapter.chapterNameEnglish)
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryTextColor)
                
                Text(chapter.chapterNameSanskrit)
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryTextColor.opacity(0.7))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.buttonBackgroundColor)
        )
    }
    
    private func textSection(
        title: String,
        subtitle: String,
        content: String,
        font: Font,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(theme.primaryTextColor)
                
                Text("• \(subtitle)")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryTextColor)
            }
            
            Text(content)
                .font(font)
                .foregroundStyle(color)
                .lineSpacing(6)
                .textSelection(.enabled)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.buttonBackgroundColor)
        )
    }
    
    private var conceptsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Concepts")
                .font(.headline)
                .foregroundStyle(theme.primaryTextColor)
            
            FlowLayout(spacing: 8) {
                ForEach(verse.keyConcepts, id: \.self) { concept in
                    Text(concept.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                        .foregroundStyle(theme.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(theme.accentColor.opacity(0.15))
                        )
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.buttonBackgroundColor)
        )
    }
    
    private var vocativeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.wave.2")
                    .foregroundStyle(theme.accentColor)
                Text("Addressed To")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.primaryTextColor)
            }
            
            Text(verse.vocativeTerms.joined(separator: ", "))
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.accentColor.opacity(0.1))
        )
    }
    
    // MARK: - Computed Properties
    
    private var shareText: String {
        var components: [String] = []
        
        // Add verse reference
        components.append("Bhagavad Gita \(verse.id)")
        components.append("")
        
        // Add content sections (only if not empty)
        if !verse.sanskrit.isEmpty {
            components.append(verse.sanskrit)
            components.append("")
        }
        
        if !verse.transliteration.isEmpty {
            components.append(verse.transliteration)
            components.append("")
        }
        
        if !verse.translationFull.isEmpty {
            components.append(verse.translationFull)
            components.append("")
        }
        
        // Add attribution
        components.append("— Shared from Vāṇī")
        
        return components.joined(separator: "\n")
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + lineHeight
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FullVerseView(verse: .sample, chapter: .sample)
    }
}

