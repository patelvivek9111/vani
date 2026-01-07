//
//  Verse.swift
//  Vani
//
//  Data model representing a single verse from the Bhagavad Gita.
//

import Foundation

/// Represents a single verse from the Bhagavad Gita
struct Verse: Codable, Identifiable, Equatable {
    
    /// Unique identifier (e.g., "2.47" for Chapter 2, Verse 47)
    let id: String
    
    /// Verse number within the chapter
    let verseNumber: Int
    
    /// Speaker of the verse (e.g., "Krishna", "Arjuna", "Sanjaya")
    let speaker: String
    
    /// Sanskrit text in Devanagari script
    let sanskrit: String
    
    /// Romanized transliteration of the Sanskrit
    let transliteration: String
    
    /// Whether the verse contains vocative terms (names like Arjuna, Partha)
    let hasVocative: Bool
    
    /// List of vocative terms used in the verse
    let vocativeTerms: [String]
    
    /// Full English translation
    let translationFull: String
    
    /// Short, widget-friendly summary line
    let widgetLine: String
    
    /// Personalized version of widget_line with {name} placeholder (only for verses with vocatives)
    let personalized: String?
    
    /// Key concept tags for filtering
    let keyConcepts: [String]
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case verseNumber = "verse_number"
        case speaker
        case sanskrit
        case transliteration
        case hasVocative = "has_vocative"
        case vocativeTerms = "vocative_terms"
        case translationFull = "translation_full"
        case widgetLine = "widget_line"
        case personalized
        case keyConcepts = "key_concepts"
    }
}

// MARK: - Sample Data for Previews

extension Verse {
    static let sample = Verse(
        id: "15.5",
        verseNumber: 5,
        speaker: "Krishna",
        sanskrit: "निर्मानमोहा जितसङ्गदोषा अध्यात्मनित्या विनिवृत्तकामाः ।\nद्वन्द्वैर्विमुक्ताः सुखदुःखसंज्ञैर्गच्छन्त्यमूढाः पदमव्ययं तत् ॥५॥",
        transliteration: "nir-māna-mohā jita-saṅga-doṣhā adhyātma-nityā vinivṛitta-kāmāḥ\ndvandvair vimuktāḥ sukha-duḥkha-saṁjñair gachchhanty amūḍhāḥ padam avyayaṁ tat",
        hasVocative: false,
        vocativeTerms: [],
        translationFull: "Those who are free from vanity and delusion, who have overcome the evil of attachment, who dwell constantly on the self and on God, who are free from the desire to enjoy the senses, and are beyond the dualities of pleasure and pain, such liberated personalities attain My eternal Abode.",
        widgetLine: "Those free from pride and confusion, who have overcome attachment, who think always of the self and God, who are beyond pleasure and pain—attain My eternal home.",
        personalized: nil,
        keyConcepts: ["detachment", "surrender", "liberation"]
    )
}


