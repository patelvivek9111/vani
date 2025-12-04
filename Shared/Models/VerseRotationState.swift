//
//  VerseRotationState.swift
//  Vani
//
//  Represents the state of the non-repeating verse rotation.
//

import Foundation

/// Represents the state of a non-repeating verse rotation
/// Stores the shuffled sequence and current position
struct VerseRotationState: Codable, Equatable {
    
    /// Ordered list of verse IDs in the current rotation
    /// Each verse appears exactly once in a shuffled order
    var shuffledVerseIds: [String]
    
    /// Index of the next verse to show (0-based)
    /// When this equals shuffledVerseIds.count, rotation is exhausted
    var currentIndex: Int
    
    /// Timestamp when this rotation was created
    /// Used for debugging and potential expiration logic
    var createdAt: Date
    
    /// Timestamp of the last verse advancement
    var lastAdvancedAt: Date
    
    // MARK: - Computed Properties
    
    /// Whether the rotation is exhausted (all verses shown)
    var isExhausted: Bool {
        currentIndex >= shuffledVerseIds.count
    }
    
    /// Number of verses remaining in this rotation
    var remainingCount: Int {
        max(0, shuffledVerseIds.count - currentIndex)
    }
    
    /// Total number of verses in this rotation
    var totalCount: Int {
        shuffledVerseIds.count
    }
    
    /// Progress through the rotation (0.0 to 1.0)
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(currentIndex) / Double(totalCount)
    }
    
    /// The current verse ID (nil if exhausted)
    var currentVerseId: String? {
        guard !isExhausted else { return nil }
        return shuffledVerseIds[currentIndex]
    }
    
    // MARK: - Initialization
    
    /// Creates a new rotation state from a list of eligible verse IDs
    /// The IDs are shuffled automatically
    init(verseIds: [String]) {
        self.shuffledVerseIds = verseIds.shuffled()
        self.currentIndex = 0
        self.createdAt = Date()
        self.lastAdvancedAt = Date()
    }
    
    /// Creates an empty rotation state
    static var empty: VerseRotationState {
        VerseRotationState(verseIds: [])
    }
    
    // MARK: - Mutation Methods
    
    /// Advances to the next verse in the rotation
    /// Returns the verse ID that was advanced to, or nil if exhausted
    @discardableResult
    mutating func advance() -> String? {
        guard !isExhausted else { return nil }
        currentIndex += 1
        lastAdvancedAt = Date()
        return currentVerseId
    }
    
    /// Resets the rotation with new verse IDs (re-shuffles)
    /// - Parameter firstVerseId: Optional verse ID to place first in the rotation
    mutating func reset(with verseIds: [String], firstVerseId: String? = nil) {
        var newShuffledIds = verseIds.shuffled()
        
        // If a first verse is specified, ensure it's first
        if let firstId = firstVerseId, let index = newShuffledIds.firstIndex(of: firstId) {
            newShuffledIds.remove(at: index)
            newShuffledIds.insert(firstId, at: 0)
        }
        
        self.shuffledVerseIds = newShuffledIds
        self.currentIndex = 0
        self.createdAt = Date()
        self.lastAdvancedAt = Date()
    }
    
    /// Checks if a specific verse ID exists in the remaining rotation
    func hasRemaining(verseId: String) -> Bool {
        guard let index = shuffledVerseIds.firstIndex(of: verseId) else { return false }
        return index >= currentIndex
    }
    
    /// Gets the verse ID at a specific position from current
    /// offset 0 = current, offset 1 = next, etc.
    func verseId(atOffset offset: Int) -> String? {
        let targetIndex = currentIndex + offset
        guard targetIndex >= 0 && targetIndex < shuffledVerseIds.count else { return nil }
        return shuffledVerseIds[targetIndex]
    }
}

// MARK: - JSON Encoding/Decoding Helpers

extension VerseRotationState {
    
    /// Encodes the rotation state to JSON data
    func toJSONData() -> Data? {
        try? JSONEncoder().encode(self)
    }
    
    /// Decodes a rotation state from JSON data
    static func fromJSONData(_ data: Data) -> VerseRotationState? {
        try? JSONDecoder().decode(VerseRotationState.self, from: data)
    }
}




