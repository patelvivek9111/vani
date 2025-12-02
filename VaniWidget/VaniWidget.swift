//
//  VaniWidget.swift
//  VaniWidget
//
//  Widget extension for displaying Bhagavad Gita verses on Home and Lock Screen.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct VaniWidgetEntry: TimelineEntry {
    let date: Date
    let verse: Verse?
    let mediumMode: MediumWidgetMode
    let largeTop: LargeWidgetTop
    let largeBottom: LargeWidgetBottom
    let theme: AppTheme
    let hasError: Bool
    let needsOnboarding: Bool
    
    init(
        date: Date,
        verse: Verse?,
        mediumMode: MediumWidgetMode,
        largeTop: LargeWidgetTop,
        largeBottom: LargeWidgetBottom,
        theme: AppTheme,
        hasError: Bool,
        needsOnboarding: Bool = false
    ) {
        self.date = date
        self.verse = verse
        self.mediumMode = mediumMode
        self.largeTop = largeTop
        self.largeBottom = largeBottom
        self.theme = theme
        self.hasError = hasError
        self.needsOnboarding = needsOnboarding
    }
    
    static var placeholder: VaniWidgetEntry {
        VaniWidgetEntry(
            date: Date(),
            verse: .sample,
            mediumMode: .essence,
            largeTop: .sanskrit,
            largeBottom: .essence,
            theme: .pureBlack,
            hasError: false
        )
    }
}

// MARK: - Timeline Provider

struct VaniTimelineProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> VaniWidgetEntry {
        VaniWidgetEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (VaniWidgetEntry) -> Void) {
        let entry = createEntry(for: Date())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<VaniWidgetEntry>) -> Void) {
        let currentDate = Date()
        let defaults = AppConstants.sharedUserDefaults ?? .standard
        
        // Read schedule to determine refresh policy
        let schedule: VerseSchedule = {
            guard let raw = defaults.string(forKey: AppConstants.UserDefaultsKeys.verseSchedule),
                  let s = VerseSchedule(rawValue: raw) else { return .oncePerDay }
            return s
        }()
        
        // Create entries based on schedule
        var entries: [VaniWidgetEntry] = []
        
        // Current entry
        let currentEntry = createEntry(for: currentDate)
        entries.append(currentEntry)
        
        // Next scheduled entry
        let nextTime = schedule.nextScheduledTime(after: currentDate)
        let nextEntry = createEntry(for: nextTime)
        entries.append(nextEntry)
        
        // Set refresh policy to next scheduled time
        let timeline = Timeline(entries: entries, policy: .after(nextTime))
        completion(timeline)
    }
    
    private func createEntry(for date: Date) -> VaniWidgetEntry {
        // Read fresh settings directly from shared UserDefaults (not cached singleton)
        let defaults = AppConstants.sharedUserDefaults ?? .standard
        
        // Check if onboarding is complete - if not, show onboarding message
        let hasCompletedOnboarding = defaults.bool(forKey: AppConstants.UserDefaultsKeys.hasCompletedOnboarding)
        if !hasCompletedOnboarding {
            // Return entry with special flag for onboarding not complete
            let theme: AppTheme = {
                guard let raw = defaults.string(forKey: AppConstants.UserDefaultsKeys.appTheme),
                      let t = AppTheme(rawValue: raw) else { return .pureBlack }
                return t
            }()
            
            return VaniWidgetEntry(
                date: date,
                verse: nil,
                mediumMode: .essence,
                largeTop: .sanskrit,
                largeBottom: .essence,
                theme: theme,
                hasError: true,
                needsOnboarding: true
            )
        }
        
        // Read theme
        let theme: AppTheme = {
            guard let raw = defaults.string(forKey: AppConstants.UserDefaultsKeys.appTheme),
                  let t = AppTheme(rawValue: raw) else { return .pureBlack }
            return t
        }()
        
        // Read widget display settings
        let mediumMode: MediumWidgetMode = {
            guard let raw = defaults.string(forKey: AppConstants.UserDefaultsKeys.mediumWidgetMode),
                  let mode = MediumWidgetMode(rawValue: raw) else { return .essence }
            return mode
        }()
        
        let largeTop: LargeWidgetTop = {
            guard let raw = defaults.string(forKey: AppConstants.UserDefaultsKeys.largeWidgetTop),
                  let mode = LargeWidgetTop(rawValue: raw) else { return .sanskrit }
            return mode
        }()
        
        let largeBottom: LargeWidgetBottom = {
            guard let raw = defaults.string(forKey: AppConstants.UserDefaultsKeys.largeWidgetBottom),
                  let mode = LargeWidgetBottom(rawValue: raw) else { return .essence }
            return mode
        }()
        
        // Read current verse ID (synced from app via rotation manager)
        let currentVerseId = defaults.string(forKey: AppConstants.UserDefaultsKeys.currentVerseId)
        
        // Load verses from repository
        let repository = BundleGitaRepository()
        
        do {
            let data = try repository.loadData()
            
            // Validate data integrity
            guard !data.allVerses.isEmpty else {
                return VaniWidgetEntry(
                    date: date,
                    verse: nil,
                    mediumMode: mediumMode,
                    largeTop: largeTop,
                    largeBottom: largeBottom,
                    theme: theme,
                    hasError: true
                )
            }
            
            let krishnaVerses = repository.getKrishnaVerses(from: data)
            
            // Validate we have Krishna verses
            guard !krishnaVerses.isEmpty else {
                return VaniWidgetEntry(
                    date: date,
                    verse: nil,
                    mediumMode: mediumMode,
                    largeTop: largeTop,
                    largeBottom: largeBottom,
                    theme: theme,
                    hasError: true
                )
            }
            
            // Use the synced verse from the app (set by VerseRotationManager)
            // Widget always displays what the app has set
            let verse: Verse?
            if let currentId = currentVerseId,
               let savedVerse = VerseSelector.findVerse(byId: currentId, from: krishnaVerses) {
                verse = savedVerse
            } else {
                // Fallback: use rotation manager to get current verse
                let rotationManager = VerseRotationManager.forWidget()
                let rotationVerse = rotationManager.getCurrentVerse(from: krishnaVerses, for: date)
                
                // Final fallback: use first verse if rotation manager fails
                verse = rotationVerse ?? krishnaVerses.first
            }
            
            return VaniWidgetEntry(
                date: date,
                verse: verse,
                mediumMode: mediumMode,
                largeTop: largeTop,
                largeBottom: largeBottom,
                theme: theme,
                hasError: false
            )
        } catch {
            // Handle all errors gracefully
            return VaniWidgetEntry(
                date: date,
                verse: nil,
                mediumMode: mediumMode,
                largeTop: largeTop,
                largeBottom: largeBottom,
                theme: theme,
                hasError: true
            )
        }
    }
}

// MARK: - Widget Entry View

struct VaniWidgetEntryView: View {
    var entry: VaniWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                MediumWidgetView(entry: entry)
            }
        }
        // Set flag to show full verse when app opens
        .widgetURL(URL(string: "vani://showverse"))
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: VaniWidgetEntry
    
    private var theme: AppTheme { entry.theme }
    private var celestialSeed: Int {
        Calendar.current.component(.minute, from: entry.date) + 
        Calendar.current.component(.hour, from: entry.date) * 60
    }
    
    var body: some View {
        if entry.needsOnboarding {
            OnboardingRequiredWidgetView(theme: theme)
        } else if entry.hasError {
            ErrorWidgetView(theme: theme)
        } else if let verse = entry.verse {
            GeometryReader { geo in
                ZStack {
                    // Celestial stars overlay for celestial theme
                    if theme == .celestial {
                        WidgetCelestialBackground(seed: celestialSeed, size: geo.size)
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        HStack {
                            Text("Kṛṣṇa Vāṇī")
                                .font(.system(size: 18, weight: .medium, design: theme.fontDesign))
                                .foregroundStyle(theme.accentColor)
                            
                            Text("•")
                                .foregroundStyle(theme.accentColor.opacity(0.5))
                            
                            Text(entry.mediumMode.displayName)
                                .font(.caption)
                                .foregroundStyle(theme.secondaryTextColor)
                            
                            Spacer()
                            
                            Text("BG \(verse.id)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(theme.isLightTheme ? .white : theme.backgroundColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(theme.accentColor))
                        }
                        
                        Spacer(minLength: 8)
                        
                        // Main content - centered vertically
                        mainContent(for: verse)
                        
                        Spacer(minLength: 8)
                    }
                    .padding(10)
                }
            }
            .containerBackground(
                LinearGradient(colors: theme.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                for: .widget
            )
        } else {
            NoVerseWidgetView(theme: theme)
        }
    }
    
    @ViewBuilder
    private func mainContent(for verse: Verse) -> some View {
        switch entry.mediumMode {
        case .sanskrit:
            Text(verse.sanskrit)
                .font(.system(size: 16, weight: .regular, design: theme.fontDesign))
                .foregroundStyle(theme.sanskritTextColor)
                .lineSpacing(4)
                .minimumScaleFactor(0.7)
            
        case .transliteration:
            Text(verse.transliteration)
                .font(.system(size: 14, weight: .regular, design: theme.fontDesign))
                .italic()
                .foregroundStyle(theme.primaryTextColor)
                .lineSpacing(3)
                .minimumScaleFactor(0.7)
            
        case .essence:
            Text(personalizedText(for: verse))
                .font(themedFont(size: 16, weight: theme.bodyFontWeight))
                .foregroundStyle(theme.primaryTextColor)
                .lineSpacing(4)
                .minimumScaleFactor(0.75)
        }
    }
    
    // Helper for custom fonts (for essence/translation only)
    private func themedFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let customFont = theme.customFontName {
            return .custom(customFont, size: size)
        } else {
            return .system(size: size, weight: weight, design: theme.fontDesign)
        }
    }
    
    // Helper to personalize text for widgets
    private func personalizedText(for verse: Verse) -> String {
        let defaults = AppConstants.sharedUserDefaults ?? .standard
        
        // Check if personalization is enabled
        let personalizationEnabled = defaults.bool(forKey: AppConstants.UserDefaultsKeys.personalizationEnabled)
        guard personalizationEnabled else {
            return verse.widgetLine
        }
        
        // Check if user has a name
        guard let userName = defaults.string(forKey: AppConstants.UserDefaultsKeys.userName),
              !userName.isEmpty else {
            return verse.widgetLine
        }
        
        // Check if verse has personalized field
        guard verse.hasVocative,
              let personalizedText = verse.personalized else {
            return verse.widgetLine
        }
        
        // Replace {name} with user's name
        return personalizedText.replacingOccurrences(of: "{name}", with: userName)
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: VaniWidgetEntry
    
    private var theme: AppTheme { entry.theme }
    private var celestialSeed: Int {
        Calendar.current.component(.minute, from: entry.date) + 
        Calendar.current.component(.hour, from: entry.date) * 60 + 100  // +100 to differ from medium
    }
    
    var body: some View {
        if entry.needsOnboarding {
            OnboardingRequiredWidgetView(theme: theme)
        } else if entry.hasError {
            ErrorWidgetView(theme: theme)
        } else if let verse = entry.verse {
            GeometryReader { geo in
                ZStack {
                    // Celestial stars overlay for celestial theme
                    if theme == .celestial {
                        WidgetCelestialBackground(seed: celestialSeed, size: geo.size)
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        headerView(verse: verse)
                        
                        Divider()
                            .background(theme.accentColor.opacity(0.3))
                            .padding(.vertical, 6)
                        
                        Spacer(minLength: 0)
                        
                        // TOP SECTION
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.largeTop.displayName.uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(theme.accentColor.opacity(0.8))
                            
                            topSectionContent(for: verse)
                        }
                        
                        Spacer(minLength: 8)
                        
                        // Subtle divider
                        Rectangle()
                            .fill(theme.accentColor.opacity(0.15))
                            .frame(height: 1)
                        
                        Spacer(minLength: 8)
                        
                        // BOTTOM SECTION
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.largeBottom.displayName.uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(theme.accentColor.opacity(0.8))
                            
                            bottomSectionContent(for: verse)
                        }
                        
                        Spacer(minLength: 0)
                        
                        // Key concepts at bottom
                        if !verse.keyConcepts.isEmpty {
                            conceptTags(for: verse)
                                .padding(.top, 8)
                        }
                    }
                    .padding(10)
                }
            }
            .containerBackground(
                LinearGradient(colors: theme.gradientColors, startPoint: .top, endPoint: .bottom),
                for: .widget
            )
        } else {
            NoVerseWidgetView(theme: theme)
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func headerView(verse: Verse) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Kṛṣṇa Vāṇī")
                    .font(.system(size: 24, weight: theme.titleFontWeight, design: theme.fontDesign))
                    .foregroundStyle(theme.accentColor)
                Text("Daily Wisdom")
                    .font(.system(size: 10))
                    .foregroundStyle(theme.secondaryTextColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Bhagavad Gita")
                    .font(.system(size: 10))
                    .foregroundStyle(theme.secondaryTextColor)
                Text(verse.id)
                    .font(.system(size: 18, weight: .semibold, design: theme.fontDesign))
                    .foregroundStyle(theme.accentColor)
            }
        }
    }
    
    // MARK: - Key Concept Tags
    
    @ViewBuilder
    private func conceptTags(for verse: Verse) -> some View {
        HStack(spacing: 6) {
            ForEach(verse.keyConcepts.prefix(4), id: \.self) { concept in
                Text(concept.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(theme.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(theme.accentColor.opacity(0.15))
                    )
            }
            Spacer()
        }
    }
    
    // MARK: - Top Section Content
    
    @ViewBuilder
    private func topSectionContent(for verse: Verse) -> some View {
        switch entry.largeTop {
        case .sanskrit:
            Text(verse.sanskrit)
                .font(.system(size: 14, weight: .regular, design: theme.fontDesign))
                .foregroundStyle(theme.sanskritTextColor)
                .lineSpacing(3)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: false)
            
        case .transliteration:
            Text(verse.transliteration)
                .font(.system(size: 13, weight: .regular, design: theme.fontDesign))
                .italic()
                .foregroundStyle(theme.primaryTextColor)
                .lineSpacing(2)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: false)
        }
    }
    
    // MARK: - Bottom Section Content
    
    @ViewBuilder
    private func bottomSectionContent(for verse: Verse) -> some View {
        switch entry.largeBottom {
        case .translation:
            Text(verse.translationFull)
                .font(themedFont(size: 13, weight: theme.bodyFontWeight))
                .foregroundStyle(theme.primaryTextColor)
                .lineSpacing(3)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: false)
            
        case .essence:
            Text(personalizedText(for: verse))
                .font(themedFont(size: 14, weight: theme.bodyFontWeight))
                .foregroundStyle(theme.primaryTextColor)
                .lineSpacing(3)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: false)
        }
    }
    
    // Helper for custom fonts (for essence/translation only)
    private func themedFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let customFont = theme.customFontName {
            return .custom(customFont, size: size)
        } else {
            return .system(size: size, weight: weight, design: theme.fontDesign)
        }
    }
    
    // Helper to personalize text for widgets
    private func personalizedText(for verse: Verse) -> String {
        let defaults = AppConstants.sharedUserDefaults ?? .standard
        
        // Check if personalization is enabled
        let personalizationEnabled = defaults.bool(forKey: AppConstants.UserDefaultsKeys.personalizationEnabled)
        guard personalizationEnabled else {
            return verse.widgetLine
        }
        
        // Check if user has a name
        guard let userName = defaults.string(forKey: AppConstants.UserDefaultsKeys.userName),
              !userName.isEmpty else {
            return verse.widgetLine
        }
        
        // Check if verse has personalized field
        guard verse.hasVocative,
              let personalizedText = verse.personalized else {
            return verse.widgetLine
        }
        
        // Replace {name} with user's name
        return personalizedText.replacingOccurrences(of: "{name}", with: userName)
    }
}

// MARK: - Fallback Views

struct ErrorWidgetView: View {
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(theme.accentColor)
            Text("Unable to load verse")
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(
            LinearGradient(colors: theme.gradientColors, startPoint: .top, endPoint: .bottom),
            for: .widget
        )
    }
}

struct NoVerseWidgetView: View {
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.closed")
                .font(.title2)
                .foregroundStyle(theme.accentColor)
            Text("No verses match your filters")
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
            Text("Adjust filters in the app")
                .font(.caption2)
                .foregroundStyle(theme.secondaryTextColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(
            LinearGradient(colors: theme.gradientColors, startPoint: .top, endPoint: .bottom),
            for: .widget
        )
    }
}

struct OnboardingRequiredWidgetView: View {
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.title2)
                .foregroundStyle(theme.accentColor)
            
            Text("Complete Onboarding")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.primaryTextColor)
                .multilineTextAlignment(.center)
            
            Text("Open the app to get started")
                .font(.caption2)
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .containerBackground(
            LinearGradient(colors: theme.gradientColors, startPoint: .top, endPoint: .bottom),
            for: .widget
        )
    }
}

// MARK: - Celestial Theme Background for Widgets

struct WidgetCelestialBackground: View {
    let seed: Int  // Use for random generation
    let size: CGSize
    
    var body: some View {
        ZStack {
            // Scattered stars
            ForEach(0..<25, id: \.self) { i in
                let position = starPosition(for: i)
                let starSize = starSize(for: i)
                let opacity = starOpacity(for: i)
                
                Circle()
                    .fill(Color.white.opacity(opacity))
                    .frame(width: starSize, height: starSize)
                    .position(x: position.x * size.width, y: position.y * size.height)
            }
            
            // Shooting star (static streak)
            WidgetShootingStarView(seed: seed, size: size)
        }
    }
    
    private func starPosition(for index: Int) -> CGPoint {
        // Use seed + index to generate pseudo-random positions
        let xSeed = Double((seed + index * 17) % 100) / 100.0
        let ySeed = Double((seed + index * 31) % 100) / 100.0
        return CGPoint(x: xSeed, y: ySeed)
    }
    
    private func starSize(for index: Int) -> CGFloat {
        let sizes: [CGFloat] = [1.0, 1.5, 2.0, 2.5, 1.2]
        return sizes[(seed + index) % sizes.count]
    }
    
    private func starOpacity(for index: Int) -> Double {
        let opacities: [Double] = [0.3, 0.5, 0.7, 0.4, 0.6, 0.8]
        return opacities[(seed + index) % opacities.count]
    }
}

struct WidgetShootingStarView: View {
    let seed: Int
    let size: CGSize
    
    private var showShootingStar: Bool {
        // Show shooting star ~60% of the time
        seed % 10 < 6
    }
    
    private var fromLeft: Bool {
        seed % 2 == 0
    }
    
    // Position along the path (0 to 1)
    private var progress: CGFloat {
        CGFloat((seed % 80) + 10) / 100.0
    }
    
    // Starting Y position (top 30% of widget)
    private var startY: CGFloat {
        CGFloat((seed % 25) + 5) / 100.0 * size.height
    }
    
    private let tailLength: CGFloat = 50
    
    var body: some View {
        if showShootingStar {
            let travelDistance = size.width + 100
            let dropRatio: CGFloat = 0.3
            
            let xPos: CGFloat = fromLeft
                ? -30 + (travelDistance * progress)
                : size.width + 30 - (travelDistance * progress)
            let yPos: CGFloat = startY + (size.height * dropRatio * progress)
            
            let angle: Double = fromLeft
                ? atan2(Double(size.height * dropRatio), Double(travelDistance)) * 180 / .pi
                : 180 - atan2(Double(size.height * dropRatio), Double(travelDistance)) * 180 / .pi
            
            ZStack {
                // Outer glow
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.5), Color.white.opacity(0.1), Color.clear],
                            startPoint: .trailing,
                            endPoint: .leading
                        )
                    )
                    .frame(width: tailLength, height: 4)
                    .blur(radius: 2)
                
                // Middle glow
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.7), Color.white.opacity(0.2), Color.clear],
                            startPoint: .trailing,
                            endPoint: .leading
                        )
                    )
                    .frame(width: tailLength * 0.85, height: 2.5)
                    .blur(radius: 1)
                
                // Core streak
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.5), Color.clear],
                            startPoint: .trailing,
                            endPoint: .leading
                        )
                    )
                    .frame(width: tailLength * 0.7, height: 1.5)
                
                // Bright head
                Circle()
                    .fill(Color.white)
                    .frame(width: 3, height: 3)
                    .blur(radius: 0.5)
                    .offset(x: tailLength * 0.35)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 2, height: 2)
                    .offset(x: tailLength * 0.35)
            }
            .rotationEffect(.degrees(angle))
            .position(x: xPos, y: yPos)
        }
    }
}

// MARK: - Widget Configuration

struct VaniWidget: Widget {
    let kind: String = "VaniWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VaniTimelineProvider()) { entry in
            VaniWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Kṛṣṇa Vāṇī")
        .description("Daily wisdom from the Bhagavad Gita")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle

@main
struct VaniWidgetBundle: WidgetBundle {
    var body: some Widget {
        VaniWidget()
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    VaniWidget()
} timeline: {
    VaniWidgetEntry.placeholder
}

#Preview(as: .systemLarge) {
    VaniWidget()
} timeline: {
    VaniWidgetEntry.placeholder
}
