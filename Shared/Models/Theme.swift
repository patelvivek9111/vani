//
//  Theme.swift
//  Vani
//
//  Theme definitions for app customization.
//

import SwiftUI

// MARK: - App Theme

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case midnightGold
    case pureBlack
    case sacredLotus
    case divineBlue
    case forestAshram
    case celestial
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .midnightGold: return "Midnight Gold"
        case .pureBlack: return "Pure Black"
        case .sacredLotus: return "Sacred Lotus"
        case .divineBlue: return "Divine Blue"
        case .forestAshram: return "Forest Ashram"
        case .celestial: return "Celestial"
        }
    }
    
    var description: String {
        switch self {
        case .midnightGold: return "Elegant dark with golden warmth"
        case .pureBlack: return "Minimal OLED black"
        case .sacredLotus: return "Soft cream with rose accents"
        case .divineBlue: return "Krishna's divine blue essence"
        case .forestAshram: return "Peaceful earth tones"
        case .celestial: return "Cosmic purple serenity"
        }
    }
    
    // MARK: - Background Colors
    
    var backgroundColor: Color {
        switch self {
        case .midnightGold:
            return Color(red: 0.12, green: 0.10, blue: 0.08)
        case .pureBlack:
            return Color.black
        case .sacredLotus:
            return Color(red: 0.98, green: 0.95, blue: 0.92)
        case .divineBlue:
            return Color(red: 0.08, green: 0.12, blue: 0.18)
        case .forestAshram:
            return Color(red: 0.10, green: 0.12, blue: 0.08)
        case .celestial:
            return Color(red: 0.12, green: 0.08, blue: 0.16)
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .midnightGold:
            return [
                Color(red: 0.12, green: 0.10, blue: 0.08),
                Color(red: 0.18, green: 0.14, blue: 0.10),
                Color(red: 0.14, green: 0.11, blue: 0.08)
            ]
        case .pureBlack:
            return [
                Color.black,
                Color(red: 0.05, green: 0.05, blue: 0.05),
                Color.black
            ]
        case .sacredLotus:
            return [
                Color(red: 0.98, green: 0.95, blue: 0.92),
                Color(red: 0.96, green: 0.90, blue: 0.88),
                Color(red: 0.98, green: 0.94, blue: 0.91)
            ]
        case .divineBlue:
            return [
                Color(red: 0.08, green: 0.12, blue: 0.18),
                Color(red: 0.10, green: 0.16, blue: 0.24),
                Color(red: 0.06, green: 0.10, blue: 0.16)
            ]
        case .forestAshram:
            return [
                Color(red: 0.10, green: 0.12, blue: 0.08),
                Color(red: 0.14, green: 0.16, blue: 0.10),
                Color(red: 0.08, green: 0.10, blue: 0.06)
            ]
        case .celestial:
            return [
                Color(red: 0.12, green: 0.08, blue: 0.16),
                Color(red: 0.16, green: 0.10, blue: 0.22),
                Color(red: 0.10, green: 0.06, blue: 0.14)
            ]
        }
    }
    
    var glowColor: Color {
        switch self {
        case .midnightGold:
            return Color(red: 0.85, green: 0.65, blue: 0.35)
        case .pureBlack:
            return Color.white
        case .sacredLotus:
            return Color(red: 0.85, green: 0.55, blue: 0.60)
        case .divineBlue:
            return Color(red: 0.40, green: 0.60, blue: 0.85)
        case .forestAshram:
            return Color(red: 0.55, green: 0.70, blue: 0.45)
        case .celestial:
            return Color(red: 0.70, green: 0.50, blue: 0.85)
        }
    }
    
    // MARK: - Text Colors
    
    var primaryTextColor: Color {
        switch self {
        case .midnightGold:
            return Color.white.opacity(0.95)
        case .pureBlack:
            return Color.white.opacity(0.9)
        case .sacredLotus:
            return Color(red: 0.25, green: 0.20, blue: 0.18)
        case .divineBlue:
            return Color.white.opacity(0.95)
        case .forestAshram:
            return Color(red: 0.95, green: 0.92, blue: 0.85)
        case .celestial:
            return Color.white.opacity(0.95)
        }
    }
    
    var accentColor: Color {
        switch self {
        case .midnightGold:
            return Color(red: 0.85, green: 0.75, blue: 0.55)
        case .pureBlack:
            return Color.white
        case .sacredLotus:
            return Color(red: 0.75, green: 0.45, blue: 0.50)
        case .divineBlue:
            return Color(red: 0.55, green: 0.75, blue: 0.95)
        case .forestAshram:
            return Color(red: 0.65, green: 0.78, blue: 0.50)
        case .celestial:
            return Color(red: 0.80, green: 0.65, blue: 0.95)
        }
    }
    
    var secondaryTextColor: Color {
        switch self {
        case .midnightGold:
            return Color.white.opacity(0.5)
        case .pureBlack:
            return Color.white.opacity(0.4)
        case .sacredLotus:
            return Color(red: 0.45, green: 0.40, blue: 0.38)
        case .divineBlue:
            return Color.white.opacity(0.5)
        case .forestAshram:
            return Color.white.opacity(0.5)
        case .celestial:
            return Color.white.opacity(0.5)
        }
    }
    
    var sanskritTextColor: Color {
        switch self {
        case .midnightGold:
            return Color(red: 0.95, green: 0.88, blue: 0.75)
        case .pureBlack:
            return Color.white.opacity(0.85)
        case .sacredLotus:
            return Color(red: 0.55, green: 0.35, blue: 0.30)
        case .divineBlue:
            return Color(red: 0.75, green: 0.88, blue: 0.98)
        case .forestAshram:
            return Color(red: 0.88, green: 0.92, blue: 0.78)
        case .celestial:
            return Color(red: 0.92, green: 0.85, blue: 0.98)
        }
    }
    
    // MARK: - UI Colors
    
    var buttonBackgroundColor: Color {
        switch self {
        case .midnightGold:
            return Color.white.opacity(0.08)
        case .pureBlack:
            return Color.white.opacity(0.1)
        case .sacredLotus:
            return Color(red: 0.75, green: 0.45, blue: 0.50).opacity(0.12)
        case .divineBlue:
            return Color.white.opacity(0.08)
        case .forestAshram:
            return Color.white.opacity(0.08)
        case .celestial:
            return Color.white.opacity(0.08)
        }
    }
    
    var buttonGradient: [Color] {
        switch self {
        case .midnightGold:
            return [Color(red: 0.85, green: 0.6, blue: 0.3), Color(red: 0.75, green: 0.5, blue: 0.25)]
        case .pureBlack:
            return [Color.white, Color.white.opacity(0.8)]
        case .sacredLotus:
            return [Color(red: 0.75, green: 0.45, blue: 0.50), Color(red: 0.65, green: 0.35, blue: 0.40)]
        case .divineBlue:
            return [Color(red: 0.35, green: 0.55, blue: 0.80), Color(red: 0.25, green: 0.45, blue: 0.70)]
        case .forestAshram:
            return [Color(red: 0.45, green: 0.60, blue: 0.35), Color(red: 0.35, green: 0.50, blue: 0.28)]
        case .celestial:
            return [Color(red: 0.60, green: 0.40, blue: 0.75), Color(red: 0.50, green: 0.30, blue: 0.65)]
        }
    }
    
    var shareButtonTextColor: Color {
        switch self {
        case .pureBlack:
            return Color.black
        default:
            return Color.white
        }
    }
    
    // MARK: - Font Style (Unique per theme)
    
    /// Custom font name - if set, use this instead of fontDesign
    var customFontName: String? {
        switch self {
        case .pureBlack:
            return "American Typewriter"
        case .divineBlue:
            return "Palatino"
        case .sacredLotus:
            return "Baskerville"
        default:
            return nil
        }
    }
    
    var fontDesign: Font.Design {
        switch self {
        case .midnightGold:
            return .serif          // Classic serif
        case .pureBlack:
            return .default        // Fallback (customFontName is used)
        case .sacredLotus:
            return .serif          // Elegant serif
        case .divineBlue:
            return .rounded        // Fallback (customFontName is used)
        case .forestAshram:
            return .serif          // Natural serif
        case .celestial:
            return .rounded        // Mystical rounded
        }
    }
    
    /// Helper to create a font with the theme's style
    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let customFont = customFontName {
            return .custom(customFont, size: size)
        } else {
            return .system(size: size, weight: weight, design: fontDesign)
        }
    }
    
    var titleFontWeight: Font.Weight {
        switch self {
        case .midnightGold:
            return .light
        case .pureBlack:
            return .thin
        case .sacredLotus:
            return .light
        case .divineBlue:
            return .regular
        case .forestAshram:
            return .light
        case .celestial:
            return .light
        }
    }
    
    var bodyFontWeight: Font.Weight {
        switch self {
        case .midnightGold:
            return .light
        case .pureBlack:
            return .light
        case .sacredLotus:
            return .regular
        case .divineBlue:
            return .light
        case .forestAshram:
            return .light
        case .celestial:
            return .light
        }
    }
    
    var isLightTheme: Bool {
        switch self {
        case .sacredLotus:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Tab Bar Colors
    
    var tabBarBackground: Color {
        switch self {
        case .pureBlack:
            return Color.black
        case .sacredLotus:
            return Color(red: 0.96, green: 0.93, blue: 0.90)
        default:
            return backgroundColor.opacity(0.95)
        }
    }
    
    var tabBarTint: Color {
        return accentColor
    }
    
    // MARK: - Preview Sample Text
    
    var previewText: String {
        return "Abcd"
    }
}




