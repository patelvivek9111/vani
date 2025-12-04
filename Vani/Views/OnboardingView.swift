//
//  OnboardingView.swift
//  Vani
//
//  Onboarding flow for new users.
//

import SwiftUI
import WidgetKit

// MARK: - Onboarding Steps

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case name
    case theme
    case notifications
    case widgets
    case complete
    
    var title: String {
        switch self {
        case .welcome: return ""
        case .name: return "What should we call you?"
        case .theme: return "Choose Your Aesthetic"
        case .notifications: return "Stay Connected"
        case .widgets: return "Wisdom at a Glance"
        case .complete: return ""
        }
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @EnvironmentObject private var settings: SettingsManager
    @State private var currentStep: OnboardingStep = .welcome
    @State private var tempName: String = ""
    @State private var tempTheme: AppTheme = .midnightGold
    @State private var enableNotifications: Bool = true
    @State private var animateIn: Bool = false
    @State private var showWidgetInstructions: Bool = false
    @State private var breathingScale: CGFloat = 1.0
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Animated background
            animatedBackground
            
            // Content
            VStack(spacing: 0) {
                // Progress indicator (hidden on welcome and complete)
                if currentStep != .welcome && currentStep != .complete {
                    progressIndicator
                        .padding(.top, 20)
                }
                
                // Main content area
                TabView(selection: $currentStep) {
                    welcomePage.tag(OnboardingStep.welcome)
                    namePage.tag(OnboardingStep.name)
                    themePage.tag(OnboardingStep.theme)
                    notificationsPage.tag(OnboardingStep.notifications)
                    widgetsPage.tag(OnboardingStep.widgets)
                    completePage.tag(OnboardingStep.complete)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: currentStep)
            }
        }
        .onAppear {
            tempTheme = settings.appTheme
            withAnimation(.easeOut(duration: 1.0)) {
                animateIn = true
            }
            // Start breathing animation after initial fade-in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                if currentStep == .welcome {
                    startBreathingAnimation()
                }
            }
        }
        .onChange(of: currentStep) { _, newStep in
            // Restart breathing animation when returning to welcome page
            if newStep == .welcome && animateIn {
                startBreathingAnimation()
            }
        }
    }
    
    // MARK: - Animated Background
    
    private var animatedBackground: some View {
        ZStack {
            // Base gradient using selected theme
            LinearGradient(
                colors: tempTheme.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Floating glow orbs
            GeometryReader { geo in
                Circle()
                    .fill(tempTheme.glowColor.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: animateIn ? -50 : -100, y: animateIn ? 100 : 50)
                    .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animateIn)
                
                Circle()
                    .fill(tempTheme.accentColor.opacity(0.1))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(x: geo.size.width - 150, y: geo.size.height - 300)
                    .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true).delay(1), value: animateIn)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1..<5, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep.rawValue ? tempTheme.accentColor : tempTheme.accentColor.opacity(0.3))
                    .frame(width: index == currentStep.rawValue ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Welcome Page
    
    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Logo/Icon - Calligraphy pen style
            VStack(spacing: 24) {
                ZStack {
                    // Ink bleed layer (outermost)
                    CalligraphyDoubleStrokeShape()
                        .fill(Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.2))
                        .frame(width: 60, height: 120)
                        .offset(x: 1.5, y: 1.5)
                        .blur(radius: 2.5)
                    
                    // Ink bleed layer (middle)
                    CalligraphyDoubleStrokeShape()
                        .fill(Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.3))
                        .frame(width: 60, height: 120)
                        .offset(x: 0.8, y: 0.8)
                        .blur(radius: 1.5)
                    
                    // Main calligraphy strokes with ink variation
                    CalligraphyDoubleStrokeShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.88, blue: 0.60), // Bright gold ink
                                    Color(red: 0.92, green: 0.78, blue: 0.45), // Medium gold
                                    Color(red: 0.88, green: 0.72, blue: 0.40), // Slightly darker
                                    Color(red: 0.85, green: 0.70, blue: 0.35), // Dark gold
                                    Color(red: 0.90, green: 0.75, blue: 0.42), // Back to medium
                                    Color(red: 0.95, green: 0.85, blue: 0.55)  // Bright again
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 120)
                        .shadow(color: Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.5), radius: 3, x: 0, y: 2)
                        .shadow(color: Color(red: 0.95, green: 0.85, blue: 0.55).opacity(0.3), radius: 5, x: 0, y: -1)
                }
                .opacity(animateIn ? 1 : 0)
                .scaleEffect(animateIn ? breathingScale : 0.8)
                .animation(.easeOut(duration: 0.8).delay(0.2), value: animateIn)
                
                VStack(spacing: 12) {
                    Text("Vāṇī")
                        .font(.system(size: 42, weight: .light, design: .serif))
                        .foregroundStyle(tempTheme.primaryTextColor)
                    
                    Text("Daily Wisdom from the Bhagavad Gita")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(tempTheme.secondaryTextColor)
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.5), value: animateIn)
            }
            
            Spacer()
            
            // Sanskrit blessing - Calligraphy pen style
            VStack(spacing: 16) {
                // Sanskrit text with ink pen effect
                ZStack {
                    // Ink bleed/shadow layer
                    Text("ॐ श्री कृष्णाय नमः")
                        .font(.system(size: 22, weight: .medium, design: .serif))
                        .italic()
                        .foregroundStyle(tempTheme.accentColor.opacity(0.25))
                        .offset(x: 1, y: 1)
                        .blur(radius: 0.5)
                    
                    // Main text with gradient (simulating ink flow)
                    Text("ॐ श्री कृष्णाय नमः")
                        .font(.system(size: 22, weight: .medium, design: .serif))
                        .italic()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    tempTheme.accentColor.opacity(0.98),
                                    tempTheme.accentColor.opacity(0.92),
                                    tempTheme.accentColor.opacity(0.88),
                                    tempTheme.accentColor.opacity(0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: tempTheme.accentColor.opacity(0.4), radius: 1, x: 0, y: 0.5)
                }
                
                // English text with ink pen effect
                ZStack {
                    // Ink bleed/shadow layer
                    Text("Begin your journey with divine wisdom")
                        .font(.system(size: 15, weight: .light, design: .serif))
                        .italic()
                        .foregroundStyle(tempTheme.secondaryTextColor.opacity(0.2))
                        .offset(x: 0.5, y: 0.5)
                        .blur(radius: 0.3)
                    
                    // Main text with gradient (simulating ink flow)
                    Text("Begin your journey with divine wisdom")
                        .font(.system(size: 15, weight: .light, design: .serif))
                        .italic()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    tempTheme.secondaryTextColor.opacity(0.95),
                                    tempTheme.secondaryTextColor.opacity(0.85),
                                    tempTheme.secondaryTextColor.opacity(0.75)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: tempTheme.secondaryTextColor.opacity(0.25), radius: 1, x: 0, y: 0.3)
                }
            }
            .opacity(animateIn ? 1 : 0)
            .animation(.easeOut(duration: 0.8).delay(0.8), value: animateIn)
            
            Spacer()
            
            // Continue button
            Button(action: { goToStep(.name) }) {
                Text("Begin")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tempTheme.isLightTheme ? .white : tempTheme.backgroundColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: tempTheme.buttonGradient, startPoint: .leading, endPoint: .trailing))
                    )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
            .opacity(animateIn ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(1.2), value: animateIn)
        }
    }
    
    // MARK: - Name Page
    
    private var namePage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: "person.circle")
                .font(.system(size: 60, weight: .thin))
                .foregroundStyle(tempTheme.accentColor)
            
            VStack(spacing: 12) {
                Text("What should we call you?")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundStyle(tempTheme.primaryTextColor)
                    .multilineTextAlignment(.center)
                
                Text("Enter your first name to personalize your spiritual journey")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(tempTheme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
            
            // Name input
            TextField("First name", text: $tempName)
                .font(.system(size: 20, weight: .regular, design: .serif))
                .foregroundStyle(tempTheme.primaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(tempTheme.buttonBackgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(tempTheme.accentColor.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Navigation buttons
            navigationButtons(
                backAction: { goToStep(.welcome) },
                nextAction: {
                    settings.userName = tempName
                    goToStep(.theme)
                },
                nextText: "Continue"
            )
        }
    }
    
    // MARK: - Theme Page
    
    private var themePage: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 20)
            
            VStack(spacing: 12) {
                Text("Choose Your Aesthetic")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundStyle(tempTheme.primaryTextColor)
                
                Text("You can change this anytime in settings")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(tempTheme.secondaryTextColor)
            }
            
            // Theme grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(AppTheme.allCases) { theme in
                        OnboardingThemeCard(
                            theme: theme,
                            isSelected: tempTheme == theme,
                            onSelect: {
                                withAnimation(.spring(response: 0.3)) {
                                    tempTheme = theme
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Navigation buttons
            navigationButtons(
                backAction: { goToStep(.name) },
                nextAction: {
                    settings.appTheme = tempTheme
                    goToStep(.notifications)
                },
                nextText: "Continue"
            )
        }
    }
    
    // MARK: - Notifications Page
    
    private var notificationsPage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: "bell.badge")
                .font(.system(size: 60, weight: .thin))
                .foregroundStyle(tempTheme.accentColor)
            
            VStack(spacing: 12) {
                Text("Stay Connected")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundStyle(tempTheme.primaryTextColor)
                
                Text("Receive gentle reminders with daily wisdom from Lord Krishna")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(tempTheme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Notification options
            VStack(spacing: 16) {
                notificationOption(
                    icon: "sunrise.fill",
                    title: "Daily Verse",
                    subtitle: "Start your day with wisdom",
                    isSelected: enableNotifications,
                    action: { enableNotifications.toggle() }
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Navigation buttons
            navigationButtons(
                backAction: { goToStep(.theme) },
                nextAction: {
                    if enableNotifications {
                        settings.verseNotificationsEnabled = true
                        NotificationManager.shared.requestPermission { _ in }
                    }
                    goToStep(.widgets)
                },
                nextText: "Continue"
            )
        }
    }
    
    // MARK: - Widgets Page
    
    private var widgetsPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            Image(systemName: "rectangle.on.rectangle")
                .font(.system(size: 60, weight: .thin))
                .foregroundStyle(tempTheme.accentColor)
            
            VStack(spacing: 12) {
                Text("Wisdom at a Glance")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundStyle(tempTheme.primaryTextColor)
                
                Text("Add Vāṇī widgets to your home screen for instant access to divine wisdom")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(tempTheme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Widget preview and configuration
            VStack(spacing: 20) {
                // Medium widget preview
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: tempTheme.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 100)
                    .overlay(
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kṛṣṇa Vāṇī")
                                .font(.system(size: 12, weight: .medium, design: .serif))
                                .foregroundStyle(tempTheme.accentColor)
                            Text("Focus on action, not results...")
                                .font(.system(size: 14, weight: .light))
                                .foregroundStyle(tempTheme.primaryTextColor)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                
                // Add Widget Button
                Button(action: {
                    WidgetHelper.reloadAllTimelines()
                    showWidgetInstructions = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Add Widget to Home Screen")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(tempTheme.isLightTheme ? .white : tempTheme.backgroundColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: tempTheme.buttonGradient, startPoint: .leading, endPoint: .trailing))
                            .shadow(color: tempTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
                .padding(.horizontal, 20)
                
                // Alternative instructions
                Text("Or: Long press home screen → Tap + → Search \"Vāṇī\"")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(tempTheme.secondaryTextColor.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Navigation buttons
            navigationButtons(
                backAction: { goToStep(.notifications) },
                nextAction: { goToStep(.complete) },
                nextText: "Almost Done"
            )
        }
        .alert("Add Widget", isPresented: $showWidgetInstructions) {
            Button("Got it") {
                // Alert will automatically dismiss when button is tapped
            }
        } message: {
            Text("1. Press the Home button or swipe up\n2. Long press on an empty area\n3. Tap the + button in the top corner\n4. Search for \"Vāṇī\"\n5. Select a widget size and tap \"Add Widget\"")
        }
    }
    
    // MARK: - Complete Page
    
    private var completePage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success icon
            ZStack {
                Circle()
                    .fill(tempTheme.accentColor.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(tempTheme.accentColor)
            }
            
            VStack(spacing: 16) {
                if !tempName.isEmpty {
                    Text("Welcome, \(tempName)!")
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundStyle(tempTheme.primaryTextColor)
                } else {
                    Text("You're All Set!")
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundStyle(tempTheme.primaryTextColor)
                }
                
                Text("Your journey with Krishna's wisdom begins now")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(tempTheme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
            
            // Sanskrit blessing
            Text("ॐ नमो भगवते वासुदेवाय नमः")
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundStyle(tempTheme.accentColor.opacity(0.8))
            
            Spacer()
            
            // Begin button
            Button(action: completeOnboarding) {
                HStack(spacing: 12) {
                    Text("Begin Your Journey")
                        .font(.system(size: 18, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(tempTheme.isLightTheme ? .white : tempTheme.backgroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(LinearGradient(colors: tempTheme.buttonGradient, startPoint: .leading, endPoint: .trailing))
                )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - Helper Views
    
    private func notificationOption(
        icon: String,
        title: String,
        subtitle: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(tempTheme.accentColor)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(tempTheme.buttonBackgroundColor))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(tempTheme.primaryTextColor)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(tempTheme.secondaryTextColor)
                }
                
                Spacer()
                
                // Toggle indicator - improved visibility
                ZStack {
                    // Track background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? tempTheme.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 52, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(isSelected ? Color.clear : Color.gray.opacity(0.4), lineWidth: 1)
                        )
                    
                    // Thumb with shadow
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                        .offset(x: isSelected ? 11 : -11)
                        .animation(.spring(response: 0.3), value: isSelected)
                    
                    // ON/OFF indicator
                    HStack {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.leading, 8)
                        }
                        Spacer()
                        if !isSelected {
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 6, height: 6)
                                .padding(.trailing, 10)
                        }
                    }
                    .frame(width: 52)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(tempTheme.buttonBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(isSelected ? tempTheme.accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func navigationButtons(
        backAction: @escaping () -> Void,
        nextAction: @escaping () -> Void,
        nextText: String,
        showSkip: Bool = false,
        skipAction: (() -> Void)? = nil
    ) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                // Back button - more premium look
                Button(action: backAction) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tempTheme.primaryTextColor.opacity(0.8))
                        .frame(width: 54, height: 54)
                        .background(
                            Circle()
                                .fill(tempTheme.buttonBackgroundColor)
                                .overlay(
                                    Circle()
                                        .strokeBorder(tempTheme.accentColor.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                
                // Continue button - gradient with icon
                Button(action: nextAction) {
                    HStack(spacing: 8) {
                        Text(nextText)
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(tempTheme.isLightTheme ? .white : tempTheme.backgroundColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: tempTheme.buttonGradient, startPoint: .leading, endPoint: .trailing))
                            .shadow(color: tempTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
            }
            
            // Skip button removed per user request
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    // MARK: - Actions
    
    private func goToStep(_ step: OnboardingStep) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = step
        }
    }
    
    private func startBreathingAnimation() {
        // Gentle breathing effect - subtle scale pulse (meditative rhythm)
        // Start from 1.0, pulse to 1.02, then back
        breathingScale = 1.0
        
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
            breathingScale = 1.02 // Very subtle - only 2% larger
        }
    }
    
    private func completeOnboarding() {
        settings.hasCompletedOnboarding = true
        // Clear rotation state and flags so 15.5 shows first
        if let defaults = AppConstants.sharedUserDefaults {
            settings.hasShownFirstVerse = false
            defaults.removeObject(forKey: AppConstants.UserDefaultsKeys.currentVerseId)
            defaults.removeObject(forKey: AppConstants.UserDefaultsKeys.verseRotationState)
            defaults.removeObject(forKey: AppConstants.UserDefaultsKeys.lastScheduledSlot)
        }
        // Reset rotation manager
        VerseRotationManager.shared.resetRotation(with: [])
        onComplete()
    }
}

// MARK: - Calligraphy Double Stroke Shape

struct CalligraphyDoubleStrokeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let strokeWidth: CGFloat = width * 0.25 // Base stroke width
        let taperLength: CGFloat = height * 0.15 // Length of tapered ends
        
        // Left stroke
        let leftCenterX = width * 0.25
        
        // Top taper (pointed end)
        path.move(to: CGPoint(x: leftCenterX, y: 0))
        path.addLine(to: CGPoint(x: leftCenterX - strokeWidth * 0.5, y: taperLength))
        path.addLine(to: CGPoint(x: leftCenterX + strokeWidth * 0.5, y: taperLength))
        path.closeSubpath()
        
        // Middle section (thicker)
        path.move(to: CGPoint(x: leftCenterX - strokeWidth * 0.5, y: taperLength))
        path.addLine(to: CGPoint(x: leftCenterX - strokeWidth * 0.5, y: height - taperLength))
        path.addLine(to: CGPoint(x: leftCenterX + strokeWidth * 0.5, y: height - taperLength))
        path.addLine(to: CGPoint(x: leftCenterX + strokeWidth * 0.5, y: taperLength))
        path.closeSubpath()
        
        // Bottom taper (pointed end)
        path.move(to: CGPoint(x: leftCenterX, y: height))
        path.addLine(to: CGPoint(x: leftCenterX - strokeWidth * 0.5, y: height - taperLength))
        path.addLine(to: CGPoint(x: leftCenterX + strokeWidth * 0.5, y: height - taperLength))
        path.closeSubpath()
        
        // Right stroke
        let rightCenterX = width * 0.75
        
        // Top taper (pointed end)
        path.move(to: CGPoint(x: rightCenterX, y: 0))
        path.addLine(to: CGPoint(x: rightCenterX - strokeWidth * 0.5, y: taperLength))
        path.addLine(to: CGPoint(x: rightCenterX + strokeWidth * 0.5, y: taperLength))
        path.closeSubpath()
        
        // Middle section (thicker)
        path.move(to: CGPoint(x: rightCenterX - strokeWidth * 0.5, y: taperLength))
        path.addLine(to: CGPoint(x: rightCenterX - strokeWidth * 0.5, y: height - taperLength))
        path.addLine(to: CGPoint(x: rightCenterX + strokeWidth * 0.5, y: height - taperLength))
        path.addLine(to: CGPoint(x: rightCenterX + strokeWidth * 0.5, y: taperLength))
        path.closeSubpath()
        
        // Bottom taper (pointed end)
        path.move(to: CGPoint(x: rightCenterX, y: height))
        path.addLine(to: CGPoint(x: rightCenterX - strokeWidth * 0.5, y: height - taperLength))
        path.addLine(to: CGPoint(x: rightCenterX + strokeWidth * 0.5, y: height - taperLength))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Onboarding Theme Card

struct OnboardingThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // Theme preview
                ZStack {
                    LinearGradient(colors: theme.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    
                    Circle()
                        .fill(theme.glowColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .blur(radius: 20)
                    
                    Text("ॐ")
                        .font(.system(size: 24, weight: .light, design: .serif))
                        .foregroundStyle(theme.accentColor)
                }
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(isSelected ? theme.accentColor : Color.clear, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                
                // Theme name
                Text(theme.displayName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? theme.accentColor : .secondary)
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView {
        print("Onboarding complete")
    }
    .environmentObject(SettingsManager.shared)
}




