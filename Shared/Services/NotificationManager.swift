//
//  NotificationManager.swift
//  Vani
//
//  Manages local notifications for verse updates and mindfulness reminders.
//

import Foundation
import UserNotifications

/// Frequency options for mindfulness reminders
enum MindfulnessFrequency: String, CaseIterable, Codable {
    case off = "off"
    case onceDaily = "1x"
    case twiceDaily = "2x"
    case thriceDaily = "3x"
    
    var displayName: String {
        switch self {
        case .off: return "Off"
        case .onceDaily: return "Once Daily"
        case .twiceDaily: return "Twice Daily"
        case .thriceDaily: return "Three Times Daily"
        }
    }
    
    var description: String {
        switch self {
        case .off: return "No reminders"
        case .onceDaily: return "One gentle reminder per day"
        case .twiceDaily: return "Morning and evening reminders"
        case .thriceDaily: return "Morning, afternoon, and evening"
        }
    }
    
    /// Hours for reminders (24h format)
    var reminderHours: [Int] {
        switch self {
        case .off: return []
        case .onceDaily: return [12]  // Noon
        case .twiceDaily: return [9, 18]  // 9 AM, 6 PM
        case .thriceDaily: return [9, 14, 19]  // 9 AM, 2 PM, 7 PM
        }
    }
}

/// Manages local notifications for the app
final class NotificationManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = NotificationManager()
    
    // MARK: - Constants
    
    private enum NotificationIdentifiers {
        static let versePrefix = "verse_notification_"
        static let mindfulnessPrefix = "mindfulness_notification_"
    }
    
    private enum NotificationContent {
        static let verseTitle = "Kṛṣṇa Vāṇī"
        static let verseBody = "Your new verse is ready."
        
        static let mindfulnessTitle = "Kṛṣṇa Vāṇī"
        static let mindfulnessBody = "Take a moment to reflect on today's wisdom."
    }
    
    // MARK: - Properties
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Permission
    
    /// Requests notification permission from the user
    func requestPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    /// Checks if notifications are authorized
    func checkPermissionStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    // MARK: - Schedule Verse Notifications
    
    /// Schedules verse notifications based on the user's schedule preference
    func scheduleVerseNotifications(schedule: VerseSchedule, enabled: Bool) {
        // Remove existing verse notifications first
        removeVerseNotifications()
        
        guard enabled else { return }
        
        let times = getNotificationTimes(for: schedule)
        
        for (index, hour) in times.enumerated() {
            let identifier = "\(NotificationIdentifiers.versePrefix)\(index)"
            scheduleDaily(
                identifier: identifier,
                title: NotificationContent.verseTitle,
                body: NotificationContent.verseBody,
                hour: hour,
                minute: 0
            )
        }
    }
    
    /// Gets the notification times based on schedule
    private func getNotificationTimes(for schedule: VerseSchedule) -> [Int] {
        switch schedule {
        case .oncePerDay:
            return [VerseSchedule.TimeSlots.morningHour]  // 4 AM
        case .twicePerDay:
            return [
                VerseSchedule.TimeSlots.morningHour,  // 4 AM
                VerseSchedule.TimeSlots.eveningHour   // 4 PM
            ]
        }
    }
    
    /// Removes all verse notifications
    func removeVerseNotifications() {
        let identifiers = (0..<5).map { "\(NotificationIdentifiers.versePrefix)\($0)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // MARK: - Schedule Mindfulness Reminders
    
    /// Schedules mindfulness reminder notifications
    func scheduleMindfulnessReminders(frequency: MindfulnessFrequency) {
        // Remove existing mindfulness notifications first
        removeMindfulnessReminders()
        
        guard frequency != .off else { return }
        
        for (index, hour) in frequency.reminderHours.enumerated() {
            let identifier = "\(NotificationIdentifiers.mindfulnessPrefix)\(index)"
            scheduleDaily(
                identifier: identifier,
                title: NotificationContent.mindfulnessTitle,
                body: NotificationContent.mindfulnessBody,
                hour: hour,
                minute: 0
            )
        }
    }
    
    /// Removes all mindfulness notifications
    func removeMindfulnessReminders() {
        let identifiers = (0..<5).map { "\(NotificationIdentifiers.mindfulnessPrefix)\($0)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // MARK: - Private Helpers
    
    /// Schedules a daily repeating notification
    private func scheduleDaily(identifier: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Utility
    
    /// Removes all app notifications
    func removeAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    /// Updates all notifications based on current settings
    func updateNotifications(
        verseSchedule: VerseSchedule,
        verseNotificationsEnabled: Bool,
        mindfulnessFrequency: MindfulnessFrequency
    ) {
        scheduleVerseNotifications(schedule: verseSchedule, enabled: verseNotificationsEnabled)
        scheduleMindfulnessReminders(frequency: mindfulnessFrequency)
    }
}




