//
//  FullVerseView.swift
//  Vani
//
//  Detail view showing complete verse with all text layers.
//

import SwiftUI
import UIKit
import WidgetKit

struct FullVerseView: View {
    
    let verse: Verse
    let chapter: Chapter?
    
    @EnvironmentObject private var settings: SettingsManager
    @Environment(\.gitaRepository) private var repository
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText: String = ""
    @State private var isSearchActive: Bool = false
    @State private var allVerses: [Verse] = []
    @State private var selectedVerseId: String?
    @State private var showingSetAsCurrentAlert: Bool = false
    @FocusState private var isSearchFocused: Bool
    
    private var theme: AppTheme { settings.appTheme }
    
    // Search results - matching verses across all verses (excluding current verse)
    private var searchResults: [Verse] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmedSearch.isEmpty else { return [] }
        let searchLower = trimmedSearch.lowercased()
        
        return allVerses.filter { verse in
            // Exclude the current verse from search results
            if verse.id == self.verse.id {
                return false
            }
            
            // Search by verse ID (e.g., "3.39" matches verse with id "3.39")
            if verse.id.lowercased() == searchLower || verse.id.lowercased().contains(searchLower) {
                return true
            }
            
            // Search in Sanskrit
            if verse.sanskrit.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            
            // Search in Transliteration
            if verse.transliteration.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            
            // Search in Translation
            if verse.translationFull.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            
            return false
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: theme.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Subtle overlay for depth
                theme.backgroundColor.opacity(0.3)
            }
            .ignoresSafeArea()
            
            // Content (only when search is not active)
            if !isSearchActive {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Enhanced Header
                        enhancedHeaderSection
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        
                        // Main content sections with better visual design
                        VStack(spacing: 20) {
                            // Sanskrit Section - Premium card design
                            enhancedTextSection(
                                icon: "book",
                                title: "Sanskrit",
                                subtitle: "संस्कृत",
                                content: formatSanskritText(verse.sanskrit),
                                font: .system(size: 24, weight: .regular, design: theme.fontDesign),
                                color: theme.sanskritTextColor,
                                accentColor: theme.accentColor
                            )
                            
                            // Transliteration Section
                            enhancedTextSection(
                                icon: "character.phonetic",
                                title: "Transliteration",
                                subtitle: "IAST",
                                content: verse.transliteration,
                                font: .system(size: 18, weight: .regular, design: theme.fontDesign).italic(),
                                color: theme.primaryTextColor.opacity(0.95),
                                accentColor: theme.accentColor.opacity(0.8)
                            )
                            
                            // Translation Section - Most prominent
                            enhancedTextSection(
                                icon: "text.book.closed",
                                title: "Translation",
                                subtitle: "English",
                                content: verse.translationFull,
                                font: .system(size: 19, weight: theme.bodyFontWeight, design: theme.fontDesign),
                                color: theme.primaryTextColor,
                                accentColor: theme.accentColor,
                                isPrimary: true
                            )
                            
                            // Key Concepts - Enhanced design
                            if !verse.keyConcepts.isEmpty {
                                enhancedConceptsSection
                            }
                            
                            // Vocative Info - Enhanced design
                            if verse.hasVocative && !verse.vocativeTerms.isEmpty {
                                enhancedVocativeSection
                            }
                            
                            // Set as Home Verse button
                            setAsHomeVerseButton
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            
            // Search overlay (when active)
            if isSearchActive {
                searchBarWithPreview
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: verse.id)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(theme.isLightTheme ? .light : .dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if !isSearchActive {
                    Text("Verse \(verse.id)")
                        .font(.headline)
                        .foregroundStyle(theme.primaryTextColor)
                } else {
                    Text("")
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                // Search button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isSearchActive.toggle()
                        if !isSearchActive {
                            searchText = ""
                            isSearchFocused = false
                        } else {
                            // Clear search text when opening
                            searchText = ""
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                isSearchFocused = true
                            }
                        }
                    }
                }) {
                    Image(systemName: isSearchActive ? "xmark.circle.fill" : "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(theme.accentColor)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(theme.accentColor.opacity(0.15))
                        )
                }
                
                // Share button
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(theme.accentColor)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(theme.accentColor.opacity(0.15))
                        )
                }
            }
        }
        .overlay(alignment: .top) {
            if isSearchActive {
                searchBarWithPreview
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1000)
            }
        }
        .onAppear {
            loadAllVerses()
        }
        .id(settings.currentVerseId ?? verse.id) // Force refresh when verse changes
        .sheet(item: Binding(
            get: { selectedVerseId.flatMap { id in allVerses.first { $0.id == id } } },
            set: { selectedVerseId = $0?.id }
        )) { verse in
            NavigationStack {
                let verseChapter = findChapter(for: verse)
                FullVerseView(verse: verse, chapter: verseChapter)
            }
        }
        .alert("Set as Home Verse", isPresented: $showingSetAsCurrentAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Set as Current") {
                setVerseAsCurrent(verse)
            }
        } message: {
            Text("This verse will appear on your home screen and widgets until the next scheduled update.")
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatSanskritText(_ text: String) -> String {
        // Sanskrit verses should be displayed in 2 lines (before and after the main । separator)
        // Remove all existing line breaks first
        let cleaned = text.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)
        
        // Find the main separator (।) that splits the verse into two parts
        // Look for the first । that appears before the verse number markers (॥)
        if let mainSeparatorRange = cleaned.range(of: "।") {
            let beforeSeparator = String(cleaned[..<mainSeparatorRange.upperBound]).trimmingCharacters(in: .whitespaces)
            var afterSeparator = String(cleaned[mainSeparatorRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            
            // Remove any remaining । separators from afterSeparator (keep only the verse number)
            afterSeparator = afterSeparator.replacingOccurrences(of: " ।", with: "")
            
            // If there's meaningful content after the separator, format as 2 lines
            if !afterSeparator.isEmpty && !afterSeparator.allSatisfy({ $0 == "॥" || $0.isWhitespace || $0.isNumber || $0.isLetter == false }) {
                return "\(beforeSeparator)\n\(afterSeparator)"
            } else {
                // If after separator is just verse number, keep it on same line or second line
                return "\(beforeSeparator)\n\(afterSeparator)"
            }
        }
        
        // Fallback: if no separator found, try to split at natural break point
        let words = cleaned.components(separatedBy: " ")
        if words.count > 15 {
            // Find a good break point (look for punctuation or mid-point)
            let midPoint = words.count / 2
            let firstHalf = words[0..<midPoint].joined(separator: " ")
            let secondHalf = words[midPoint...].joined(separator: " ")
            return "\(firstHalf)\n\(secondHalf)"
        }
        
        return cleaned
    }
    
    private func loadAllVerses() {
        do {
            let data = try repository.loadData()
            allVerses = repository.getKrishnaVerses(from: data)
        } catch {
            allVerses = []
        }
    }
    
    private func findChapter(for verse: Verse) -> Chapter? {
        do {
            let data = try repository.loadData()
            let chapterNumber = Int(verse.id.split(separator: ".").first ?? "") ?? 0
            return data.chapter(chapterNumber)
        } catch {
            return nil
        }
    }
    
    private func setVerseAsCurrent(_ verse: Verse) {
        // Set as current verse (this will appear on home screen and widgets)
        settings.currentVerseId = verse.id
        
        // Mark this verse as shown in the rotation system
        // This ensures it counts as displayed and won't show again until all verses are shown
        VerseRotationManager.shared.markVerseAsShown(verseId: verse.id, from: allVerses)
        
        // Reload widgets to show the new verse
        WidgetKit.WidgetCenter.shared.reloadAllTimelines()
        
        // Show success feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Dismiss the alert
        showingSetAsCurrentAlert = false
        
        // Force update the current view to reflect the change
        // The onChange handler will pick this up
    }
    
    // MARK: - Subviews
    
    private var searchBarWithPreview: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(theme.isLightTheme ? Color.gray : Color.white.opacity(0.7))
                
                TextField("Search verses or verse ID...", text: $searchText)
                    .focused($isSearchFocused)
                    .foregroundColor(theme.isLightTheme ? Color.black : Color.white)
                    .tint(theme.accentColor)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .textFieldStyle(.plain)
                    .accentColor(theme.accentColor)
                
                if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button(action: {
                        searchText = ""
                        isSearchFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(theme.isLightTheme ? Color.gray : Color.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.isLightTheme ? Color.white : Color(white: 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(theme.accentColor.opacity(0.4), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
            .padding(.top, isSearchActive ? 60 : 8) // Extra padding when search is active to account for nav bar
            .padding(.bottom, 8)
            
            // Preview list - only show when there's actual search text (no whitespace-only)
            let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedSearch.isEmpty {
                if searchResults.isEmpty {
                    // No results
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.secondaryTextColor)
                        Text("No matches found")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryTextColor)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        theme.backgroundColor.opacity(0.95)
                            .ignoresSafeArea(edges: .top)
                    )
                } else {
                    // Show preview list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(searchResults.prefix(10)) { resultVerse in
                                SearchResultRow(
                                    verse: resultVerse,
                                    searchText: searchText,
                                    theme: theme,
                                    onTap: {
                                        selectedVerseId = resultVerse.id
                                        isSearchActive = false
                                        searchText = ""
                                    }
                                )
                            }
                            
                            if searchResults.count > 10 {
                                Text("And \(searchResults.count - 10) more...")
                                    .font(.caption)
                                    .foregroundStyle(theme.secondaryTextColor)
                                    .padding(.vertical, 12)
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                    .background(
                        theme.backgroundColor.opacity(0.95)
                            .ignoresSafeArea(edges: .top)
                    )
                }
            }
        }
        .background(
            theme.backgroundColor
                .ignoresSafeArea(edges: .all)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private var enhancedHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row with logo and speaker
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.accentColor)
                        Text("Bhagavad Gita")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.accentColor)
                            .textCase(.uppercase)
                            .tracking(1.2)
                    }
                    
                    Text("Chapter \(String(verse.id.split(separator: ".").first ?? "")), Verse \(verse.verseNumber)")
                        .font(.system(size: 28, weight: .bold, design: theme.fontDesign))
                        .foregroundStyle(theme.primaryTextColor)
                }
                
                Spacer()
                
                // Enhanced speaker badge
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text(verse.speaker)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(theme.isLightTheme ? .white : theme.backgroundColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: theme.buttonGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: theme.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                )
            }
            
            // Chapter info with divider
            if let chapter = chapter {
                VStack(alignment: .leading, spacing: 6) {
                    Divider()
                        .background(theme.accentColor.opacity(0.3))
                        .padding(.vertical, 4)
                    
                    Text(chapter.chapterNameEnglish)
                        .font(.system(size: 16, weight: .medium, design: theme.fontDesign))
                        .foregroundStyle(theme.primaryTextColor.opacity(0.9))
                    
                    Text(chapter.chapterNameSanskrit)
                        .font(.system(size: 15, weight: .regular, design: theme.fontDesign))
                        .foregroundStyle(theme.accentColor.opacity(0.8))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    .ultraThinMaterial
                        .opacity(theme.isLightTheme ? 0.6 : 0.3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    theme.accentColor.opacity(0.3),
                                    theme.accentColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: theme.accentColor.opacity(0.1), radius: 12, x: 0, y: 4)
        )
    }
    
    private func enhancedTextSection(
        icon: String,
        title: String,
        subtitle: String,
        content: String,
        font: Font,
        color: Color,
        accentColor: Color,
        isPrimary: Bool = false
    ) -> some View {
        let isHighlighted = shouldHighlightSection(title: title)
        
        return VStack(alignment: .leading, spacing: 16) {
            // Header with icon
            HStack(spacing: 10) {
                Image(systemName: icon == "book" ? "text.book.closed" : icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(accentColor.opacity(0.15))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: theme.fontDesign))
                        .foregroundStyle(theme.primaryTextColor)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: theme.fontDesign))
                        .foregroundStyle(theme.secondaryTextColor)
                }
                
                Spacer()
                
                // Search match indicator
                if isHighlighted && !searchText.isEmpty && !isSearchActive {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.accentColor)
                }
            }
            
            // Content with enhanced styling and search highlighting (only if not in search mode)
            if isSearchActive {
                Text(content)
                    .font(font)
                    .foregroundStyle(color)
                    .lineSpacing(isPrimary ? 8 : 6)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                createHighlightedText(content: content, font: font, color: color, lineSpacing: isPrimary ? 8 : 6)
                    .font(font)
                    .foregroundStyle(color)
                    .lineSpacing(isPrimary ? 8 : 6)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    .ultraThinMaterial
                        .opacity(theme.isLightTheme ? 0.7 : 0.25)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: isPrimary ? [
                                    accentColor.opacity(0.4),
                                    accentColor.opacity(0.2)
                                ] : [
                                    accentColor.opacity(0.2),
                                    accentColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isPrimary ? 1.5 : 1
                        )
                )
                .shadow(
                    color: isPrimary ? accentColor.opacity(0.15) : Color.black.opacity(0.1),
                    radius: isPrimary ? 16 : 8,
                    x: 0,
                    y: isPrimary ? 6 : 4
                )
        )
    }
    
    private var enhancedConceptsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon
            HStack(spacing: 10) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.accentColor)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(theme.accentColor.opacity(0.15))
                    )
                
                Text("Key Concepts")
                    .font(.system(size: 17, weight: .semibold, design: theme.fontDesign))
                    .foregroundStyle(theme.primaryTextColor)
                
                Spacer()
            }
            
            // Enhanced concept tags
            FlowLayout(spacing: 10) {
                ForEach(verse.keyConcepts, id: \.self) { concept in
                    HStack(spacing: 6) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 10, weight: .semibold))
                        Text(concept.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(theme.accentColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        theme.accentColor.opacity(0.2),
                                        theme.accentColor.opacity(0.15)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(theme.accentColor.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    .ultraThinMaterial
                        .opacity(theme.isLightTheme ? 0.7 : 0.25)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            theme.accentColor.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private var setAsHomeVerseButton: some View {
        Button(action: {
            showingSetAsCurrentAlert = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.down.on.square")
                    .font(.system(size: 16, weight: .semibold))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Set as Home Verse")
                        .font(.system(size: 16, weight: .semibold, design: theme.fontDesign))
                    
                    Text("Show on home screen & widgets")
                        .font(.system(size: 12, weight: .regular, design: theme.fontDesign))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(theme.accentColor)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.accentColor.opacity(0.2),
                                theme.accentColor.opacity(0.15)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.accentColor.opacity(0.4), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var enhancedVocativeSection: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.wave.2.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.accentColor)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.accentColor.opacity(0.25),
                                    theme.accentColor.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Addressed To")
                    .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                    .foregroundStyle(theme.secondaryTextColor)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Text(verse.vocativeTerms.joined(separator: ", "))
                    .font(.system(size: 16, weight: .medium, design: theme.fontDesign))
                    .foregroundStyle(theme.primaryTextColor)
            }
            
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.accentColor.opacity(0.15),
                            theme.accentColor.opacity(0.08)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper Functions
    
    private func shouldHighlightSection(title: String) -> Bool {
        guard !searchText.isEmpty else { return false }
        
        switch title {
        case "Sanskrit":
            return verse.sanskrit.localizedCaseInsensitiveContains(searchText)
        case "Transliteration":
            return verse.transliteration.localizedCaseInsensitiveContains(searchText)
        case "Translation":
            return verse.translationFull.localizedCaseInsensitiveContains(searchText)
        default:
            return false
        }
    }
    
    private func createHighlightedText(content: String, font: Font, color: Color, lineSpacing: CGFloat) -> Text {
        if searchText.isEmpty {
            return Text(content)
        } else {
            // Use NSAttributedString for highlighting
            let attributedString = NSMutableAttributedString(string: content)
            let searchLower = searchText.lowercased()
            let contentLower = content.lowercased()
            
            // Find all occurrences (case-insensitive) using NSString
            let nsContent = contentLower as NSString
            var searchLocation = 0
            while searchLocation < nsContent.length {
                let range = nsContent.range(of: searchLower, options: .caseInsensitive, range: NSRange(location: searchLocation, length: nsContent.length - searchLocation))
                if range.location != NSNotFound {
                    // Convert SwiftUI Color to UIColor
                    let accentUIColor = UIColor(theme.accentColor)
                    let highlightColor = accentUIColor.withAlphaComponent(0.3)
                    
                    attributedString.addAttribute(.backgroundColor, value: highlightColor, range: range)
                    attributedString.addAttribute(.foregroundColor, value: accentUIColor, range: range)
                    searchLocation = range.location + range.length
                } else {
                    break
                }
            }
            
            return Text(AttributedString(attributedString))
        }
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

// MARK: - Search Result Row

struct SearchResultRow: View {
    let verse: Verse
    let searchText: String
    let theme: AppTheme
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Verse \(verse.id)")
                        .font(.system(size: 15, weight: .semibold, design: theme.fontDesign))
                        .foregroundStyle(theme.accentColor)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.secondaryTextColor)
                }
                
                // Show matching text preview
                Text(verse.translationFull)
                    .font(.system(size: 13, weight: .regular, design: theme.fontDesign))
                    .foregroundStyle(theme.primaryTextColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(theme.buttonBackgroundColor.opacity(0.5))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FullVerseView(verse: .sample, chapter: .sample)
    }
}

