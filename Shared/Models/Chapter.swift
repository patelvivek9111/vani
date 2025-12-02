//
//  Chapter.swift
//  Vani
//
//  Data model representing chapter-level metadata from the Bhagavad Gita.
//

import Foundation

/// Represents metadata for a chapter of the Bhagavad Gita
struct Chapter: Codable, Identifiable, Equatable {
    
    /// Chapter number (1-18)
    let chapterNumber: Int
    
    /// Sanskrit name in Devanagari
    let chapterNameSanskrit: String
    
    /// Romanized transliteration of the chapter name
    let chapterNameTransliteration: String
    
    /// English name/title of the chapter
    let chapterNameEnglish: String
    
    /// Total number of verses in the chapter
    let totalVerses: Int
    
    /// Number of verses spoken by Krishna
    let krishnaVerses: Int
    
    /// Brief thematic description of the chapter
    let theme: String
    
    // MARK: - Identifiable
    
    var id: Int { chapterNumber }
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case chapterNumber = "chapter_number"
        case chapterNameSanskrit = "chapter_name_sanskrit"
        case chapterNameTransliteration = "chapter_name_transliteration"
        case chapterNameEnglish = "chapter_name_english"
        case totalVerses = "total_verses"
        case krishnaVerses = "krishna_verses"
        case theme
    }
}

// MARK: - Sample Data for Previews

extension Chapter {
    static let sample = Chapter(
        chapterNumber: 2,
        chapterNameSanskrit: "साङ्ख्ययोगः",
        chapterNameTransliteration: "Sāṅkhya-yogaḥ",
        chapterNameEnglish: "Sankhya Yoga – The Yoga of Knowledge",
        totalVerses: 72,
        krishnaVerses: 63,
        theme: "Krishna reveals the nature of the soul, the duty of a warrior, and introduces Karma-yoga and the qualities of a steady, wise person."
    )
}





