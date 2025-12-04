//
//  HomeView.swift
//  Vani
//
//  Main home screen displaying the current verse.
//

import SwiftUI
import WidgetKit

struct HomeView: View {
    
    @EnvironmentObject private var settings: SettingsManager
    @Environment(\.gitaRepository) private var repository
    @StateObject private var rotationManager = VerseRotationManager.shared
    
    @State private var currentVerse: Verse?
    @State private var allVerses: [Verse] = []
    @State private var chapter: Chapter?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingFullVerse = false
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?
    @State private var showingShareOptions = false
    @State private var showingTemplateSelection = false
    
    // Shooting star animation state
    @State private var shootingStarVisible = false
    @State private var shootingStarProgress: CGFloat = 0
    @State private var shootingStarY: CGFloat = 50
    @State private var shootingStarFromLeft: Bool = true
    
    // Cherry blossom animation state (for Sacred Lotus theme)
    @State private var cherryBlossomPetals: [CherryBlossomPetal] = []
    
    // Forest Ashram animation state
    @State private var fallingLeaves: [FallingLeaf] = []
    
    private var theme: AppTheme { settings.appTheme }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Themed background
                    themedBackground
                    
                    if isLoading {
                        LoadingView(theme: theme)
                    } else if let error = errorMessage {
                        ErrorStateView(message: error, theme: theme) {
                            loadData()
                        }
                    } else if let verse = currentVerse {
                        // Main content
                        VStack(spacing: 0) {
                            // Top section - Minimal header
                            topBar
                                .padding(.top, 8)
                            
                            Spacer()
                            
                            // Center - Main content based on display mode
                            mainContentView(verse: verse, geometry: geometry)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                    removal: .opacity.combined(with: .scale(scale: 1.05))
                                ))
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        showingFullVerse = true
                                    }
                                }
                            
                            Spacer()
                            
                            // Bottom actions
                            bottomActions(verse: verse)
                                .padding(.bottom, 20)
                        }
                        .padding(.horizontal, 24)
                    } else {
                        NoVersesView(theme: theme)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showingFullVerse) {
                if let verse = currentVerse {
                    FullVerseView(verse: verse, chapter: chapter)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = shareImage {
                    ShareSheet(items: [image])
                }
            }
        }
        .onAppear {
            if allVerses.isEmpty {
                loadData()
            }
        }
    }
    
    // MARK: - Themed Background
    
    private var themedBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: theme.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle radial glow
            RadialGradient(
                colors: [
                    theme.glowColor.opacity(0.15),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            
            // Decorative elements
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                theme.glowColor.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(x: -100, y: -150)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                theme.glowColor.opacity(0.06),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 250
                        )
                    )
                    .frame(width: 500, height: 500)
                    .offset(x: geo.size.width - 200, y: geo.size.height - 200)
                
                // Stars and shooting star for Celestial theme
                if theme == .celestial {
                    // Static star field - use fixed seed so stars don't change
                    CelestialStarsBackground(
                        seed: 42, // Fixed seed for consistent star positions
                        size: geo.size
                    )
                    
                    // Shooting star animation
                    if shootingStarVisible {
                        ShootingStarView(
                            progress: shootingStarProgress,
                            fromLeft: shootingStarFromLeft,
                            startY: shootingStarY
                        )
                    }
                }
                
                // Cherry blossoms for Sacred Lotus theme
                if theme == .sacredLotus {
                    ForEach(cherryBlossomPetals) { petal in
                        CherryBlossomPetalView(petal: petal)
                    }
                }
                
                // Falling leaves for Forest Ashram theme
                if theme == .forestAshram {
                    ForEach(fallingLeaves) { leaf in
                        FallingLeafView(leaf: leaf)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if theme == .celestial {
                startShootingStarTimer()
            }
            if theme == .sacredLotus {
                startCherryBlossomTimer()
            }
            if theme == .forestAshram {
                startForestAshramAnimations()
            }
        }
        .onChange(of: theme) { _, newTheme in
            // Smooth theme transition
            withAnimation(.easeInOut(duration: 0.6)) {
                if newTheme == .celestial {
                    startShootingStarTimer()
                }
                if newTheme == .sacredLotus {
                    cherryBlossomPetals.removeAll()
                    startCherryBlossomTimer()
                } else {
                    cherryBlossomPetals.removeAll()
                }
                if newTheme == .forestAshram {
                    fallingLeaves.removeAll()
                    startForestAshramAnimations()
                } else {
                    fallingLeaves.removeAll()
                }
            }
        }
    }
    
    private func startShootingStarTimer() {
        // Start first shooting star after initial delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            triggerShootingStar()
        }
    }
    
    private func triggerShootingStar() {
        guard theme == .celestial else { return }
        
        // Random start Y position in top 25% of screen
        let screenHeight = UIScreen.main.bounds.height
        let topArea = screenHeight * 0.25
        
        // Setup shooting star
        shootingStarFromLeft = Bool.random()
        shootingStarY = CGFloat.random(in: 40...topArea)
        shootingStarProgress = 0
        shootingStarVisible = true
        
        // Animate progress from 0 to 1 (full screen travel)
        withAnimation(.linear(duration: 0.8)) {
            shootingStarProgress = 1.0
        }
        
        // Hide after animation and schedule next
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            shootingStarVisible = false
            shootingStarProgress = 0
            
            // Schedule next shooting star with 6-8 second gap
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 6...8)) {
                triggerShootingStar()
            }
        }
    }
    
    // MARK: - Cherry Blossom Animation
    
    private func startCherryBlossomTimer() {
        // Start dropping petals
        spawnCherryBlossomPetal()
    }
    
    private func spawnCherryBlossomPetal() {
        guard theme == .sacredLotus else { return }
        
        let screenWidth = UIScreen.main.bounds.width
        
        // Create a new petal with random properties
        let petal = CherryBlossomPetal(
            id: UUID(),
            startX: CGFloat.random(in: -50...(screenWidth + 50)),
            size: CGFloat.random(in: 12...22),
            duration: Double.random(in: 6...10),
            delay: 0,
            swayAmount: CGFloat.random(in: 30...80),
            rotationSpeed: Double.random(in: 1...3)
        )
        
        cherryBlossomPetals.append(petal)
        
        // Remove petal after it falls off screen
        DispatchQueue.main.asyncAfter(deadline: .now() + petal.duration + 1) {
            cherryBlossomPetals.removeAll { $0.id == petal.id }
        }
        
        // Schedule next petal
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.8...2.0)) {
            spawnCherryBlossomPetal()
        }
    }
    
    // MARK: - Forest Ashram Animation
    
    private func startForestAshramAnimations() {
        // Start spawning leaves
        spawnFallingLeaf()
    }
    
    private func spawnFallingLeaf() {
        guard theme == .forestAshram else { return }
        
        let screenWidth = UIScreen.main.bounds.width
        
        // Create a new leaf with random properties
        let leaf = FallingLeaf(
            id: UUID(),
            startX: CGFloat.random(in: -30...(screenWidth + 30)),
            size: CGFloat.random(in: 14...24),
            duration: Double.random(in: 7...12),
            swayAmount: CGFloat.random(in: 40...100),
            rotationSpeed: Double.random(in: 1.5...3),
            leafType: [0, 2].randomElement() ?? 0, // Only smooth leaf shapes (no maple/star-like)
            color: Color.leafColors.randomElement() ?? .green
        )
        
        fallingLeaves.append(leaf)
        
        // Remove leaf after it falls off screen
        DispatchQueue.main.asyncAfter(deadline: .now() + leaf.duration + 1) {
            fallingLeaves.removeAll { $0.id == leaf.id }
        }
        
        // Schedule next leaf
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.0...2.5)) {
            spawnFallingLeaf()
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Kṛṣṇa Vāṇī")
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundStyle(theme.accentColor)
                
                if let chapter = chapter {
                    Text(chapter.chapterNameEnglish)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(theme.secondaryTextColor)
                }
            }
            
            Spacer()
            
            // Verse badge
            if let verse = currentVerse {
                Text("BG \(verse.id)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(theme.accentColor.opacity(0.7))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(theme.buttonBackgroundColor)
                    )
                
                // Favorite button
                Button(action: {
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        settings.toggleFavorite(verse.id)
                    }
                }) {
                    Image(systemName: settings.isFavorite(verse.id) ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(settings.isFavorite(verse.id) ? .red : theme.accentColor.opacity(0.7))
                        .scaleEffect(settings.isFavorite(verse.id) ? 1.1 : 1.0)
                }
                .padding(.leading, 8)
            }
        }
    }
    
    // MARK: - Main Content View
    
    @ViewBuilder
    private func mainContentView(verse: Verse, geometry: GeometryProxy) -> some View {
        switch settings.homeDisplayMode {
        case .sanskrit:
            sanskritView(verse: verse, geometry: geometry)
        case .transliteration:
            textView(text: verse.transliteration, geometry: geometry, isItalic: true)
        case .translation:
            textView(text: verse.translationFull, geometry: geometry, isItalic: false)
        case .essence:
            // Show personalized text if personalization is enabled and verse has personalized field
            let essenceText = PersonalizationHelper.personalize(
                text: verse.widgetLine,
                verse: verse,
                settings: settings
            )
            textView(text: essenceText, geometry: geometry, isItalic: false)
        case .personalized:
            // Always show personalized text in personalized mode
            let personalizedText = PersonalizationHelper.personalize(
                text: verse.widgetLine,
                verse: verse,
                settings: settings
            )
            textView(text: personalizedText, geometry: geometry, isItalic: false)
        }
    }
    
    // MARK: - Sanskrit View
    
    private func sanskritView(verse: Verse, geometry: GeometryProxy) -> some View {
        VStack(spacing: 24) {
            // Sanskrit text - use minimumScaleFactor to ensure lines fit on screen
            Text(verse.sanskrit)
                .font(themedFont(size: dynamicFontSize(for: verse.sanskrit, maxWidth: geometry.size.width - 48, isSanskrit: true), weight: .regular))
                .foregroundStyle(theme.sanskritTextColor)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .minimumScaleFactor(0.7)
            
            // Key concepts
            keyConceptsView(verse: verse)
            
            // Tap hint
            tapHint
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Text View (for Transliteration, Translation, Essence)
    
    private func textView(text: String, geometry: GeometryProxy, isItalic: Bool) -> some View {
        VStack(spacing: 24) {
            // The main text
            Text(text)
                .font(themedFont(size: dynamicFontSize(for: text, maxWidth: geometry.size.width - 48, isSanskrit: false), weight: .light))
                .italic(isItalic)
                .foregroundStyle(theme.primaryTextColor)
                .multilineTextAlignment(.center)
                .lineSpacing(12)
                .fixedSize(horizontal: false, vertical: true)
            
            // Key concepts
            if let verse = currentVerse {
                keyConceptsView(verse: verse)
            }
            
            // Tap hint
            tapHint
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Themed Font Helper
    
    private func themedFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let customFont = theme.customFontName {
            return .custom(customFont, size: size)
        } else {
            return .system(size: size, weight: weight, design: theme.fontDesign)
        }
    }
    
    // MARK: - Key Concepts
    
    private func keyConceptsView(verse: Verse) -> some View {
        Group {
            if !verse.keyConcepts.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(verse.keyConcepts.prefix(3).enumerated()), id: \.element) { index, concept in
                        if index > 0 {
                            Text("·")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(theme.accentColor.opacity(0.5))
                        }
                        Text(concept.replacingOccurrences(of: "_", with: " ").uppercased())
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(theme.accentColor.opacity(0.8))
                    }
                }
                .padding(.top, 16)
            }
        }
    }
    
    private var tapHint: some View {
        Text("Tap to explore full verse")
            .font(.system(size: 11, weight: .regular))
            .foregroundStyle(theme.secondaryTextColor.opacity(0.6))
            .padding(.top, 8)
    }
    
    // MARK: - Bottom Actions
    
    private func bottomActions(verse: Verse) -> some View {
        HStack(spacing: 12) {
            // New Verse button
            Button(action: selectNewVerse) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .medium))
                    Text("New Verse")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(theme.accentColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(theme.buttonBackgroundColor)
                        .overlay(
                            Capsule()
                                .strokeBorder(theme.accentColor.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(SmoothButtonStyle())
            
            // Share button
            Button(action: { 
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                showingShareOptions = true 
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                    Text("Share")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(theme.shareButtonTextColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: theme.buttonGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
            .buttonStyle(SmoothButtonStyle())
            .confirmationDialog("Share Verse", isPresented: $showingShareOptions, titleVisibility: .visible) {
                Button("Share as Image") {
                    showingTemplateSelection = true
                }
                Button("Copy Text") {
                    copyVerseText(verse: verse)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("How would you like to share this verse?")
            }
            .sheet(isPresented: $showingTemplateSelection) {
                if let verse = currentVerse {
                    ShareTemplateSelectionView(
                        verse: verse,
                        chapter: chapter,
                        displayMode: settings.homeDisplayMode,
                        currentTemplate: settings.shareTemplate,
                        onSelect: { template in
                            settings.shareTemplate = template
                            shareAsImage(verse: verse, template: template)
                            showingTemplateSelection = false
                        },
                        onCancel: {
                            showingTemplateSelection = false
                        }
                    )
                    .presentationDetents([.large])
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func dynamicFontSize(for text: String, maxWidth: CGFloat, isSanskrit: Bool) -> CGFloat {
        let length = text.count
        if isSanskrit {
            if length < 100 { return 26 }
            else if length < 200 { return 22 }
            else if length < 300 { return 20 }
            else { return 18 }
        } else {
            if length < 60 { return 32 }
            else if length < 100 { return 28 }
            else if length < 150 { return 24 }
            else if length < 250 { return 22 }
            else { return 20 }
        }
    }
    
    // MARK: - Share Functions
    
    private func shareAsImage(verse: Verse, template: ShareTemplate? = nil) {
        // Validate verse has content
        guard !verse.sanskrit.isEmpty || !verse.transliteration.isEmpty || !verse.translationFull.isEmpty else {
            // Show error if verse is empty
            errorMessage = "Verse content is empty. Please try another verse."
            return
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let selectedTemplate = template ?? settings.shareTemplate
        let shareView = ShareableVerseView(verse: verse, chapter: chapter, displayMode: settings.homeDisplayMode, theme: theme, template: selectedTemplate)
        let renderer = ImageRenderer(content: shareView)
        renderer.scale = UIScreen.main.scale
        renderer.proposedSize = .init(width: 1080, height: 1920)
        
        if let image = renderer.uiImage {
            shareImage = image
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showingShareSheet = true
            }
        } else {
            // Handle image rendering failure
            errorMessage = "Unable to generate share image. Please try again."
        }
    }
    
    private func copyVerseText(verse: Verse) {
        // Get the content based on current display mode with fallbacks
        let content: String
        switch settings.homeDisplayMode {
        case .sanskrit:
            content = verse.sanskrit.isEmpty ? (verse.transliteration.isEmpty ? verse.translationFull : verse.transliteration) : verse.sanskrit
        case .transliteration:
            content = verse.transliteration.isEmpty ? (verse.translationFull.isEmpty ? verse.widgetLine : verse.translationFull) : verse.transliteration
        case .translation:
            content = verse.translationFull.isEmpty ? verse.widgetLine : verse.translationFull
        case .essence:
            let essenceText = PersonalizationHelper.personalize(
                text: verse.widgetLine,
                verse: verse,
                settings: settings
            )
            content = essenceText.isEmpty ? verse.translationFull : essenceText
        case .personalized:
            let personalizedText = PersonalizationHelper.personalize(
                text: verse.widgetLine,
                verse: verse,
                settings: settings
            )
            content = personalizedText.isEmpty ? verse.translationFull : personalizedText
        }
        
        // Ensure we have content
        guard !content.isEmpty else {
            errorMessage = "Verse content is empty. Please try another verse."
            return
        }
        
        // Format: content + spacing + attribution
        let text = """
\(content)

— Bhagavad Gita \(verse.id)
"""
        
        UIPasteboard.general.string = text
        
        // Show a brief feedback (haptic)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        isLoading = true
        errorMessage = nil
        
        do {
            let data = try repository.loadData()
            
            // Validate data integrity
            guard !data.allVerses.isEmpty else {
                errorMessage = "No verses found in data file. Please contact support."
                isLoading = false
                return
            }
            
            chapter = data.chapterInfo
            
            // Get all Krishna verses (no concept filtering anymore)
            let krishnaVerses = repository.getKrishnaVerses(from: data)
            
            // Validate we have Krishna verses
            guard !krishnaVerses.isEmpty else {
                errorMessage = "No verses available. Please try again later."
                isLoading = false
                return
            }
            
            allVerses = krishnaVerses
            
            // Use rotation manager to get current verse
            currentVerse = rotationManager.getCurrentVerse(from: allVerses)
            
            // Validate we got a verse
            guard let verse = currentVerse else {
                errorMessage = "Unable to select a verse. Please try again."
                isLoading = false
                return
            }
            
            // Sync to settings for widget access
            settings.currentVerseId = verse.id
            WidgetHelper.reloadAllTimelines()
            
            isLoading = false
        } catch let error as GitaRepositoryError {
            // Provide specific error messages
            switch error {
            case .fileNotFound:
                errorMessage = "Data file not found. Please reinstall the app."
            case .decodingFailed:
                errorMessage = "Data file is corrupted. Please reinstall the app."
            case .invalidData:
                errorMessage = "Invalid data format. Please contact support."
            }
            isLoading = false
        } catch {
            // Generic error fallback
            errorMessage = "Unable to load verses. Please try again."
            isLoading = false
        }
    }
    
    private func selectNewVerse() {
        // Validate we have verses available
        guard !allVerses.isEmpty else {
            // Reload data if we have no verses
            loadData()
            return
        }
        
        // Smooth spring animation for verse change
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            // Advance to next verse in rotation (no repeats until all shown)
            currentVerse = rotationManager.advanceToNextVerse(from: allVerses)
            
            // Fallback: if no verse returned, get a random one
            if currentVerse == nil && !allVerses.isEmpty {
                currentVerse = allVerses.randomElement()
            }
            
            if let verse = currentVerse {
                settings.currentVerseId = verse.id
                WidgetHelper.reloadAllTimelines()
            }
        }
        
        // Haptic feedback for premium feel
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Shareable Verse View (for Instagram)

struct ShareableVerseView: View {
    let verse: Verse
    let chapter: Chapter?
    let displayMode: HomeDisplayMode
    let theme: AppTheme
    let template: ShareTemplate
    
    init(verse: Verse, chapter: Chapter?, displayMode: HomeDisplayMode, theme: AppTheme, template: ShareTemplate = .classic) {
        self.verse = verse
        self.chapter = chapter
        self.displayMode = displayMode
        self.theme = theme
        self.template = template
    }
    
    var body: some View {
        Group {
            switch template {
            case .classic:
                ClassicShareView(verse: verse, chapter: chapter, displayMode: displayMode, theme: theme)
            case .minimal:
                MinimalShareView(verse: verse, chapter: chapter, displayMode: displayMode, theme: theme)
            case .ornate:
                OrnateShareView(verse: verse, chapter: chapter, displayMode: displayMode, theme: theme)
            case .quote:
                QuoteShareView(verse: verse, chapter: chapter, displayMode: displayMode, theme: theme)
            case .elegant:
                ElegantShareView(verse: verse, chapter: chapter, displayMode: displayMode, theme: theme)
            }
        }
        .frame(width: 1080, height: 1920)
    }
}

// MARK: - Classic Share View (Original Design)

struct ClassicShareView: View {
    let verse: Verse
    let chapter: Chapter?
    let displayMode: HomeDisplayMode
    let theme: AppTheme
    
    var body: some View {
        ZStack {
            // Solid background
            theme.backgroundColor
            
            // Gradient overlay
            LinearGradient(
                colors: [
                    theme.gradientColors[0].opacity(0.8),
                    Color.clear,
                    theme.gradientColors[safe: 2]?.opacity(0.6) ?? Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle glow
            Circle()
                .fill(theme.glowColor.opacity(0.1))
                .frame(width: 600, height: 600)
                .blur(radius: 100)
            
            // Content - vertically centered
            VStack(spacing: 0) {
                // Main content group - centered
                VStack(spacing: 0) {
                    // Main content
                    ShareViewHelpers.shareContent(for: verse, displayMode: displayMode, theme: theme, baseSize: 52)
                        .padding(.horizontal, 60)
                    
                    // Spacing before attribution
                    Spacer()
                        .frame(height: 80)
                    
                    // Attribution - bigger text
                    VStack(spacing: 16) {
                        Text("— Bhagavad Gita \(verse.id)")
                            .font(.system(size: 42, weight: .semibold, design: theme.fontDesign))
                            .foregroundColor(theme.accentColor)
                        
                        if let chapter = chapter {
                            Text(chapter.chapterNameEnglish)
                                .font(.system(size: 28, weight: .regular))
                                .foregroundColor(theme.secondaryTextColor)
                        }
                    }
                    
                    // 3x spacing before Krsna Vani (3 x 80 = 240)
                    Spacer()
                        .frame(height: 240)
                    
                    // App branding
                    Text("Vāṇī")
                        .font(.system(size: 36, weight: .medium, design: .serif))
                        .foregroundColor(theme.accentColor.opacity(0.8))
                }
                .frame(maxHeight: .infinity)
                .padding(.bottom, 80)
            }
        }
    }
}

// MARK: - Share View Helpers

struct ShareViewHelpers {
    @ViewBuilder
    static func shareContent(for verse: Verse, displayMode: HomeDisplayMode, theme: AppTheme, baseSize: CGFloat) -> some View {
        switch displayMode {
        case .sanskrit:
            Text(verse.sanskrit)
                .font(shareFont(size: baseSize, theme: theme))
                .foregroundColor(theme.sanskritTextColor)
                .multilineTextAlignment(.center)
                .lineSpacing(20)
            
        case .transliteration:
            Text(verse.transliteration)
                .font(shareFont(size: baseSize * 0.92, theme: theme))
                .italic()
                .foregroundColor(theme.primaryTextColor)
                .multilineTextAlignment(.center)
                .lineSpacing(20)
            
        case .translation:
            Text(verse.translationFull)
                .font(shareFont(size: baseSize * 0.85, theme: theme))
                .foregroundColor(theme.primaryTextColor)
                .multilineTextAlignment(.center)
                .lineSpacing(18)
            
        case .essence:
            Text(verse.widgetLine)
                .font(shareFont(size: baseSize * 1.08, theme: theme))
                .foregroundColor(theme.primaryTextColor)
                .multilineTextAlignment(.center)
                .lineSpacing(24)
        
        case .personalized:
            // For share, we need to personalize the text
            // Since we don't have access to SettingsManager here, we'll use widgetLine
            // In practice, this should be personalized, but for share templates we'll use the original
            Text(verse.widgetLine)
                .font(shareFont(size: baseSize * 1.08, theme: theme))
                .foregroundColor(theme.primaryTextColor)
                .multilineTextAlignment(.center)
                .lineSpacing(24)
        }
    }
    
    static func shareFont(size: CGFloat, theme: AppTheme) -> Font {
        if let customFont = theme.customFontName {
            return .custom(customFont, size: size)
        } else {
            return .system(size: size, weight: .light, design: theme.fontDesign)
        }
    }
}

// MARK: - Minimal Share View

struct MinimalShareView: View {
    let verse: Verse
    let chapter: Chapter?
    let displayMode: HomeDisplayMode
    let theme: AppTheme
    
    var body: some View {
        ZStack {
            // Clean white/light background
            Color.white
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main content - centered
                ShareViewHelpers.shareContent(for: verse, displayMode: displayMode, theme: theme, baseSize: 56)
                    .padding(.horizontal, 80)
                    .foregroundColor(.black)
                
                Spacer()
                    .frame(height: 100)
                
                // Attribution - minimal
                VStack(spacing: 12) {
                    Text("— Bhagavad Gita \(verse.id)")
                        .font(.system(size: 36, weight: .regular, design: .serif))
                        .foregroundColor(.gray)
                    
                    if let chapter = chapter {
                        Text(chapter.chapterNameEnglish)
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
                
                Spacer()
                    .frame(height: 200)
                
                // App branding - subtle
                Text("Vāṇī")
                    .font(.system(size: 32, weight: .light, design: .serif))
                    .foregroundColor(.gray.opacity(0.5))
                
                Spacer()
            }
            .padding(.bottom, 80)
        }
    }
}

// MARK: - Ornate Share View

struct OrnateShareView: View {
    let verse: Verse
    let chapter: Chapter?
    let displayMode: HomeDisplayMode
    let theme: AppTheme
    
    var body: some View {
        ZStack {
            // Rich background
            theme.backgroundColor
            
            // Decorative border pattern
            VStack(spacing: 0) {
                // Top border
                Rectangle()
                    .fill(theme.accentColor)
                    .frame(height: 8)
                
                HStack(spacing: 0) {
                    // Left border
                    Rectangle()
                        .fill(theme.accentColor)
                        .frame(width: 8)
                    
                    // Content area
                    ZStack {
                        // Ornate pattern overlay
                        LinearGradient(
                            colors: [
                                theme.gradientColors[0].opacity(0.3),
                                Color.clear,
                                theme.gradientColors[safe: 1]?.opacity(0.3) ?? Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        VStack(spacing: 0) {
                            Spacer()
                            
                            // Decorative top element
                            HStack {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(theme.accentColor.opacity(0.6))
                                Spacer()
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(theme.accentColor.opacity(0.6))
                            }
                            .padding(.horizontal, 60)
                            .padding(.bottom, 40)
                            
                            // Main content
                            ShareViewHelpers.shareContent(for: verse, displayMode: displayMode, theme: theme, baseSize: 50)
                                .padding(.horizontal, 60)
                            
                            Spacer()
                                .frame(height: 60)
                            
                            // Attribution
                            VStack(spacing: 16) {
                                Text("— Bhagavad Gita \(verse.id)")
                                    .font(.system(size: 40, weight: .semibold, design: theme.fontDesign))
                                    .foregroundColor(theme.accentColor)
                                
                                if let chapter = chapter {
                                    Text(chapter.chapterNameEnglish)
                                        .font(.system(size: 26, weight: .regular))
                                        .foregroundColor(theme.secondaryTextColor)
                                }
                            }
                            
                            Spacer()
                                .frame(height: 200)
                            
                            // Decorative bottom element
                            HStack {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(theme.accentColor.opacity(0.6))
                                Spacer()
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(theme.accentColor.opacity(0.6))
                            }
                            .padding(.horizontal, 60)
                            .padding(.top, 40)
                            
                            // App branding
                            Text("Vāṇī")
                                .font(.system(size: 34, weight: .medium, design: .serif))
                                .foregroundColor(theme.accentColor.opacity(0.8))
                            .padding(.top, 40)
                            
                            Spacer()
                        }
                        .padding(.vertical, 40)
                    }
                    
                    // Right border
                    Rectangle()
                        .fill(theme.accentColor)
                        .frame(width: 8)
                }
                
                // Bottom border
                Rectangle()
                    .fill(theme.accentColor)
                    .frame(height: 8)
            }
        }
    }
}

// MARK: - Quote Share View

struct QuoteShareView: View {
    let verse: Verse
    let chapter: Chapter?
    let displayMode: HomeDisplayMode
    let theme: AppTheme
    
    var body: some View {
        ZStack {
            // Dark background for contrast
            Color.black
            
            VStack(spacing: 0) {
                Spacer()
                
                // Large quote mark
                Text("\u{201C}")
                    .font(.system(size: 120, weight: .light))
                    .foregroundColor(theme.accentColor.opacity(0.3))
                    .offset(x: -400, y: -200)
                
                // Main content - very large
                ShareViewHelpers.shareContent(for: verse, displayMode: displayMode, theme: theme, baseSize: 64)
                    .padding(.horizontal, 100)
                    .foregroundColor(.white)
                
                Spacer()
                    .frame(height: 120)
                
                // Attribution - bold
                VStack(spacing: 20) {
                    Text("— Bhagavad Gita \(verse.id)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(theme.accentColor)
                    
                    if let chapter = chapter {
                        Text(chapter.chapterNameEnglish)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                    .frame(height: 240)
                
                // App branding - minimal
                Text("Vāṇī")
                    .font(.system(size: 36, weight: .light, design: .serif))
                    .foregroundColor(.white.opacity(0.4))
                
                Spacer()
            }
            .padding(.bottom, 80)
        }
    }
}

// MARK: - Elegant Share View

struct ElegantShareView: View {
    let verse: Verse
    let chapter: Chapter?
    let displayMode: HomeDisplayMode
    let theme: AppTheme
    
    var body: some View {
        ZStack {
            // Sophisticated gradient background
            LinearGradient(
                colors: [
                    theme.backgroundColor,
                    theme.gradientColors[0].opacity(0.3),
                    theme.backgroundColor
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 0) {
                Spacer()
                
                // Elegant divider line
                Rectangle()
                    .fill(theme.accentColor.opacity(0.3))
                    .frame(width: 200, height: 2)
                    .padding(.bottom, 60)
                
                // Main content - sophisticated typography
                ShareViewHelpers.shareContent(for: verse, displayMode: displayMode, theme: theme, baseSize: 54)
                    .padding(.horizontal, 80)
                    .lineSpacing(28)
                
                Spacer()
                    .frame(height: 80)
                
                // Elegant divider line
                Rectangle()
                    .fill(theme.accentColor.opacity(0.3))
                    .frame(width: 200, height: 2)
                    .padding(.top, 20)
                
                Spacer()
                    .frame(height: 80)
                
                // Attribution - elegant spacing
                VStack(spacing: 20) {
                    Text("— Bhagavad Gita \(verse.id)")
                        .font(.system(size: 38, weight: .medium, design: .serif))
                        .foregroundColor(theme.accentColor)
                        .tracking(2)
                    
                    if let chapter = chapter {
                        Text(chapter.chapterNameEnglish)
                            .font(.system(size: 24, weight: .light, design: .serif))
                            .foregroundColor(theme.secondaryTextColor)
                            .tracking(1)
                    }
                }
                
                Spacer()
                    .frame(height: 220)
                
                // App branding - elegant
                Text("Vāṇī")
                    .font(.system(size: 38, weight: .light, design: .serif))
                    .foregroundColor(theme.accentColor.opacity(0.6))
                    .tracking(4)
                
                Spacer()
            }
            .padding(.bottom, 80)
        }
    }
}

// MARK: - Share Template Selection View

struct ShareTemplateSelectionView: View {
    let verse: Verse
    let chapter: Chapter?
    let displayMode: HomeDisplayMode
    let currentTemplate: ShareTemplate
    let onSelect: (ShareTemplate) -> Void
    let onCancel: () -> Void
    
    @EnvironmentObject private var settings: SettingsManager
    
    private var theme: AppTheme { settings.appTheme }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(ShareTemplate.allCases) { template in
                        Button(action: {
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                            onSelect(template)
                        }) {
                            VStack(spacing: 12) {
                                // Preview thumbnail
                                TemplatePreviewThumbnail(
                                    verse: verse,
                                    chapter: chapter,
                                    displayMode: displayMode,
                                    theme: theme,
                                    template: template
                                )
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(template == currentTemplate ? theme.accentColor : Color.clear, lineWidth: 3)
                                )
                                
                                // Template info
                                HStack(spacing: 12) {
                                    Image(systemName: template.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(theme.accentColor)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(template.displayName)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(theme.primaryTextColor)
                                            
                                            if template == currentTemplate {
                                                Spacer()
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(theme.accentColor)
                                            }
                                        }
                                        
                                        Text(template.description)
                                            .font(.system(size: 13))
                                            .foregroundColor(theme.secondaryTextColor)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(template == currentTemplate ? theme.accentColor.opacity(0.1) : theme.buttonBackgroundColor)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(template == currentTemplate ? theme.accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .background(theme.backgroundColor)
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(theme.accentColor)
                }
            }
        }
    }
}

// MARK: - Template Preview Thumbnail

struct TemplatePreviewThumbnail: View {
    let verse: Verse
    let chapter: Chapter?
    let displayMode: HomeDisplayMode
    let theme: AppTheme
    let template: ShareTemplate
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                switch template {
                case .classic:
                    ClassicShareView(verse: verse, chapter: chapter, displayMode: displayMode, theme: theme)
                case .minimal:
                    MinimalShareView(verse: verse, chapter: chapter, displayMode: displayMode, theme: theme)
                case .ornate:
                    OrnateShareView(verse: verse, chapter: chapter, displayMode: displayMode, theme: theme)
                case .quote:
                    QuoteShareView(verse: verse, chapter: chapter, displayMode: displayMode, theme: theme)
                case .elegant:
                    ElegantShareView(verse: verse, chapter: chapter, displayMode: displayMode, theme: theme)
                }
            }
            .frame(width: 1080, height: 1920)
            .scaleEffect(min(geometry.size.width / 1080, geometry.size.height / 1920))
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

// MARK: - Array Safe Subscript Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Supporting Views

struct LoadingView: View {
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(theme.accentColor)
            Text("Loading wisdom...")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)
        }
    }
}

struct ErrorStateView: View {
    let message: String
    let theme: AppTheme
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(theme.accentColor)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            Button("Try Again", action: retryAction)
                .foregroundStyle(theme.accentColor)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(theme.buttonBackgroundColor)
                )
        }
        .padding()
    }
}

struct NoVersesView: View {
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.largeTitle)
                .foregroundStyle(theme.secondaryTextColor)
            
            Text("No verses match your current filters")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryTextColor)
            
            Text("Try adjusting your concept filters in Settings")
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor.opacity(0.7))
        }
        .padding()
    }
}

// MARK: - Smooth Button Style

struct SmoothButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    HomeView()
        .environmentObject(SettingsManager.shared)
}

