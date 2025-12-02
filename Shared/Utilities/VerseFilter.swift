//
//  VerseFilter.swift
//  Vani
//
//  Utilities for filtering verses by various criteria.
//

import Foundation

/// Utility for filtering verses
enum VerseFilter {
    
    // MARK: - Filter by Speaker
    
    /// Returns verses spoken by the specified speaker
    static func filterBySpeaker(_ verses: [Verse], speaker: Speaker) -> [Verse] {
        verses.filter { $0.speaker == speaker.rawValue }
    }
    
    /// Returns only verses spoken by Krishna
    static func filterKrishnaOnly(_ verses: [Verse]) -> [Verse] {
        filterBySpeaker(verses, speaker: .krishna)
    }
    
    // MARK: - Filter by Key Concepts
    
    /// Returns verses matching ANY of the specified key concepts
    /// If concepts is empty, returns all verses (no filtering)
    static func filterByKeyConcepts(_ verses: [Verse], concepts: Set<String>) -> [Verse] {
        // Empty set = no filtering, return all
        guard !concepts.isEmpty else { return verses }
        
        return verses.filter { verse in
            // Check if verse has any of the selected concepts
            let verseConcepts = Set(verse.keyConcepts)
            return !verseConcepts.isDisjoint(with: concepts)
        }
    }
    
    // MARK: - Combined Filtering
    
    /// Applies all filters: Krishna-only and key concepts
    static func applyFilters(
        to verses: [Verse],
        krishnaOnly: Bool = true,
        concepts: Set<String> = []
    ) -> [Verse] {
        var result = verses
        
        if krishnaOnly {
            result = filterKrishnaOnly(result)
        }
        
        result = filterByKeyConcepts(result, concepts: concepts)
        
        return result
    }
    
    // MARK: - Key Concepts Extraction
    
    /// Extracts all unique key concepts from a collection of verses
    static func extractAllKeyConcepts(from verses: [Verse]) -> [String] {
        let allConcepts = verses.flatMap { $0.keyConcepts }
        let uniqueConcepts = Set(allConcepts)
        return uniqueConcepts.sorted()
    }
}





