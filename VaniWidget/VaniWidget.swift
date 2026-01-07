//
//  VaniWidget.swift
//  VaniWidget
//
//  Widget extension for displaying Bhagavad Gita verses on Home and Lock Screen.
//

import WidgetKit
import SwiftUI
import Foundation

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
        // getSnapshot must be fast - use placeholder for previews, real data for widget gallery
        if context.isPreview {
            completion(VaniWidgetEntry.placeholder)
        } else {
            // For widget gallery, use real data but ensure it's fast
            let entry = createEntry(for: Date())
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<VaniWidgetEntry>) -> Void) {
        let currentDate = Date()
        
        // Safely get UserDefaults - ensure we always have a valid instance
        let defaults = AppConstants.sharedUserDefaults ?? UserDefaults.standard
        
        // Read schedule to determine refresh policy with safe fallback
        let schedule: VerseSchedule = {
            guard let raw = defaults.string(forKey: AppConstants.UserDefaultsKeys.verseSchedule),
                  let s = VerseSchedule(rawValue: raw) else { return .oncePerDay }
            return s
        }()
        
        // Create entries based on schedule
        // Use autoreleasepool to manage memory efficiently in widget extension
        var entries: [VaniWidgetEntry] = []
        
        autoreleasepool {
            // Load verses first
            let repository = BundleGitaRepository()
            do {
                let data = try repository.loadData()
                let krishnaVerses = repository.getKrishnaVerses(from: data)
                
                guard !krishnaVerses.isEmpty else {
                    // No verses available - create error entry
                    entries.append(createErrorEntry(for: currentDate))
                    let nextTime = schedule.nextScheduledTime(after: currentDate)
                    let timeline = Timeline(entries: entries, policy: .after(nextTime))
                    completion(timeline)
                    return
                }
                
                // Get rotation manager for timeline generation
                let rotationManager = VerseRotationManager.forWidget()
                
                // CRITICAL: For the current entry, use getCurrentVerse to actually advance rotation if needed
                // This ensures the rotation state is updated when the widget refreshes at scheduled times
                let currentEntry = createEntry(for: currentDate)
                entries.append(currentEntry)
                
                // For the next scheduled entry, use generateTimelineEntries to simulate without advancing
                // This prevents premature rotation advances while still showing the correct future verse
                let nextTime = schedule.nextScheduledTime(after: currentDate)
                let timelineEntries = rotationManager.generateTimelineEntries(from: krishnaVerses, startDate: currentDate)
                
                // Find the next entry from the timeline (compare dates within same minute to handle timing differences)
                let calendar = Calendar.current
                if let nextEntry = timelineEntries.first(where: { 
                    calendar.isDate($0.date, equalTo: nextTime, toGranularity: .minute)
                }) {
                    let entry = createEntryFromVerse(verse: nextEntry.verse, for: nextTime, defaults: defaults)
                    entries.append(entry)
                } else if timelineEntries.count > 1 {
                    // Fallback: use the second entry (should be the next scheduled one)
                    let nextEntry = timelineEntries[1]
                    let entry = createEntryFromVerse(verse: nextEntry.verse, for: nextTime, defaults: defaults)
                    entries.append(entry)
                }
                
            } catch {
                // Error loading data - create error entry
                entries.append(createErrorEntry(for: currentDate))
            }
        }
        
        // Ensure we always have at least one entry
        if entries.isEmpty {
            entries.append(createErrorEntry(for: currentDate))
        }
        
        // Set refresh policy to next scheduled time
        let nextTime = schedule.nextScheduledTime(after: currentDate)
        let timeline = Timeline(entries: entries, policy: .after(nextTime))
        
        // Always call completion to prevent widget extension from hanging
        completion(timeline)
    }
    
    /// Creates an entry from a verse without calling getCurrentVerse (prevents rotation advances)
    private func createEntryFromVerse(verse: Verse, for date: Date, defaults: UserDefaults) -> VaniWidgetEntry {
        // Read theme
        let theme: AppTheme = {
            guard let raw = defaults.string(forKey: AppConstants.UserDefaultsKeys.appTheme),
                  let t = AppTheme(rawValue: raw) else { return .pureBlack }
            return t
        }()
        
        // Read widget display settings
        let mediumMode: MediumWidgetMode = {
            guard let raw = defaults.string(forKey: AppConstants.UserDefaultsKeys.mediumWidgetMode),
                  let mode = MediumWidgetMode(rawValue: raw) else { return .transliteration }
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
        
        return VaniWidgetEntry(
            date: date,
            verse: verse,
            mediumMode: mediumMode,
            largeTop: largeTop,
            largeBottom: largeBottom,
            theme: theme,
            hasError: false
        )
    }
    
    /// Creates an error entry
    private func createErrorEntry(for date: Date) -> VaniWidgetEntry {
        let defaults = AppConstants.sharedUserDefaults ?? UserDefaults.standard
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
            hasError: true
        )
    }
    
    private func createEntry(for date: Date) -> VaniWidgetEntry {
        // Read fresh settings directly from shared UserDefaults (not cached singleton)
        // Use safe fallback to standard UserDefaults if shared is unavailable
        let defaults = AppConstants.sharedUserDefaults ?? UserDefaults.standard
        
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
                  let mode = MediumWidgetMode(rawValue: raw) else { return .transliteration }
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
        // Use autoreleasepool to manage memory efficiently in widget extension
        let repository = BundleGitaRepository()
        
        // Wrap in autoreleasepool to help with memory management
        return autoreleasepool {
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
                
                // CRITICAL: Optimize widget verse selection to prevent unnecessary rotation advances
                // Strategy: Check slot key first, only call getCurrentVerse if slot actually changed
                let verse: Verse?
                
                // Calculate current slot key
                let schedule: VerseSchedule = {
                    guard let raw = defaults.string(forKey: AppConstants.UserDefaultsKeys.verseSchedule),
                          let s = VerseSchedule(rawValue: raw) else { return .oncePerDay }
                    return s
                }()
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let dateString = formatter.string(from: date)
                let slotIndex = schedule.currentSlotIndex(for: date)
                let currentSlotKey = "\(dateString)-\(slotIndex)"
                
                // Read saved slot key
                let savedSlotKey = defaults.string(forKey: AppConstants.UserDefaultsKeys.lastScheduledSlot) ?? ""
                
                // If slot hasn't changed and we have a saved verse ID, use it directly
                // This prevents unnecessary calls to getCurrentVerse which could cause advances
                if savedSlotKey == currentSlotKey, let savedId = currentVerseId,
                   let savedVerse = VerseSelector.findVerse(byId: savedId, from: krishnaVerses) {
                    // Same slot, use saved verse - no need to call rotation manager
                    verse = savedVerse
                } else {
                    // Slot changed or no saved verse - need to call rotation manager
                    // This will handle slot changes and advance if needed
                    let rotationManager = VerseRotationManager.forWidget()
                    let verseResult = rotationManager.getCurrentVerse(from: krishnaVerses, for: date)
                    
                    if let verseFromManager = verseResult {
                        verse = verseFromManager
                        // The rotation manager already saves the verse ID when it advances
                    } else {
                        // Fallback: try to use saved verse ID if rotation manager fails
                        if let currentId = currentVerseId,
                           let savedVerse = VerseSelector.findVerse(byId: currentId, from: krishnaVerses) {
                            verse = savedVerse
                        } else {
                            // Final fallback: use first verse
                            verse = krishnaVerses.first
                        }
                    }
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
                // Handle all errors gracefully - widget extensions must never crash
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
                        HStack(alignment: .center) {
                            Text("Kṛṣṇa Vāṇī")
                                .font(.system(size: 17, weight: .semibold, design: theme.fontDesign))
                                .foregroundStyle(theme.accentColor)
                            
                            Spacer()
                            
                            Text("BG \(verse.id)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(theme.isLightTheme ? .white : theme.backgroundColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(theme.accentColor)
                                        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                                )
                        }
                        
                        Divider()
                            .background(theme.accentColor.opacity(0.3))
                            .padding(.vertical, 6)
                        
                        Spacer(minLength: 0)
                        
                        // Main content
                        mainContent(for: verse)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                        
                        Spacer(minLength: 0)
                    }
                    .padding(8)
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
                .font(.system(size: 17, weight: .regular, design: theme.fontDesign))
                .foregroundStyle(theme.sanskritTextColor)
                .lineSpacing(6)
                .lineLimit(4)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: false)
            
        case .transliteration:
            Text(verse.transliteration)
                .font(.system(size: 15, weight: .regular, design: theme.fontDesign))
                .italic()
                .foregroundStyle(theme.primaryTextColor.opacity(0.95))
                .lineSpacing(5)
                .lineLimit(5)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: false)
            
        case .essence:
            Text(personalizedText(for: verse))
                .font(themedFont(size: 17, weight: theme.bodyFontWeight))
                .foregroundStyle(theme.primaryTextColor.opacity(0.95))
                .lineSpacing(6)
                .lineLimit(4)
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
                    }
                    .padding(8)
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
                Text(chapterTransliteration(for: verse))
                    .font(.system(size: 10))
                    .foregroundStyle(theme.secondaryTextColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Bhagavad Gītā")
                    .font(.system(size: 10))
                    .foregroundStyle(theme.secondaryTextColor)
                Text(verse.id)
                    .font(.system(size: 18, weight: .semibold, design: theme.fontDesign))
                    .foregroundStyle(theme.accentColor)
            }
        }
    }
    
    /// Gets the chapter transliteration for a verse
    private func chapterTransliteration(for verse: Verse) -> String {
        // Extract chapter number from verse ID (e.g., "15.5" -> 15)
        guard let chapterNumber = Int(verse.id.split(separator: ".").first ?? "") else {
            return "Daily Wisdom" // Fallback
        }
        
        // Load data and get chapter
        do {
            let repository = BundleGitaRepository()
            let data = try repository.loadData()
            if let chapter = data.chapter(chapterNumber) {
                return chapter.chapterNameTransliteration
            }
        } catch {
            // If loading fails, return fallback
        }
        
        return "Daily Wisdom" // Fallback
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
