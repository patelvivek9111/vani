//
//  VerseSelector.swift
//  Vani
//
//  Utilities for selecting verses from a filtered list.
//

import Foundation

/// Utility for selecting verses
enum VerseSelector {
    
    // MARK: - Find by ID
    
    /// Finds a verse by its ID from the provided array
    /// Returns nil if not found
    static func findVerse(byId id: String?, from verses: [Verse]) -> Verse? {
        guard let id = id else { return nil }
        return verses.first { $0.id == id }
    }
    
    // MARK: - Random Selection
    
    /// Selects a random verse from the provided array
    /// Returns nil if the array is empty
    static func selectRandomVerse(from verses: [Verse]) -> Verse? {
        verses.randomElement()
    }
    
    // MARK: - Verse of the Day
    
    /// Selects a verse deterministically based on the date
    /// This ensures the same verse appears all day for consistency (especially in widgets)
    /// Returns nil if the array is empty
    static func selectVerseOfTheDay(from verses: [Verse], date: Date = Date()) -> Verse? {
        guard !verses.isEmpty else { return nil }
        
        // Use day of year to get a consistent index for the entire day
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        
        // Use modulo to wrap around if we have fewer verses than days
        let index = (dayOfYear - 1) % verses.count
        
        return verses[index]
    }
    
    // MARK: - Sequential Selection
    
    /// Returns the next verse after the current one (wraps around)
    static func selectNextVerse(after currentVerse: Verse, from verses: [Verse]) -> Verse? {
        guard !verses.isEmpty else { return nil }
        
        guard let currentIndex = verses.firstIndex(where: { $0.id == currentVerse.id }) else {
            return verses.first
        }
        
        let nextIndex = (currentIndex + 1) % verses.count
        return verses[nextIndex]
    }
    
    /// Returns the previous verse before the current one (wraps around)
    static func selectPreviousVerse(before currentVerse: Verse, from verses: [Verse]) -> Verse? {
        guard !verses.isEmpty else { return nil }
        
        guard let currentIndex = verses.firstIndex(where: { $0.id == currentVerse.id }) else {
            return verses.last
        }
        
        let previousIndex = currentIndex == 0 ? verses.count - 1 : currentIndex - 1
        return verses[previousIndex]
    }
}





