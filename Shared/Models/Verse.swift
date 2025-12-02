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
        id: "2.47",
        verseNumber: 47,
        speaker: "Krishna",
        sanskrit: "कर्मण्येवाधिकारस्ते मा फलेषु कदाचन ।\nमा कर्मफलहेतुर्भूर्मा ते सङ्गोऽस्त्वकर्मणि ॥४७॥",
        transliteration: "karmaṇy-evādhikāras te mā phaleṣhu kadāchana\nmā karma-phala-hetur bhūr mā te saṅgo 'stvakarmaṇi",
        hasVocative: false,
        vocativeTerms: [],
        translationFull: "You have a right to perform your prescribed duties, but you are not entitled to the fruits of your actions. Never consider yourself to be the cause of the results of your activities, nor be attached to inaction.",
        widgetLine: "You have a right to duty, not to its fruits; don't act for reward, nor cling to inaction.",
        personalized: nil,
        keyConcepts: ["karma_yoga", "detachment", "duty"]
    )
}


