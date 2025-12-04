//
//  VaniApp.swift
//  Vani
//
//  Main app entry point with environment setup.
//

import SwiftUI
import WidgetKit

@main
struct VaniApp: App {
    
    /// Shared settings manager for the entire app
    @StateObject private var settingsManager = SettingsManager.shared
    
    /// Navigation coordinator for deep links
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    
    /// Repository for loading Gita data
    private let repository = BundleGitaRepository()
    
    /// Track if splash screen is showing (for returning users)
    @State private var showSplash = false
    
    /// Track if onboarding should show
    @State private var showOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app content (only shown after splash/onboarding)
                if settingsManager.hasCompletedOnboarding && !showOnboarding && !showSplash {
                    ContentView()
                        .environmentObject(settingsManager)
                        .environmentObject(navigationCoordinator)
                        .environment(\.gitaRepository, repository)
                        .onOpenURL { url in
                            // When widget is tapped, show full verse
                            if url.scheme == "vani" && url.host == "showverse" {
                                navigationCoordinator.showFullVerse()
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                            // Refresh widget when app goes to background
                            WidgetHelper.reloadAllTimelines()
                        }
                        .onAppear {
                            // Schedule notifications based on saved settings
                            setupNotifications()
                        }
                }
                
                // Premium splash screen for returning users
                if settingsManager.hasCompletedOnboarding && showSplash {
                    SplashView {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showSplash = false
                        }
                    }
                    .environmentObject(settingsManager)
                    .transition(.opacity)
                    .zIndex(3)
                }
                
                // Onboarding flow for new users
                if !settingsManager.hasCompletedOnboarding || showOnboarding {
                    OnboardingView {
                        withAnimation(.easeOut(duration: 0.5)) {
                            showOnboarding = false
                        }
                    }
                    .environmentObject(settingsManager)
                    .transition(.opacity)
                    .zIndex(2)
                }
            }
            .onAppear {
                // Show splash for returning users, onboarding for new users
                if settingsManager.hasCompletedOnboarding {
                    showSplash = true
                } else {
                    showOnboarding = true
                }
            }
        }
    }
    
    /// Setup notifications on app launch
    private func setupNotifications() {
        // Update notifications with current settings
        NotificationManager.shared.updateNotifications(
            verseSchedule: settingsManager.verseSchedule,
            verseNotificationsEnabled: settingsManager.verseNotificationsEnabled,
            mindfulnessFrequency: settingsManager.mindfulnessFrequency
        )
    }
}

// MARK: - Navigation Coordinator

class NavigationCoordinator: ObservableObject {
    @Published var shouldShowFullVerse: Bool = false
    
    func showFullVerse() {
        shouldShowFullVerse = true
    }
    
    func dismiss() {
        shouldShowFullVerse = false
    }
}

// MARK: - Environment Keys

/// Environment key for Gita repository
private struct GitaRepositoryKey: EnvironmentKey {
    static let defaultValue: GitaRepositoryProtocol = BundleGitaRepository()
}

extension EnvironmentValues {
    var gitaRepository: GitaRepositoryProtocol {
        get { self[GitaRepositoryKey.self] }
        set { self[GitaRepositoryKey.self] = newValue }
    }
}
