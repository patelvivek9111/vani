//
//  VerseRotationManager.swift
//  Vani
//
//  Manages non-repeating verse rotation with time-based scheduling.
//  Shared between the main app and widget extension.
//

import Foundation
import Combine

/// Manages verse rotation ensuring no verse repeats until all have been shown
final class VerseRotationManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = VerseRotationManager()
    
    // MARK: - Published Properties
    
    /// Current verse schedule (once or twice per day)
    @Published var schedule: VerseSchedule {
        didSet { saveSchedule() }
    }
    
    /// Current rotation state
    @Published private(set) var rotationState: VerseRotationState {
        didSet { saveRotationState() }
    }
    
    /// The current verse ID to display
    @Published private(set) var currentVerseId: String?
    
    // MARK: - Private Properties
    
    private let defaults: UserDefaults
    private var lastScheduledSlot: String {
        get { defaults.string(forKey: AppConstants.UserDefaultsKeys.lastScheduledSlot) ?? "" }
        set { defaults.set(newValue, forKey: AppConstants.UserDefaultsKeys.lastScheduledSlot) }
    }
    
    // MARK: - Initialization
    
    init(defaults: UserDefaults? = AppConstants.sharedUserDefaults) {
        self.defaults = defaults ?? .standard
        
        // Load schedule
        self.schedule = Self.loadSchedule(from: self.defaults)
        
        // Load rotation state
        self.rotationState = Self.loadRotationState(from: self.defaults)
        
        // Load current verse ID (synced with SettingsManager)
        self.currentVerseId = defaults?.string(forKey: AppConstants.UserDefaultsKeys.currentVerseId)
    }
    
    // MARK: - Loading Methods
    
    private static func loadSchedule(from defaults: UserDefaults) -> VerseSchedule {
        guard let raw = defaults.string(forKey: AppConstants.UserDefaultsKeys.verseSchedule),
              let schedule = VerseSchedule(rawValue: raw) else {
            return .oncePerDay // Default
        }
        return schedule
    }
    
    private static func loadRotationState(from defaults: UserDefaults) -> VerseRotationState {
        guard let data = defaults.data(forKey: AppConstants.UserDefaultsKeys.verseRotationState),
              let state = VerseRotationState.fromJSONData(data) else {
            return .empty
        }
        return state
    }
    
    // MARK: - Saving Methods
    
    private func saveSchedule() {
        defaults.set(schedule.rawValue, forKey: AppConstants.UserDefaultsKeys.verseSchedule)
    }
    
    private func saveRotationState() {
        if let data = rotationState.toJSONData() {
            defaults.set(data, forKey: AppConstants.UserDefaultsKeys.verseRotationState)
        }
    }
    
    private func saveCurrentVerseId(_ verseId: String?) {
        defaults.set(verseId, forKey: AppConstants.UserDefaultsKeys.currentVerseId)
        currentVerseId = verseId
    }
    
    // MARK: - Core Rotation Logic
    
    /// Gets the current verse for a given time, advancing the rotation if needed
    /// This is the main entry point for both app and widget
    /// - Parameters:
    ///   - eligibleVerses: All verses that pass current filters
    ///   - date: The date/time to check (defaults to now)
    /// - Returns: The verse to display, or nil if no eligible verses
    func getCurrentVerse(from eligibleVerses: [Verse], for date: Date = Date()) -> Verse? {
        guard !eligibleVerses.isEmpty else { return nil }
        
        let eligibleIds = eligibleVerses.map { $0.id }
        
        // Ensure rotation is initialized/valid for current eligible verses
        ensureRotationValid(for: eligibleIds)
        
        // Check if we need to advance based on schedule
        let currentSlotKey = slotKey(for: date)
        
        if lastScheduledSlot != currentSlotKey {
            // Time slot changed - advance to next verse
            advanceRotation(eligibleIds: eligibleIds)
            lastScheduledSlot = currentSlotKey
        }
        
        // Return the current verse
        guard let verseId = rotationState.currentVerseId else {
            // Rotation exhausted - reset and get first
            resetRotation(with: eligibleIds)
            guard let newId = rotationState.currentVerseId else { return nil }
            saveCurrentVerseId(newId)
            return eligibleVerses.first { $0.id == newId }
        }
        
        // Sync the current verse ID
        if currentVerseId != verseId {
            saveCurrentVerseId(verseId)
        }
        
        return eligibleVerses.first { $0.id == verseId }
    }
    
    /// Manually advances to the next verse (e.g., user taps refresh)
    /// This also counts toward the rotation - no repeats
    /// - Parameter eligibleVerses: All verses that pass current filters
    /// - Returns: The new verse to display
    @discardableResult
    func advanceToNextVerse(from eligibleVerses: [Verse]) -> Verse? {
        guard !eligibleVerses.isEmpty else { return nil }
        
        let eligibleIds = eligibleVerses.map { $0.id }
        
        // Ensure rotation is valid
        ensureRotationValid(for: eligibleIds)
        
        // Advance the rotation
        advanceRotation(eligibleIds: eligibleIds)
        
        // Update the slot key so scheduled advance doesn't double-advance
        lastScheduledSlot = slotKey(for: Date())
        
        // Return the new verse
        guard let verseId = rotationState.currentVerseId else { return nil }
        return eligibleVerses.first { $0.id == verseId }
    }
    
    /// Resets the rotation with new verses (e.g., when filters change)
    func resetRotation(with verseIds: [String]) {
        rotationState.reset(with: verseIds)
        if let firstId = rotationState.currentVerseId {
            saveCurrentVerseId(firstId)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Generates a unique key for the current time slot
    /// Format: "YYYY-MM-DD-slotIndex"
    private func slotKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        let slotIndex = schedule.currentSlotIndex(for: date)
        return "\(dateString)-\(slotIndex)"
    }
    
    /// Ensures the rotation state is valid for the given eligible verses
    /// Resets if empty or if the eligible set has changed
    private func ensureRotationValid(for eligibleIds: [String]) {
        // Check if rotation is empty
        if rotationState.shuffledVerseIds.isEmpty {
            resetRotation(with: eligibleIds)
            return
        }
        
        // Check if eligible verses have changed (different set)
        let currentSet = Set(rotationState.shuffledVerseIds)
        let newSet = Set(eligibleIds)
        
        if currentSet != newSet {
            // Eligible set changed - reset rotation
            resetRotation(with: eligibleIds)
        }
    }
    
    /// Advances the rotation, resetting if exhausted
    private func advanceRotation(eligibleIds: [String]) {
        rotationState.advance()
        
        // If exhausted, reset with fresh shuffle
        if rotationState.isExhausted {
            resetRotation(with: eligibleIds)
        }
        
        // Update the current verse ID
        if let verseId = rotationState.currentVerseId {
            saveCurrentVerseId(verseId)
        }
    }
    
    // MARK: - Widget Timeline Support
    
    /// Generates timeline entries for the widget
    /// - Parameters:
    ///   - eligibleVerses: All verses that pass current filters
    ///   - startDate: Starting date for the timeline
    /// - Returns: Array of (date, verse) tuples for the timeline
    func generateTimelineEntries(from eligibleVerses: [Verse], startDate: Date = Date()) -> [(date: Date, verse: Verse)] {
        guard !eligibleVerses.isEmpty else { return [] }
        
        var entries: [(date: Date, verse: Verse)] = []
        let eligibleIds = eligibleVerses.map { $0.id }
        
        // Create a copy of rotation state for simulation
        var simulatedState = rotationState
        var simulatedSlotKey = lastScheduledSlot
        
        // Ensure simulated state is valid
        if simulatedState.shuffledVerseIds.isEmpty || Set(simulatedState.shuffledVerseIds) != Set(eligibleIds) {
            simulatedState.reset(with: eligibleIds)
        }
        
        // Get current slot key
        let currentSlotKey = slotKey(for: startDate)
        
        // If slot changed, advance simulation
        if simulatedSlotKey != currentSlotKey {
            simulatedState.advance()
            if simulatedState.isExhausted {
                simulatedState.reset(with: eligibleIds)
            }
            simulatedSlotKey = currentSlotKey
        }
        
        // First entry: current verse at current time
        if let verseId = simulatedState.currentVerseId,
           let verse = eligibleVerses.first(where: { $0.id == verseId }) {
            entries.append((date: startDate, verse: verse))
        }
        
        // Generate entries for next slot(s)
        let nextTime = schedule.nextScheduledTime(after: startDate)
        
        // Advance for next slot
        simulatedState.advance()
        if simulatedState.isExhausted {
            simulatedState.reset(with: eligibleIds)
        }
        
        if let verseId = simulatedState.currentVerseId,
           let verse = eligibleVerses.first(where: { $0.id == verseId }) {
            entries.append((date: nextTime, verse: verse))
        }
        
        return entries
    }
    
    /// Returns the next scheduled refresh time for the widget timeline policy
    func nextRefreshTime(after date: Date = Date()) -> Date {
        schedule.nextScheduledTime(after: date)
    }
}

// MARK: - Static Helpers for Widget (No Singleton Access)

extension VerseRotationManager {
    
    /// Creates a rotation manager instance for widget use
    /// Widget should create fresh instances to read latest shared state
    static func forWidget() -> VerseRotationManager {
        VerseRotationManager(defaults: AppConstants.sharedUserDefaults)
    }
}




