//
//  ContentView.swift
//  Vani
//
//  Main content view with tab navigation.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var settings: SettingsManager
    @Environment(\.gitaRepository) private var repository
    
    @State private var selectedTab = 0
    @State private var verseToShow: Verse?
    @State private var chapter: Chapter?
    
    private var theme: AppTheme { settings.appTheme }
    
    var body: some View {
        ZStack {
            // Global themed background
            theme.backgroundColor.ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "book.fill")
                    }
                    .tag(0)
                
                FavoritesView()
                    .tabItem {
                        Label("Favorites", systemImage: "heart.fill")
                    }
                    .tag(1)
                
                ThemesView()
                    .tabItem {
                        Label("Themes", systemImage: "paintpalette.fill")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
            .tint(theme.tabBarTint)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
        }
        .preferredColorScheme(theme.isLightTheme ? .light : .dark)
        .sheet(isPresented: $navigationCoordinator.shouldShowFullVerse) {
            if let verse = verseToShow {
                NavigationStack {
                    FullVerseView(verse: verse, chapter: chapter)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        navigationCoordinator.dismiss()
                                    }
                                }
                                .fontWeight(.medium)
                                .foregroundStyle(theme.accentColor)
                            }
                        }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(theme.accentColor)
                    Text("Loading verse...")
                        .foregroundStyle(theme.secondaryTextColor)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.backgroundColor)
                .onAppear {
                    loadCurrentVerse()
                }
            }
        }
        .onChange(of: navigationCoordinator.shouldShowFullVerse) { _, shouldShow in
            if shouldShow {
                loadCurrentVerse()
            }
        }
    }
    
    private func loadCurrentVerse() {
        do {
            let data = try repository.loadData()
            
            // Validate data
            guard !data.allVerses.isEmpty else {
                verseToShow = nil
                return
            }
            
            chapter = data.chapterInfo
            
            let krishnaVerses = repository.getKrishnaVerses(from: data)
            
            // Validate we have Krishna verses
            guard !krishnaVerses.isEmpty else {
                verseToShow = nil
                return
            }
            
            // Try to find the current verse, fallback to first available
            if let currentId = settings.currentVerseId,
               let verse = VerseSelector.findVerse(byId: currentId, from: krishnaVerses) {
                verseToShow = verse
            } else {
                // Fallback to first verse if current not found
                verseToShow = krishnaVerses.first
            }
        } catch {
            // Handle errors gracefully
            verseToShow = nil
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsManager.shared)
        .environmentObject(NavigationCoordinator())
}
