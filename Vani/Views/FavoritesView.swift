//
//  FavoritesView.swift
//  Vani
//
//  View for displaying favorite verses.
//

import SwiftUI

struct FavoritesView: View {
    
    @EnvironmentObject private var settings: SettingsManager
    @Environment(\.gitaRepository) private var repository
    
    @State private var favoriteVerses: [Verse] = []
    @State private var chapter: Chapter?
    @State private var isLoading = true
    @State private var selectedVerse: Verse?
    @State private var showingFullVerse = false
    
    private var theme: AppTheme { settings.appTheme }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Themed background
                theme.backgroundColor.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(theme.accentColor)
                } else if favoriteVerses.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(favoriteVerses) { verse in
                                FavoriteVerseCard(
                                    verse: verse,
                                    theme: theme,
                                    onTap: {
                                        selectedVerse = verse
                                        showingFullVerse = true
                                    },
                                    onRemove: {
                                        withAnimation {
                                            settings.removeFavorite(verse.id)
                                            loadFavorites()
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Favorites")
            .toolbarBackground(theme.backgroundColor, for: .navigationBar)
            .toolbarColorScheme(theme.isLightTheme ? .light : .dark, for: .navigationBar)
            .navigationDestination(isPresented: $showingFullVerse) {
                if let verse = selectedVerse {
                    FullVerseView(verse: verse, chapter: chapter)
                }
            }
        }
        .onAppear {
            loadFavorites()
        }
        .onChange(of: settings.favoriteVerseIds) { _, _ in
            loadFavorites()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundStyle(theme.secondaryTextColor.opacity(0.5))
            
            Text("No Favorites Yet")
                .font(.system(size: 22, weight: .semibold, design: theme.fontDesign))
                .foregroundStyle(theme.primaryTextColor)
            
            Text("Tap the heart icon on any verse to save it here")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private func loadFavorites() {
        isLoading = true
        
        do {
            let data = try repository.loadData()
            
            // Validate data
            guard !data.allVerses.isEmpty else {
                favoriteVerses = []
                isLoading = false
                return
            }
            
            chapter = data.chapterInfo
            
            // Filter verses that are in favorites
            favoriteVerses = data.allVerses.filter { settings.favoriteVerseIds.contains($0.id) }
            
            // Sort by verse ID (chapter.verse) with safe parsing
            favoriteVerses.sort { v1, v2 in
                let parts1 = v1.id.split(separator: ".").compactMap { Int($0) }
                let parts2 = v2.id.split(separator: ".").compactMap { Int($0) }
                
                if parts1.count == 2 && parts2.count == 2 {
                    if parts1[0] != parts2[0] {
                        return parts1[0] < parts2[0]
                    }
                    return parts1[1] < parts2[1]
                }
                // Fallback to string comparison if parsing fails
                return v1.id < v2.id
            }
        } catch _ as GitaRepositoryError {
            // Handle specific errors gracefully
            favoriteVerses = []
        } catch {
            // Generic error fallback
            favoriteVerses = []
        }
        
        isLoading = false
    }
}

// MARK: - Favorite Verse Card

struct FavoriteVerseCard: View {
    let verse: Verse
    let theme: AppTheme
    let onTap: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text("BG \(verse.id)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(theme.accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(theme.accentColor.opacity(0.15))
                        )
                    
                    Spacer()
                    
                    // Remove from favorites
                    Button(action: onRemove) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
                
                // Essence
                Text(verse.widgetLine)
                    .font(.system(size: 15, weight: .medium, design: theme.fontDesign))
                    .foregroundStyle(theme.primaryTextColor)
                    .lineLimit(3)
                
                // Key concepts
                if !verse.keyConcepts.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(verse.keyConcepts.prefix(3), id: \.self) { concept in
                            Text(concept.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(theme.secondaryTextColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(theme.secondaryTextColor.opacity(0.1))
                                )
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.buttonBackgroundColor)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FavoritesView()
        .environmentObject(SettingsManager.shared)
}

