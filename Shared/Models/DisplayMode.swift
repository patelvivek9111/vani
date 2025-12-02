//
//  DisplayMode.swift
//  Vani
//
//  Enums for widget display configuration.
//

import Foundation

// MARK: - Home Screen Display Mode

/// What the home screen displays
enum HomeDisplayMode: String, Codable, CaseIterable, Identifiable {
    case sanskrit
    case transliteration
    case translation
    case essence
    case personalized
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .sanskrit: return "Sanskrit"
        case .transliteration: return "Transliteration"
        case .translation: return "Translation"
        case .essence: return "Essence"
        case .personalized: return "Personalized"
        }
    }
    
    var description: String {
        switch self {
        case .sanskrit: return "Original Devanagari script with verse markers"
        case .transliteration: return "Romanized Sanskrit pronunciation"
        case .translation: return "Full English translation"
        case .essence: return "Core meaning in simple words"
        case .personalized: return "Personalized wisdom with your name"
        }
    }
}

// MARK: - Medium Widget Display Mode

/// What the medium widget displays (single content)
enum MediumWidgetMode: String, Codable, CaseIterable, Identifiable {
    case sanskrit
    case transliteration
    case essence
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .sanskrit: return "Sanskrit"
        case .transliteration: return "Transliteration"
        case .essence: return "Essence"
        }
    }
    
    var description: String {
        switch self {
        case .sanskrit: return "Original Devanagari script"
        case .transliteration: return "Romanized Sanskrit"
        case .essence: return "Core meaning of the verse"
        }
    }
}

// MARK: - Large Widget Top Section

/// What the large widget shows in the top section
enum LargeWidgetTop: String, Codable, CaseIterable, Identifiable {
    case sanskrit
    case transliteration
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .sanskrit: return "Sanskrit"
        case .transliteration: return "Transliteration"
        }
    }
    
    var description: String {
        switch self {
        case .sanskrit: return "Original Devanagari script"
        case .transliteration: return "Romanized Sanskrit"
        }
    }
}

// MARK: - Large Widget Bottom Section

/// What the large widget shows in the bottom section
enum LargeWidgetBottom: String, Codable, CaseIterable, Identifiable {
    case translation
    case essence
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .translation: return "Translation"
        case .essence: return "Essence"
        }
    }
    
    var description: String {
        switch self {
        case .translation: return "Full English translation"
        case .essence: return "Core meaning of the verse"
        }
    }
}

// MARK: - Legacy DisplayMode (kept for compatibility)

/// Legacy display mode - kept for backward compatibility
enum DisplayMode: String, Codable, CaseIterable, Identifiable {
    case sanskrit
    case transliteration
    case translation
    case sanskritAndTranslation
    case transliterationAndTranslation
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .sanskrit: return "Sanskrit"
        case .transliteration: return "Transliteration"
        case .translation: return "Essence"
        case .sanskritAndTranslation: return "Sanskrit + Translation"
        case .transliterationAndTranslation: return "Transliteration + Translation"
        }
    }
}
