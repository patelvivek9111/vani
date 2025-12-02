//
//  ThemesView.swift
//  Vani
//
//  Theme selection view with aesthetic previews.
//

import SwiftUI

struct ThemesView: View {
    
    @EnvironmentObject private var settings: SettingsManager
    @Environment(\.gitaRepository) private var repository
    
    @State private var selectedThemeForPreview: AppTheme?
    @State private var currentVerse: Verse?
    @State private var chapter: Chapter?
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    /// Themes sorted with selected theme first
    private var sortedThemes: [AppTheme] {
        let selected = settings.appTheme
        var themes = AppTheme.allCases.filter { $0 != selected }
        themes.insert(selected, at: 0)
        return themes
    }
    
    private var theme: AppTheme { settings.appTheme }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header description
                    Text("Choose a theme that resonates with your spiritual journey")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Theme grid - selected theme appears first
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(sortedThemes) { theme in
                            ThemeCard(
                                theme: theme,
                                isSelected: settings.appTheme == theme,
                                onSelect: {
                                    selectedThemeForPreview = theme
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selectedThemeForPreview) { theme in
                ThemePreviewView(
                    theme: theme,
                    currentVerse: currentVerse,
                    chapter: chapter,
                    onApply: {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            settings.appTheme = theme
                        }
                        selectedThemeForPreview = nil
                    }
                )
            }
        }
        .onAppear {
            loadCurrentVerse()
        }
    }
    
    private func loadCurrentVerse() {
        do {
            let data = try repository.loadData()
            chapter = data.chapterInfo
            
            let krishnaVerses = repository.getKrishnaVerses(from: data)
            
            if let verse = VerseSelector.findVerse(byId: settings.currentVerseId, from: krishnaVerses) {
                currentVerse = verse
            } else {
                currentVerse = krishnaVerses.first
            }
        } catch {
            currentVerse = nil
        }
    }
}

// MARK: - Theme Preview View

struct ThemePreviewView: View {
    let theme: AppTheme
    let currentVerse: Verse?
    let chapter: Chapter?
    let onApply: () -> Void
    
    @EnvironmentObject private var settings: SettingsManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Themed background
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Preview content
                previewContent
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.backgroundColor, for: .navigationBar)
        .toolbarColorScheme(theme.isLightTheme ? .light : .dark, for: .navigationBar)
    }
    
    // MARK: - Preview Content
    
    private var previewContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 32) {
                    // Theme title
                    VStack(spacing: 8) {
                        Text(theme.displayName)
                            .font(.system(size: 28, weight: .light, design: .serif))
                            .foregroundStyle(theme.accentColor)
                        
                        Text(theme.description)
                            .font(.subheadline)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                    .padding(.top, 20)
                    
                    // Home Screen Preview
                    previewSection(title: "Home Screen") {
                        HomePreviewCard(theme: theme, verse: currentVerse, chapter: chapter, displayMode: settings.homeDisplayMode)
                    }
                    
                    // Large Widget Preview
                    previewSection(title: "Large Widget") {
                        LargeWidgetPreviewCard(theme: theme, verse: currentVerse, topMode: settings.largeWidgetTop, bottomMode: settings.largeWidgetBottom)
                    }
                    
                    // Medium Widget Preview
                    previewSection(title: "Medium Widget") {
                        MediumWidgetPreviewCard(theme: theme, verse: currentVerse, mode: settings.mediumWidgetMode)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
            
            // Apply button
            applyButton
        }
    }
    
    
    // MARK: - Apply Button
    
    private var applyButton: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.3)
            
            HStack(spacing: 16) {
                // Current indicator
                if settings.appTheme == theme {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Current Theme")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.buttonBackgroundColor)
                    .clipShape(Capsule())
                } else {
                    Button(action: {
                        onApply()
                        dismiss()
                    }) {
                        Text("Apply Theme")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: theme.buttonGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(theme.backgroundColor.opacity(0.95))
        }
    }
    
    // MARK: - Helper Methods
    
    private func previewSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(theme.accentColor.opacity(0.7))
            
            content()
        }
    }
    
    private func contentText(for verse: Verse) -> String {
        switch settings.homeDisplayMode {
        case .sanskrit: return verse.sanskrit
        case .transliteration: return verse.transliteration
        case .translation: return verse.translationFull
        case .essence: return verse.widgetLine
        case .personalized: return verse.widgetLine
        }
    }
}

// MARK: - Home Preview Card

struct HomePreviewCard: View {
    let theme: AppTheme
    let verse: Verse?
    let chapter: Chapter?
    let displayMode: HomeDisplayMode
    
    @EnvironmentObject private var settings: SettingsManager
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: theme.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Glow
            Circle()
                .fill(theme.glowColor.opacity(0.12))
                .frame(width: 200, height: 200)
                .blur(radius: 50)
                .offset(y: 30)
            
            // Content
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Kṛṣṇa Vāṇī")
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundStyle(theme.accentColor)
                    
                    Spacer()
                    
                    Text("BG \(verse?.id ?? "2.47")")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(theme.accentColor.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(theme.buttonBackgroundColor))
                }
                
                Spacer()
                
                // Verse content
                Text(contentText(for: verse))
                    .font(.system(size: 14, weight: .light, design: theme.fontDesign))
                    .foregroundStyle(displayMode == .sanskrit ? theme.sanskritTextColor : theme.primaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .lineLimit(6)
                
                // Key concepts
                HStack(spacing: 6) {
                    ForEach(Array(conceptsToShow.prefix(3).enumerated()), id: \.element) { index, concept in
                        if index > 0 {
                            Text("·")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(theme.accentColor.opacity(0.5))
                        }
                        Text(concept.replacingOccurrences(of: "_", with: " ").uppercased())
                            .font(.system(size: 7, weight: .semibold))
                            .tracking(1)
                            .foregroundStyle(theme.accentColor.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Bottom buttons preview
                HStack(spacing: 8) {
                    Circle()
                        .fill(theme.buttonBackgroundColor)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "paintpalette.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(theme.accentColor)
                        )
                    
                    Capsule()
                        .fill(theme.buttonBackgroundColor)
                        .frame(width: 80, height: 28)
                        .overlay(
                            Text("New Verse")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(theme.accentColor)
                        )
                    
                    Capsule()
                        .fill(LinearGradient(colors: theme.buttonGradient, startPoint: .leading, endPoint: .trailing))
                        .frame(width: 60, height: 28)
                        .overlay(
                            Text("Share")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.white)
                        )
                }
            }
            .padding(20)
        }
        .frame(height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
    
    private var conceptsToShow: [String] {
        verse?.keyConcepts ?? ["Karma Yoga", "Duty", "Detachment"]
    }
    
    private func contentText(for verse: Verse?) -> String {
        let sampleSanskrit = "कर्मण्येवाधिकारस्ते मा फलेषु कदाचन।\nमा कर्मफलहेतुर्भूर्मा ते सङ्गोऽस्त्वकर्मणि॥"
        let sampleTransliteration = "karmaṇy evādhikāras te mā phaleṣu kadācana\nmā karma-phala-hetur bhūr mā te saṅgo 'stv akarmaṇi"
        let sampleTranslation = "You have a right to perform your prescribed duties, but you are not entitled to the fruits of your actions."
        let sampleEssence = "Focus on action, not results. Do your duty without attachment."
        
        guard let verse = verse else {
            switch displayMode {
            case .sanskrit: return sampleSanskrit
            case .transliteration: return sampleTransliteration
            case .translation: return sampleTranslation
            case .essence: return sampleEssence
            case .personalized: return sampleEssence
            }
        }
        
        switch displayMode {
        case .sanskrit: return verse.sanskrit
        case .transliteration: return verse.transliteration
        case .translation: return verse.translationFull
        case .essence: return verse.widgetLine
        case .personalized: return verse.widgetLine // For preview, just show widget line
        }
    }
}

// MARK: - Large Widget Preview Card

struct LargeWidgetPreviewCard: View {
    let theme: AppTheme
    let verse: Verse?
    let topMode: LargeWidgetTop
    let bottomMode: LargeWidgetBottom
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: theme.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Glow
            Circle()
                .fill(theme.glowColor.opacity(0.1))
                .frame(width: 150, height: 150)
                .blur(radius: 40)
            
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Text("Kṛṣṇa Vāṇī")
                        .font(.system(size: 10, weight: .medium, design: .serif))
                        .foregroundStyle(theme.accentColor)
                    
                    Text("·")
                        .foregroundStyle(theme.accentColor.opacity(0.5))
                    
                    Text(topMode.displayName.uppercased())
                        .font(.system(size: 8, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(theme.secondaryTextColor)
                    
                    Spacer()
                    
                    Text("BG \(verse?.id ?? "2.47")")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(theme.accentColor.opacity(0.7))
                }
                
                Divider().opacity(0.3)
                
                // Top section
                Text(topContent)
                    .font(.system(size: 11, weight: .regular, design: theme.fontDesign))
                    .foregroundStyle(theme.sanskritTextColor)
                    .lineSpacing(4)
                    .lineLimit(4)
                
                Spacer(minLength: 8)
                
                Divider().opacity(0.3)
                
                // Bottom section label
                Text(bottomMode.displayName.uppercased())
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(theme.secondaryTextColor)
                
                Text(bottomContent)
                    .font(.system(size: 10, weight: .light, design: theme.fontDesign))
                    .foregroundStyle(theme.primaryTextColor)
                    .lineSpacing(3)
                    .lineLimit(3)
                
                Spacer(minLength: 4)
                
                // Tags
                HStack(spacing: 4) {
                    ForEach(conceptsToShow.prefix(3), id: \.self) { concept in
                        Text(concept.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.system(size: 7, weight: .medium))
                            .foregroundStyle(theme.accentColor.opacity(0.8))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(theme.buttonBackgroundColor))
                    }
                }
            }
            .padding(12)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
    }
    
    private var conceptsToShow: [String] {
        verse?.keyConcepts ?? ["Karma Yoga", "Duty", "Detachment"]
    }
    
    private var topContent: String {
        let sampleSanskrit = "कर्मण्येवाधिकारस्ते मा फलेषु कदाचन।"
        let sampleTransliteration = "karmaṇy evādhikāras te mā phaleṣu kadācana"
        
        guard let verse = verse else {
            return topMode == .sanskrit ? sampleSanskrit : sampleTransliteration
        }
        return topMode == .sanskrit ? verse.sanskrit : verse.transliteration
    }
    
    private var bottomContent: String {
        let sampleTranslation = "You have a right to perform your prescribed duties, but you are not entitled to the fruits of your actions."
        let sampleEssence = "Focus on action, not results."
        
        guard let verse = verse else {
            return bottomMode == .translation ? sampleTranslation : sampleEssence
        }
        return bottomMode == .translation ? verse.translationFull : verse.widgetLine
    }
}

// MARK: - Medium Widget Preview Card

struct MediumWidgetPreviewCard: View {
    let theme: AppTheme
    let verse: Verse?
    let mode: MediumWidgetMode
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: theme.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Glow
            Circle()
                .fill(theme.glowColor.opacity(0.1))
                .frame(width: 100, height: 100)
                .blur(radius: 30)
            
            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack {
                    Text("Kṛṣṇa Vāṇī")
                        .font(.system(size: 9, weight: .medium, design: .serif))
                        .foregroundStyle(theme.accentColor)
                    
                    Text("·")
                        .foregroundStyle(theme.accentColor.opacity(0.5))
                    
                    Text(mode.displayName.uppercased())
                        .font(.system(size: 7, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(theme.secondaryTextColor)
                    
                    Spacer()
                    
                    Text("BG \(verse?.id ?? "2.47")")
                        .font(.system(size: 7, weight: .medium, design: .monospaced))
                        .foregroundStyle(theme.accentColor.opacity(0.7))
                }
                
                Divider().opacity(0.3)
                
                Spacer(minLength: 4)
                
                // Content
                Text(contentText)
                    .font(.system(size: mode == .sanskrit ? 12 : 10, weight: mode == .sanskrit ? .regular : .light, design: theme.fontDesign))
                    .foregroundStyle(mode == .sanskrit ? theme.sanskritTextColor : theme.primaryTextColor)
                    .lineSpacing(3)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
                
                Spacer(minLength: 4)
            }
            .padding(10)
        }
        .frame(height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
    }
    
    private var contentText: String {
        let sampleSanskrit = "कर्मण्येवाधिकारस्ते मा फलेषु कदाचन।"
        let sampleTransliteration = "karmaṇy evādhikāras te mā phaleṣu kadācana"
        let sampleEssence = "Focus on action, not results."
        
        guard let verse = verse else {
            switch mode {
            case .sanskrit: return sampleSanskrit
            case .transliteration: return sampleTransliteration
            case .essence: return sampleEssence
            }
        }
        
        switch mode {
        case .sanskrit: return verse.sanskrit
        case .transliteration: return verse.transliteration
        case .essence: return verse.widgetLine
        }
    }
}

// MARK: - Theme Card

struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    @EnvironmentObject private var settings: SettingsManager
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                // Theme preview
                themePreview
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                isSelected ? theme.accentColor : Color.clear,
                                lineWidth: 3
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                // Theme name and selection indicator
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(theme.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        Text(theme.description)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(theme.accentColor)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.top, 10)
                .padding(.horizontal, 4)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Theme Preview
    
    @ViewBuilder
    private var themePreview: some View {
        ZStack {
            // Background
            themeBackground
            
            // Content preview
            VStack(spacing: 10) {
                // Decorative element based on theme
                themeDecoration
                
                // Sample text - uses theme's custom font
                Text(theme.previewText)
                    .font(themePreviewFont(for: theme))
                    .foregroundStyle(theme.primaryTextColor)
                
                // Accent dots
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(theme.accentColor.opacity(0.6))
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var themeBackground: some View {
        ZStack {
            LinearGradient(colors: theme.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle()
                .fill(theme.glowColor.opacity(0.15))
                .frame(width: 120, height: 120)
                .blur(radius: 35)
                .offset(y: 20)
        }
    }
    
    @ViewBuilder
    private var themeDecoration: some View {
        switch theme {
        case .midnightGold:
            Text("ॐ")
                .font(.system(size: 20))
                .foregroundStyle(theme.accentColor.opacity(0.4))
            
        case .pureBlack:
            Rectangle()
                .fill(theme.accentColor.opacity(0.3))
                .frame(width: 30, height: 1)
            
        case .sacredLotus:
            Image(systemName: "leaf.fill")
                .font(.system(size: 16))
                .foregroundStyle(theme.accentColor.opacity(0.5))
                .rotationEffect(.degrees(180))
            
        case .divineBlue:
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(theme.accentColor.opacity(0.4))
                        .frame(width: 2, height: 12)
                }
            }
            
        case .forestAshram:
            Image(systemName: "leaf.fill")
                .font(.system(size: 16))
                .foregroundStyle(theme.accentColor.opacity(0.5))
            
        case .celestial:
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 14))
                .foregroundStyle(theme.accentColor.opacity(0.5))
        }
    }
    
    /// Returns the appropriate font for the theme preview text
    private func themePreviewFont(for theme: AppTheme) -> Font {
        if let customFont = theme.customFontName {
            return .custom(customFont, size: 24)
        } else {
            return .system(size: 24, weight: .light, design: theme.fontDesign)
        }
    }
}

// MARK: - Preview

#Preview {
    ThemesView()
        .environmentObject(SettingsManager.shared)
}
