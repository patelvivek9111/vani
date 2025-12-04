//
//  Constants.swift
//  Vani
//
//  Shared constants used by both the main app and widget extension.
//

import Foundation

/// App-wide constants shared between the main app and widget extension
enum AppConstants {
    
    /// App Group identifier for sharing data between app and widget
    /// IMPORTANT: This must match the App Group configured in Xcode capabilities
    static let appGroupIdentifier = "group.com.vani.shared"
    
    /// UserDefaults suite for shared settings
    static var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    /// Keys for UserDefaults storage
    enum UserDefaultsKeys {
        // Legacy
        static let displayMode = "displayMode"
        
        // Home screen display
        static let homeDisplayMode = "homeDisplayMode"
        
        // Theme
        static let appTheme = "appTheme"
        
        // Widget settings
        static let mediumWidgetMode = "mediumWidgetMode"
        static let largeWidgetTop = "largeWidgetTop"
        static let largeWidgetBottom = "largeWidgetBottom"
        
        // Current verse (synced across app, settings, widget)
        static let currentVerseId = "currentVerseId"
        
        // Verse schedule & rotation
        static let verseSchedule = "verseSchedule"
        static let verseRotationState = "verseRotationState"
        static let lastScheduledSlot = "lastScheduledSlot"  // "YYYY-MM-DD-slotIndex" format
        
        // Personalization
        static let userName = "userName"
        static let personalizationEnabled = "personalizationEnabled"
        
        // Favorites
        static let favoriteVerseIds = "favoriteVerseIds"
        
        // Notifications
        static let verseNotificationsEnabled = "verseNotificationsEnabled"
        static let mindfulnessFrequency = "mindfulnessFrequency"
        
        // Onboarding
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let hasShownFirstVerse = "hasShownFirstVerse"
        
        // Share template
        static let shareTemplate = "shareTemplate"
    }
    
    /// Data file configuration
    enum DataFiles {
        static let gitaVersesFilename = "bhagavad_gita"
        static let gitaVersesExtension = "json"
    }
}
