//
//  VerseRotationManager.swift
//  Vani
//
//  Manages non-repeating verse rotation with time-based scheduling.
//  Shared between the main app and widget extension.
//

import Foundation
import Combine
import WidgetKit

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
        
        // PRIORITY: Check if this is the first time after onboarding - show 15.5 immediately
        // This check MUST happen before any other rotation logic
        // Read directly from UserDefaults to ensure we get the latest values
        let hasCompletedOnboarding = defaults.bool(forKey: AppConstants.UserDefaultsKeys.hasCompletedOnboarding)
        let hasShownFirstVerse = defaults.bool(forKey: AppConstants.UserDefaultsKeys.hasShownFirstVerse)
        
        // CRITICAL: If onboarding just completed and first verse hasn't been shown, 
        // AND 15.5 is in eligible verses, show it immediately regardless of rotation state
        if hasCompletedOnboarding && !hasShownFirstVerse && eligibleIds.contains("15.5") {
            // Force reset with 15.5 as first - this MUST be the first verse shown
            // Clear any existing rotation state first
            rotationState = .empty
            rotationState.reset(with: eligibleIds, firstVerseId: "15.5")
            saveRotationState()
            // Mark as shown BEFORE returning to prevent any other code path from running
            defaults.set(true, forKey: AppConstants.UserDefaultsKeys.hasShownFirstVerse)
            defaults.synchronize() // Force immediate write
            if let verse15_5 = eligibleVerses.first(where: { $0.id == "15.5" }) {
                saveCurrentVerseId("15.5")
                // Reload widget immediately with 15.5
                WidgetCenter.shared.reloadAllTimelines()
                return verse15_5
            }
        }
        
        // Ensure rotation is initialized/valid for current eligible verses
        // This will only run if the 15.5 check above didn't trigger
        ensureRotationValid(for: eligibleIds)
        
        // CRITICAL: Atomic slot change check to prevent race conditions
        // Strategy: Read fresh state, check, and update atomically
        let currentSlotKey = slotKey(for: date)
        
        // Always read fresh from UserDefaults (never use cached values) to prevent race conditions
        // This ensures we see the latest state even if another process (app/widget) just updated it
        let savedSlotKey = defaults.string(forKey: AppConstants.UserDefaultsKeys.lastScheduledSlot) ?? ""
        
        // Handle three cases:
        // 1. First time (empty slot key) - initialize without advancing
        // 2. Slot changed - advance to next verse (with double-check to prevent race conditions)
        // 3. Same slot - no action needed
        
        if savedSlotKey.isEmpty {
            // First time initialization - set slot key to current slot WITHOUT advancing
            // The verse is already correctly set by ensureRotationValid above
            defaults.set(currentSlotKey, forKey: AppConstants.UserDefaultsKeys.lastScheduledSlot)
            defaults.synchronize()
        } else if savedSlotKey != currentSlotKey {
            // Slot changed - need to advance to next verse
            // Double-check: Re-read slot key to see if another process already advanced
            // This prevents duplicate advances when multiple processes check simultaneously
            let recheckSlotKey = defaults.string(forKey: AppConstants.UserDefaultsKeys.lastScheduledSlot) ?? ""
            
            if recheckSlotKey != currentSlotKey {
                // Slot key still shows old slot - safe to advance (no other process advanced yet)
                // Pass the new slot key to advanceRotation so it saves everything atomically
                advanceRotation(eligibleIds: eligibleIds, newSlotKey: currentSlotKey)
            } else {
                // Another process already advanced (recheckSlotKey == currentSlotKey)
                // Just continue with current rotation state - no need to advance again
            }
        }
        
        // Return the current verse
        guard let verseId = rotationState.currentVerseId else {
            // Rotation exhausted - reset and get first (shuffle all verses again)
            resetRotation(with: eligibleIds)
            guard let newId = rotationState.currentVerseId else { return nil }
            saveCurrentVerseId(newId)
            // Ensure slot key is set
            defaults.set(currentSlotKey, forKey: AppConstants.UserDefaultsKeys.lastScheduledSlot)
            defaults.synchronize()
            return eligibleVerses.first { $0.id == newId }
        }
        
        // Sync the current verse ID (only if it changed to prevent unnecessary writes)
        if currentVerseId != verseId {
            saveCurrentVerseId(verseId)
            defaults.synchronize() // Force immediate write for widget consistency
        }
        
        let finalVerse = eligibleVerses.first { $0.id == verseId }
        return finalVerse
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
    
    /// Marks a specific verse as shown by advancing the rotation to it
    /// This counts the verse as displayed - it won't show again until all verses are shown
    /// Even if the verse was already shown, manually setting it still counts as displayed
    /// - Parameters:
    ///   - verseId: The verse ID to mark as shown
    ///   - eligibleVerses: All verses that pass current filters
    func markVerseAsShown(verseId: String, from eligibleVerses: [Verse]) {
        guard !eligibleVerses.isEmpty else { return }
        
        let eligibleIds = eligibleVerses.map { $0.id }
        
        // Ensure the verse is in the eligible set
        guard eligibleIds.contains(verseId) else { return }
        
        // Ensure rotation is valid
        ensureRotationValid(for: eligibleIds)
        
        // Find the verse in the rotation
        guard let verseIndex = rotationState.shuffledVerseIds.firstIndex(of: verseId) else {
            // Verse not in rotation - reset rotation to include it
            resetRotation(with: eligibleIds)
            // Try to find it again after reset
            if let newIndex = rotationState.shuffledVerseIds.firstIndex(of: verseId) {
                // Advance to this verse (marking all verses before it as shown)
                rotationState.currentIndex = newIndex + 1
                rotationState.lastAdvancedAt = Date()
            }
            saveRotationState()
            return
        }
        
        // Always advance to this verse, even if it was already shown
        // This ensures manually setting a verse always counts as displayed
        if verseIndex >= rotationState.currentIndex {
            // Verse is in the future - advance to it (marking it and all before as shown)
            rotationState.currentIndex = verseIndex + 1
            rotationState.lastAdvancedAt = Date()
        } else {
            // Verse was already shown in the past
            // Since user manually set it, we should still count it
            // We can't go backwards, but we ensure it's tracked
            // The verse won't appear again until rotation resets anyway
            // Just update the timestamp to reflect this manual action
            rotationState.lastAdvancedAt = Date()
        }
        
        // If we've exhausted the rotation, reset it
        if rotationState.isExhausted {
            resetRotation(with: eligibleIds)
        }
        
        saveRotationState()
    }
    
    /// Resets the rotation with new verses (e.g., when filters change)
    func resetRotation(with verseIds: [String]) {
        // Check if we need to show 15.5 first after onboarding
        let hasCompletedOnboarding = defaults.bool(forKey: AppConstants.UserDefaultsKeys.hasCompletedOnboarding)
        let hasShownFirstVerse = defaults.bool(forKey: AppConstants.UserDefaultsKeys.hasShownFirstVerse)
        
        if hasCompletedOnboarding && !hasShownFirstVerse && verseIds.contains("15.5") {
            rotationState.reset(with: verseIds, firstVerseId: "15.5")
        } else {
            rotationState.reset(with: verseIds)
        }
        
        if let firstId = rotationState.currentVerseId {
            saveCurrentVerseId(firstId)
        }
        
        // CRITICAL: Always initialize slot key to current slot when resetting
        // This prevents the next getCurrentVerse call from thinking the slot changed
        // Use Date() here since resetRotation is typically called at operation start
        let currentSlot = slotKey(for: Date())
        defaults.set(currentSlot, forKey: AppConstants.UserDefaultsKeys.lastScheduledSlot)
        defaults.synchronize()
    }
    
    /// Force clears all rotation state (used after onboarding)
    func forceClearRotationState() {
        rotationState = .empty
        currentVerseId = nil
        lastScheduledSlot = ""
        defaults.removeObject(forKey: AppConstants.UserDefaultsKeys.verseRotationState)
        defaults.removeObject(forKey: AppConstants.UserDefaultsKeys.currentVerseId)
        defaults.removeObject(forKey: AppConstants.UserDefaultsKeys.lastScheduledSlot)
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
        // PRIORITY: Check if this is the first time after onboarding - prioritize 15.5
        // This must be checked BEFORE checking if rotation is empty
        let hasCompletedOnboarding = defaults.bool(forKey: AppConstants.UserDefaultsKeys.hasCompletedOnboarding)
        let hasShownFirstVerse = defaults.bool(forKey: AppConstants.UserDefaultsKeys.hasShownFirstVerse)
        
        if hasCompletedOnboarding && !hasShownFirstVerse && eligibleIds.contains("15.5") {
            // Reset with 15.5 as first - this will be handled by resetRotation
            resetRotation(with: eligibleIds)
            return
        }
        
        // Check if rotation is empty - only reset if we're past the first verse check
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
    /// - Parameter eligibleIds: The eligible verse IDs
    /// - Parameter newSlotKey: Optional slot key to save atomically with the rotation state
    private func advanceRotation(eligibleIds: [String], newSlotKey: String? = nil) {
        rotationState.advance()
        
        // If exhausted, reset with fresh shuffle
        if rotationState.isExhausted {
            resetRotation(with: eligibleIds)
        }
        
        // Atomically save rotation state, verse ID, and slot key together
        // This reduces race conditions by making the update atomic
        saveRotationState()
        
        if let verseId = rotationState.currentVerseId {
            defaults.set(verseId, forKey: AppConstants.UserDefaultsKeys.currentVerseId)
            currentVerseId = verseId
        }
        
        // If slot key provided, save it atomically with the other updates
        if let slotKey = newSlotKey {
            defaults.set(slotKey, forKey: AppConstants.UserDefaultsKeys.lastScheduledSlot)
        }
        
        // Force synchronization to make all updates visible immediately
        defaults.synchronize()
        
        // Reload widget timeline immediately when verse changes
        if rotationState.currentVerseId != nil {
            WidgetCenter.shared.reloadAllTimelines()
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




