//
//  SettingsManager.swift
//  Vani
//
//  Manages user settings with App Group sharing for widget access.
//

import Foundation
import Combine

/// Manages user settings and persists them to shared UserDefaults
final class SettingsManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = SettingsManager()
    
    // MARK: - Published Properties (Home Screen Display)
    
    /// Home screen display mode
    @Published var homeDisplayMode: HomeDisplayMode {
        didSet { saveHomeDisplayMode() }
    }
    
    /// App theme
    @Published var appTheme: AppTheme {
        didSet { saveAppTheme() }
    }
    
    // MARK: - Published Properties (Widget Display Settings)
    
    /// Medium widget display mode (Sanskrit, Transliteration, or Essence)
    @Published var mediumWidgetMode: MediumWidgetMode {
        didSet { saveMediumWidgetMode() }
    }
    
    /// Large widget top section (Sanskrit or Transliteration)
    @Published var largeWidgetTop: LargeWidgetTop {
        didSet { saveLargeWidgetTop() }
    }
    
    /// Large widget bottom section (Translation or Essence)
    @Published var largeWidgetBottom: LargeWidgetBottom {
        didSet { saveLargeWidgetBottom() }
    }
    
    // MARK: - Published Properties (Current Verse)
    
    /// Current verse ID - synced across app, settings preview, and widgets
    @Published var currentVerseId: String? {
        didSet { saveCurrentVerseId() }
    }
    
    // MARK: - Published Properties (Verse Schedule)
    
    /// How often the verse changes (once or twice per day)
    @Published var verseSchedule: VerseSchedule {
        didSet {
            saveVerseSchedule()
            updateNotifications()
        }
    }
    
    // MARK: - Published Properties (Personalization)
    
    /// User's name for personalization (future feature)
    @Published var userName: String {
        didSet { saveUserName() }
    }
    
    /// Whether personalization is enabled (future feature)
    @Published var personalizationEnabled: Bool {
        didSet { savePersonalizationEnabled() }
    }
    
    // MARK: - Published Properties (Favorites)
    
    /// Set of favorite verse IDs
    @Published var favoriteVerseIds: Set<String> {
        didSet { saveFavoriteVerseIds() }
    }
    
    // MARK: - Published Properties (Notifications)
    
    /// Whether verse notifications are enabled (tied to schedule)
    @Published var verseNotificationsEnabled: Bool {
        didSet {
            saveVerseNotificationsEnabled()
            updateNotifications()
        }
    }
    
    /// Mindfulness reminder frequency
    @Published var mindfulnessFrequency: MindfulnessFrequency {
        didSet {
            saveMindfulnessFrequency()
            updateNotifications()
        }
    }
    
    // MARK: - Published Properties (Onboarding)
    
    /// Whether the user has completed onboarding
    @Published var hasCompletedOnboarding: Bool {
        didSet { saveHasCompletedOnboarding() }
    }
    
    // MARK: - Published Properties (Share Template)
    
    /// Selected share card template
    @Published var shareTemplate: ShareTemplate {
        didSet { saveShareTemplate() }
    }
    
    // MARK: - Legacy (kept for compatibility)
    
    @Published var displayMode: DisplayMode {
        didSet { saveDisplayMode() }
    }
    
    // MARK: - Private Properties
    
    private let defaults: UserDefaults
    
    // MARK: - Initialization
    
    init(defaults: UserDefaults? = AppConstants.sharedUserDefaults) {
        self.defaults = defaults ?? .standard
        
        // Load home screen settings
        self.homeDisplayMode = Self.loadHomeDisplayMode(from: self.defaults)
        self.appTheme = Self.loadAppTheme(from: self.defaults)
        
        // Load widget settings
        self.mediumWidgetMode = Self.loadMediumWidgetMode(from: self.defaults)
        self.largeWidgetTop = Self.loadLargeWidgetTop(from: self.defaults)
        self.largeWidgetBottom = Self.loadLargeWidgetBottom(from: self.defaults)
        
        // Load current verse
        self.currentVerseId = Self.loadCurrentVerseId(from: self.defaults)
        
        // Load verse schedule
        self.verseSchedule = Self.loadVerseSchedule(from: self.defaults)
        
        // Load personalization
        self.userName = Self.loadUserName(from: self.defaults)
        self.personalizationEnabled = Self.loadPersonalizationEnabled(from: self.defaults)
        
        // Load favorites
        self.favoriteVerseIds = Self.loadFavoriteVerseIds(from: self.defaults)
        
        // Load notifications
        self.verseNotificationsEnabled = Self.loadVerseNotificationsEnabled(from: self.defaults)
        self.mindfulnessFrequency = Self.loadMindfulnessFrequency(from: self.defaults)
        
        // Load onboarding
        self.hasCompletedOnboarding = Self.loadHasCompletedOnboarding(from: self.defaults)
        
        // Load share template
        self.shareTemplate = Self.loadShareTemplate(from: self.defaults)
        
        // Legacy
        self.displayMode = Self.loadDisplayMode(from: self.defaults)
    }
    
    // MARK: - Loading Methods (Home Screen)
    
    private static func loadHomeDisplayMode(from defaults: UserDefaults) -> HomeDisplayMode {
        guard let rawValue = defaults.string(forKey: AppConstants.UserDefaultsKeys.homeDisplayMode),
              let mode = HomeDisplayMode(rawValue: rawValue) else {
            return .essence // Default
        }
        return mode
    }
    
    private static func loadAppTheme(from defaults: UserDefaults) -> AppTheme {
        guard let rawValue = defaults.string(forKey: AppConstants.UserDefaultsKeys.appTheme),
              let theme = AppTheme(rawValue: rawValue) else {
            return .pureBlack // Default
        }
        return theme
    }
    
    // MARK: - Loading Methods (Widget Settings)
    
    private static func loadMediumWidgetMode(from defaults: UserDefaults) -> MediumWidgetMode {
        guard let rawValue = defaults.string(forKey: AppConstants.UserDefaultsKeys.mediumWidgetMode),
              let mode = MediumWidgetMode(rawValue: rawValue) else {
            return .essence // Default
        }
        return mode
    }
    
    private static func loadLargeWidgetTop(from defaults: UserDefaults) -> LargeWidgetTop {
        guard let rawValue = defaults.string(forKey: AppConstants.UserDefaultsKeys.largeWidgetTop),
              let mode = LargeWidgetTop(rawValue: rawValue) else {
            return .sanskrit // Default
        }
        return mode
    }
    
    private static func loadLargeWidgetBottom(from defaults: UserDefaults) -> LargeWidgetBottom {
        guard let rawValue = defaults.string(forKey: AppConstants.UserDefaultsKeys.largeWidgetBottom),
              let mode = LargeWidgetBottom(rawValue: rawValue) else {
            return .essence // Default
        }
        return mode
    }
    
    private static func loadCurrentVerseId(from defaults: UserDefaults) -> String? {
        defaults.string(forKey: AppConstants.UserDefaultsKeys.currentVerseId)
    }
    
    // MARK: - Loading Methods (Verse Schedule)
    
    private static func loadVerseSchedule(from defaults: UserDefaults) -> VerseSchedule {
        guard let raw = defaults.string(forKey: AppConstants.UserDefaultsKeys.verseSchedule),
              let schedule = VerseSchedule(rawValue: raw) else {
            return .oncePerDay // Default
        }
        return schedule
    }
    
    // MARK: - Loading Methods (Personalization)
    
    private static func loadUserName(from defaults: UserDefaults) -> String {
        defaults.string(forKey: AppConstants.UserDefaultsKeys.userName) ?? ""
    }
    
    private static func loadPersonalizationEnabled(from defaults: UserDefaults) -> Bool {
        defaults.bool(forKey: AppConstants.UserDefaultsKeys.personalizationEnabled)
    }
    
    private static func loadFavoriteVerseIds(from defaults: UserDefaults) -> Set<String> {
        guard let array = defaults.array(forKey: AppConstants.UserDefaultsKeys.favoriteVerseIds) as? [String] else {
            return []
        }
        return Set(array)
    }
    
    // MARK: - Loading Methods (Notifications)
    
    private static func loadVerseNotificationsEnabled(from defaults: UserDefaults) -> Bool {
        // Default to false - user must opt in
        defaults.bool(forKey: AppConstants.UserDefaultsKeys.verseNotificationsEnabled)
    }
    
    private static func loadMindfulnessFrequency(from defaults: UserDefaults) -> MindfulnessFrequency {
        guard let raw = defaults.string(forKey: AppConstants.UserDefaultsKeys.mindfulnessFrequency),
              let frequency = MindfulnessFrequency(rawValue: raw) else {
            return .off  // Default to off
        }
        return frequency
    }
    
    private static func loadDisplayMode(from defaults: UserDefaults) -> DisplayMode {
        guard let rawValue = defaults.string(forKey: AppConstants.UserDefaultsKeys.displayMode),
              let mode = DisplayMode(rawValue: rawValue) else {
            return .translation
        }
        return mode
    }
    
    // MARK: - Loading Methods (Onboarding)
    
    private static func loadHasCompletedOnboarding(from defaults: UserDefaults) -> Bool {
        defaults.bool(forKey: AppConstants.UserDefaultsKeys.hasCompletedOnboarding)
    }
    
    // MARK: - Loading Methods (Share Template)
    
    private static func loadShareTemplate(from defaults: UserDefaults) -> ShareTemplate {
        if let rawValue = defaults.string(forKey: AppConstants.UserDefaultsKeys.shareTemplate),
           let template = ShareTemplate(rawValue: rawValue) {
            return template
        }
        return .classic // Default to classic (current design)
    }
    
    // MARK: - Saving Methods
    
    private func saveHomeDisplayMode() {
        defaults.set(homeDisplayMode.rawValue, forKey: AppConstants.UserDefaultsKeys.homeDisplayMode)
    }
    
    private func saveAppTheme() {
        defaults.set(appTheme.rawValue, forKey: AppConstants.UserDefaultsKeys.appTheme)
    }
    
    private func saveMediumWidgetMode() {
        defaults.set(mediumWidgetMode.rawValue, forKey: AppConstants.UserDefaultsKeys.mediumWidgetMode)
    }
    
    private func saveLargeWidgetTop() {
        defaults.set(largeWidgetTop.rawValue, forKey: AppConstants.UserDefaultsKeys.largeWidgetTop)
    }
    
    private func saveLargeWidgetBottom() {
        defaults.set(largeWidgetBottom.rawValue, forKey: AppConstants.UserDefaultsKeys.largeWidgetBottom)
    }
    
    private func saveCurrentVerseId() {
        defaults.set(currentVerseId, forKey: AppConstants.UserDefaultsKeys.currentVerseId)
    }
    
    private func saveVerseSchedule() {
        defaults.set(verseSchedule.rawValue, forKey: AppConstants.UserDefaultsKeys.verseSchedule)
    }
    
    private func saveUserName() {
        defaults.set(userName, forKey: AppConstants.UserDefaultsKeys.userName)
    }
    
    private func savePersonalizationEnabled() {
        defaults.set(personalizationEnabled, forKey: AppConstants.UserDefaultsKeys.personalizationEnabled)
    }
    
    private func saveDisplayMode() {
        defaults.set(displayMode.rawValue, forKey: AppConstants.UserDefaultsKeys.displayMode)
    }
    
    private func saveFavoriteVerseIds() {
        defaults.set(Array(favoriteVerseIds), forKey: AppConstants.UserDefaultsKeys.favoriteVerseIds)
    }
    
    private func saveVerseNotificationsEnabled() {
        defaults.set(verseNotificationsEnabled, forKey: AppConstants.UserDefaultsKeys.verseNotificationsEnabled)
    }
    
    private func saveMindfulnessFrequency() {
        defaults.set(mindfulnessFrequency.rawValue, forKey: AppConstants.UserDefaultsKeys.mindfulnessFrequency)
    }
    
    private func saveHasCompletedOnboarding() {
        defaults.set(hasCompletedOnboarding, forKey: AppConstants.UserDefaultsKeys.hasCompletedOnboarding)
    }
    
    private func saveShareTemplate() {
        defaults.set(shareTemplate.rawValue, forKey: AppConstants.UserDefaultsKeys.shareTemplate)
    }
    
    // MARK: - Notification Helpers
    
    /// Updates notifications based on current settings
    private func updateNotifications() {
        NotificationManager.shared.updateNotifications(
            verseSchedule: verseSchedule,
            verseNotificationsEnabled: verseNotificationsEnabled,
            mindfulnessFrequency: mindfulnessFrequency
        )
    }
    
    // MARK: - Convenience Methods
    
    /// Resets all settings to defaults
    func resetToDefaults() {
        homeDisplayMode = .essence
        appTheme = .pureBlack
        mediumWidgetMode = .essence
        largeWidgetTop = .sanskrit
        largeWidgetBottom = .essence
        currentVerseId = nil  // Will pick verse based on rotation
        verseSchedule = .oncePerDay
        userName = ""
        personalizationEnabled = false
        favoriteVerseIds = []
        verseNotificationsEnabled = false
        mindfulnessFrequency = .off
        displayMode = .translation
    }
    
    // MARK: - Favorites Methods
    
    /// Check if a verse is favorited
    func isFavorite(_ verseId: String) -> Bool {
        favoriteVerseIds.contains(verseId)
    }
    
    /// Toggle favorite status for a verse
    func toggleFavorite(_ verseId: String) {
        if favoriteVerseIds.contains(verseId) {
            favoriteVerseIds.remove(verseId)
        } else {
            favoriteVerseIds.insert(verseId)
        }
    }
    
    /// Add a verse to favorites
    func addFavorite(_ verseId: String) {
        favoriteVerseIds.insert(verseId)
    }
    
    /// Remove a verse from favorites
    func removeFavorite(_ verseId: String) {
        favoriteVerseIds.remove(verseId)
    }
}
