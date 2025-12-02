//
//  VerseSchedule.swift
//  Vani
//
//  Defines how often the verse changes during the day.
//

import Foundation

/// Schedule for how often the verse changes
enum VerseSchedule: String, CaseIterable, Codable {
    case oncePerDay = "oncePerDay"
    case twicePerDay = "twicePerDay"
    
    /// User-friendly display name
    var displayName: String {
        switch self {
        case .oncePerDay:
            return "Once a Day"
        case .twicePerDay:
            return "Twice a Day"
        }
    }
    
    /// Description of the schedule behavior
    var description: String {
        switch self {
        case .oncePerDay:
            return "One verse for the entire day"
        case .twicePerDay:
            return "Morning verse (4 AM) & Evening verse (4 PM)"
        }
    }
    
    /// Number of verse slots per day
    var slotsPerDay: Int {
        switch self {
        case .oncePerDay: return 1
        case .twicePerDay: return 2
        }
    }
}

// MARK: - Schedule Time Configuration

extension VerseSchedule {
    
    /// Time slots for when verses change (hour in 24h format)
    /// Easily adjustable or could be exposed to user settings later
    struct TimeSlots {
        static let morningHour: Int = 4   // 4:00 AM
        static let eveningHour: Int = 16  // 4:00 PM
    }
    
    /// Returns the scheduled times for verse changes in a given day
    func scheduledTimes(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        switch self {
        case .oncePerDay:
            // Single entry at morning time
            return [
                calendar.date(byAdding: .hour, value: TimeSlots.morningHour, to: startOfDay)!
            ]
            
        case .twicePerDay:
            // Two entries: morning and evening
            return [
                calendar.date(byAdding: .hour, value: TimeSlots.morningHour, to: startOfDay)!,
                calendar.date(byAdding: .hour, value: TimeSlots.eveningHour, to: startOfDay)!
            ]
        }
    }
    
    /// Determines the current time slot index based on the current time
    /// For oncePerDay: always 0
    /// For twicePerDay: 0 for morning (4AM-4PM), 1 for evening (4PM-4AM)
    func currentSlotIndex(for date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        switch self {
        case .oncePerDay:
            return 0
            
        case .twicePerDay:
            // Morning slot: 4 AM to 4 PM (hours 4-15)
            // Evening slot: 4 PM to 4 AM (hours 16-23, 0-3)
            if hour >= TimeSlots.morningHour && hour < TimeSlots.eveningHour {
                return 0 // Morning
            } else {
                return 1 // Evening
            }
        }
    }
    
    /// Returns the next scheduled change time after the given date
    func nextScheduledTime(after date: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let startOfDay = calendar.startOfDay(for: date)
        
        switch self {
        case .oncePerDay:
            // Next change is tomorrow at morning hour
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return calendar.date(byAdding: .hour, value: TimeSlots.morningHour, to: tomorrow)!
            
        case .twicePerDay:
            if hour < TimeSlots.morningHour {
                // Before morning: next is today's morning
                return calendar.date(byAdding: .hour, value: TimeSlots.morningHour, to: startOfDay)!
            } else if hour < TimeSlots.eveningHour {
                // Between morning and evening: next is today's evening
                return calendar.date(byAdding: .hour, value: TimeSlots.eveningHour, to: startOfDay)!
            } else {
                // After evening: next is tomorrow's morning
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                return calendar.date(byAdding: .hour, value: TimeSlots.morningHour, to: tomorrow)!
            }
        }
    }
}




