//
//  SettingsView.swift
//  Vani
//
//  Settings screen for user preferences.
//

import SwiftUI
import WidgetKit

struct SettingsView: View {
    
    @EnvironmentObject private var settings: SettingsManager
    @Environment(\.gitaRepository) private var repository
    
    @State private var showingResetAlert = false
    @State private var sampleVerse: Verse?
    
    private var theme: AppTheme { settings.appTheme }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Themed background
                theme.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Account Section (at the top)
                        accountSection
                        
                        // Widget Settings Section (Navigation Link)
                        widgetSettingsSection
                        
                        // Personalization Section
                        personalizationSection
                        
                        // Verse Schedule Section
                        verseScheduleSection
                        
                        // Notifications Section
                        notificationsSection
                        
                        // About Section
                        aboutSection
                        
                        // Reset Section
                        resetSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Settings")
            .toolbarBackground(theme.backgroundColor, for: .navigationBar)
            .toolbarColorScheme(theme.isLightTheme ? .light : .dark, for: .navigationBar)
            .onAppear {
                loadSampleVerse()
            }
            .onChange(of: settings.mediumWidgetMode) { _, _ in refreshWidgets() }
            .onChange(of: settings.largeWidgetTop) { _, _ in refreshWidgets() }
            .onChange(of: settings.largeWidgetBottom) { _, _ in refreshWidgets() }
            .alert("Reset Settings", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    settings.resetToDefaults()
                }
            } message: {
                Text("This will reset all settings to their default values.")
            }
        }
    }
    
    // MARK: - Verse Schedule Section
    
    private var verseScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(theme.accentColor)
                Text("Verse Schedule")
                    .font(.headline)
                    .foregroundStyle(theme.primaryTextColor)
            }
            .padding(.horizontal, 4)
            
            // Schedule Options
            VStack(spacing: 0) {
                ForEach(VerseSchedule.allCases, id: \.rawValue) { schedule in
                    ThemedOptionRow(
                        title: schedule.displayName,
                        subtitle: schedule.description,
                        isSelected: settings.verseSchedule == schedule,
                        theme: theme
                    ) {
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            settings.verseSchedule = schedule
                            refreshWidgets()
                        }
                    }
                    
                    if schedule != VerseSchedule.allCases.last {
                        Divider()
                            .background(theme.secondaryTextColor.opacity(0.3))
                            .padding(.leading, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.buttonBackgroundColor)
            )
            
            Text("Each verse is shown once before any verse repeats")
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
                .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "bell.fill")
                    .foregroundStyle(theme.accentColor)
                Text("Notifications")
                    .font(.headline)
                    .foregroundStyle(theme.primaryTextColor)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // Verse Notifications Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("New Verse Alerts")
                            .font(.system(size: 16, weight: .medium, design: theme.fontDesign))
                            .foregroundStyle(theme.primaryTextColor)
                        Text("Get notified when your verse changes")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $settings.verseNotificationsEnabled)
                        .labelsHidden()
                        .tint(theme.accentColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .onChange(of: settings.verseNotificationsEnabled) { _, newValue in
                    if newValue {
                        requestNotificationPermission()
                    }
                }
                
                Divider()
                    .background(theme.secondaryTextColor.opacity(0.3))
                    .padding(.leading, 16)
                
                // Mindfulness Reminders
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mindfulness Reminders")
                                .font(.system(size: 16, weight: .medium, design: theme.fontDesign))
                                .foregroundStyle(theme.primaryTextColor)
                            Text("Gentle reminders to reflect")
                                .font(.caption)
                                .foregroundStyle(theme.secondaryTextColor)
                        }
                        
                        Spacer()
                    }
                    
                    // Frequency Options
                    HStack(spacing: 8) {
                        ForEach(MindfulnessFrequency.allCases, id: \.rawValue) { frequency in
                            Button {
                                if frequency != .off {
                                    requestNotificationPermission()
                                }
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                                
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    settings.mindfulnessFrequency = frequency
                                }
                            } label: {
                                Text(frequency.displayName)
                                    .font(.system(size: 13, weight: settings.mindfulnessFrequency == frequency ? .semibold : .regular))
                                    .foregroundStyle(
                                        settings.mindfulnessFrequency == frequency
                                            ? (theme.isLightTheme ? .white : theme.backgroundColor)
                                            : theme.primaryTextColor
                                    )
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(settings.mindfulnessFrequency == frequency
                                                  ? theme.accentColor
                                                  : theme.secondaryTextColor.opacity(0.15))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.buttonBackgroundColor)
            )
            
            Text("Notifications require permission from your device")
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
                .padding(.horizontal, 4)
        }
    }
    
    /// Request notification permission
    private func requestNotificationPermission() {
        NotificationManager.shared.requestPermission { granted in
            if !granted {
                // Could show an alert here if permission denied
            }
        }
    }
    
    // MARK: - Personalization Section
    
    private var personalizationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .foregroundStyle(theme.accentColor)
                Text("Personalization")
                    .font(.headline)
                    .foregroundStyle(theme.primaryTextColor)
            }
            .padding(.horizontal, 4)
            
            // Personalization Toggle
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Personalized Verses")
                        .font(.system(size: 16, weight: .medium, design: theme.fontDesign))
                        .foregroundStyle(theme.primaryTextColor)
                    
                    if !settings.userName.isEmpty {
                        Text("Verses will address you as \(settings.userName)")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryTextColor)
                    } else {
                        Text("Set your name in onboarding to enable")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { settings.personalizationEnabled && !settings.userName.isEmpty },
                    set: { newValue in
                        settings.personalizationEnabled = newValue
                        // If disabling personalization and currently in personalized mode, switch to translation
                        if !newValue && settings.homeDisplayMode == .personalized {
                            settings.homeDisplayMode = .translation
                        }
                    }
                ))
                .disabled(settings.userName.isEmpty)
                .tint(theme.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.buttonBackgroundColor)
            )
            
            Text("When enabled, verses that address Arjuna will use your name instead")
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
                .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Widget Settings Section
    
    private var widgetSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "rectangle.on.rectangle")
                    .foregroundStyle(theme.accentColor)
                Text("Widget Settings")
                    .font(.headline)
                    .foregroundStyle(theme.primaryTextColor)
            }
            .padding(.horizontal, 4)
            
            NavigationLink {
                DisplayModeView(sampleVerse: sampleVerse)
                    .environmentObject(settings)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Display Mode")
                            .font(.system(size: 16, weight: .medium, design: theme.fontDesign))
                            .foregroundStyle(theme.primaryTextColor)
                        
                        Text("Home: \(settings.homeDisplayMode.displayName) · Widgets: \(settings.mediumWidgetMode.displayName)")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryTextColor)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.secondaryTextColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.buttonBackgroundColor)
                )
            }
            .buttonStyle(.plain)
            
            Text("Customize what content appears on home screen and widgets")
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
                .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundStyle(theme.accentColor)
                Text("Account")
                    .font(.headline)
                    .foregroundStyle(theme.primaryTextColor)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // Name Field
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name")
                            .font(.system(size: 16, weight: .medium, design: theme.fontDesign))
                            .foregroundStyle(theme.primaryTextColor)
                        Text("Used for personalized verses")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    TextField("Your name", text: $settings.userName)
                        .font(.system(size: 16, design: theme.fontDesign))
                        .foregroundStyle(theme.primaryTextColor)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 150)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.buttonBackgroundColor)
            )
            
            Text("Your name will be used in personalized verses when enabled")
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
                .padding(.horizontal, 4)
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundStyle(theme.accentColor)
                Text("About")
                    .font(.headline)
                    .foregroundStyle(theme.primaryTextColor)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                HStack {
                    Text("App Version")
                        .foregroundStyle(theme.primaryTextColor)
                    Spacer()
                    Text("1.0")
                        .foregroundStyle(theme.secondaryTextColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .background(theme.secondaryTextColor.opacity(0.3))
                    .padding(.leading, 16)
                
                Link(destination: URL(string: "https://www.holy-bhagavad-gita.org")!) {
                    HStack {
                        Text("Learn More About the Gita")
                            .foregroundStyle(theme.primaryTextColor)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(theme.accentColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.buttonBackgroundColor)
            )
        }
    }
    
    // MARK: - Reset Section
    
    private var resetSection: some View {
        Button {
            showingResetAlert = true
        } label: {
            Text("Reset All Settings")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                )
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadSampleVerse() {
        do {
            let data = try repository.loadData()
            let krishnaVerses = repository.getKrishnaVerses(from: data)
            
            // Use current verse from settings, or first verse as fallback
            if let verse = VerseSelector.findVerse(byId: settings.currentVerseId, from: krishnaVerses) {
                sampleVerse = verse
            } else {
                sampleVerse = krishnaVerses.first
            }
        } catch {
            sampleVerse = nil
        }
    }
    
    private func refreshWidgets() {
        WidgetHelper.reloadAllTimelines()
    }
}

// MARK: - Themed Option Row

struct ThemedOptionRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let theme: AppTheme
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium, design: theme.fontDesign))
                        .foregroundStyle(theme.primaryTextColor)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(theme.secondaryTextColor)
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? theme.accentColor : theme.secondaryTextColor.opacity(0.5), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Circle()
                            .fill(theme.accentColor)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? theme.accentColor.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Themed Medium Widget Preview

struct ThemedMediumWidgetPreview: View {
    let mode: MediumWidgetMode
    let verse: Verse?
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Kṛṣṇa Vāṇī")
                    .font(.system(size: 14, weight: .medium, design: theme.fontDesign))
                    .foregroundStyle(theme.accentColor)
                
                Text("•")
                    .foregroundStyle(theme.accentColor.opacity(0.5))
                
                Text(mode.displayName)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.secondaryTextColor)
                
                Spacer()
                
                Text("BG \(verse?.id ?? "2.47")")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(theme.isLightTheme ? .white : theme.backgroundColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(theme.accentColor))
            }
            
            Spacer(minLength: 4)
            
            // Content
            previewContent
                .frame(maxHeight: .infinity, alignment: .top)
            
            Spacer(minLength: 4)
        }
        .padding(14)
        .frame(height: 130)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: theme.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        )
    }
    
    @ViewBuilder
    private var previewContent: some View {
        switch mode {
        case .sanskrit:
            Text(verse?.sanskrit ?? "कर्मण्येवाधिकारस्ते मा फलेषु कदाचन।")
                .font(.system(size: 12, design: theme.fontDesign))
                .foregroundStyle(theme.sanskritTextColor)
                .lineSpacing(2)
                .minimumScaleFactor(0.7)
        case .transliteration:
            Text(verse?.transliteration ?? "karmaṇy evādhikāras te mā phaleṣu kadācana")
                .font(.system(size: 11, design: theme.fontDesign))
                .italic()
                .foregroundStyle(theme.primaryTextColor)
                .lineSpacing(2)
                .minimumScaleFactor(0.7)
        case .essence:
            Text(verse?.widgetLine ?? "You have the right to action, but never to its fruits.")
                .font(.system(size: 12, weight: theme.bodyFontWeight, design: theme.fontDesign))
                .foregroundStyle(theme.primaryTextColor)
                .lineSpacing(2)
                .minimumScaleFactor(0.75)
        }
    }
}

// MARK: - Themed Large Widget Preview

struct ThemedLargeWidgetPreview: View {
    let topMode: LargeWidgetTop
    let bottomMode: LargeWidgetBottom
    let verse: Verse?
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Kṛṣṇa Vāṇī")
                        .font(.system(size: 16, weight: theme.titleFontWeight, design: theme.fontDesign))
                        .foregroundStyle(theme.accentColor)
                    Text("Daily Wisdom")
                        .font(.system(size: 8))
                        .foregroundStyle(theme.secondaryTextColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 1) {
                    Text("Bhagavad Gita")
                        .font(.system(size: 8))
                        .foregroundStyle(theme.secondaryTextColor)
                    Text(verse?.id ?? "2.47")
                        .font(.system(size: 14, weight: .semibold, design: theme.fontDesign))
                        .foregroundStyle(theme.accentColor)
                }
            }
            .padding(.bottom, 8)
            
            Divider()
                .background(theme.accentColor.opacity(0.3))
                .padding(.bottom, 10)
            
            // First section
            VStack(alignment: .leading, spacing: 3) {
                Text(topMode.displayName.uppercased())
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(theme.accentColor.opacity(0.8))
                
                topContent
            }
            
            Spacer(minLength: 6)
            
            Rectangle()
                .fill(theme.accentColor.opacity(0.15))
                .frame(height: 1)
                .padding(.vertical, 4)
            
            Spacer(minLength: 4)
            
            // Second section
            VStack(alignment: .leading, spacing: 3) {
                Text(bottomMode.displayName.uppercased())
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(theme.accentColor.opacity(0.8))
                
                bottomContent
            }
            
            Spacer(minLength: 6)
            
            // Concepts
            HStack(spacing: 4) {
                ForEach(verse?.keyConcepts.prefix(2) ?? ["Karma Yoga", "Duty"], id: \.self) { tag in
                    Text(tag.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(theme.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(theme.accentColor.opacity(0.15)))
                }
                Spacer()
            }
        }
        .padding(14)
        .frame(height: 220)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: theme.gradientColors, startPoint: .top, endPoint: .bottom))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        )
    }
    
    @ViewBuilder
    private var topContent: some View {
        switch topMode {
        case .sanskrit:
            Text(verse?.sanskrit ?? "कर्मण्येवाधिकारस्ते मा फलेषु कदाचन।")
                .font(.system(size: 11, design: theme.fontDesign))
                .foregroundStyle(theme.sanskritTextColor)
                .lineSpacing(2)
                .lineLimit(3)
                .minimumScaleFactor(0.6)
        case .transliteration:
            Text(verse?.transliteration ?? "karmaṇy evādhikāras te mā phaleṣu kadācana")
                .font(.system(size: 10, design: theme.fontDesign))
                .italic()
                .foregroundStyle(theme.primaryTextColor)
                .lineSpacing(2)
                .lineLimit(3)
                .minimumScaleFactor(0.6)
        }
    }
    
    @ViewBuilder
    private var bottomContent: some View {
        switch bottomMode {
        case .translation:
            Text(verse?.translationFull ?? "You have a right to perform your prescribed duties, but you are not entitled to the fruits of your actions.")
                .font(.system(size: 10, weight: theme.bodyFontWeight, design: theme.fontDesign))
                .foregroundStyle(theme.primaryTextColor)
                .lineSpacing(2)
                .lineLimit(3)
                .minimumScaleFactor(0.6)
        case .essence:
            Text(verse?.widgetLine ?? "You have the right to action, but never to its fruits.")
                .font(.system(size: 11, weight: theme.bodyFontWeight, design: theme.fontDesign))
                .foregroundStyle(theme.primaryTextColor)
                .lineSpacing(2)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
    }
}

// MARK: - Themed Concept Tags View

struct ThemedConceptTagsView: View {
    let concepts: [String]
    let selectedConcepts: Set<String>
    let theme: AppTheme
    let onToggle: (String) -> Void
    
    var body: some View {
        FlowLayoutView(spacing: 8) {
            ForEach(concepts, id: \.self) { concept in
                let isSelected = selectedConcepts.contains(concept)
                
                Button {
                    onToggle(concept)
                } label: {
                    Text(concept.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .regular, design: theme.fontDesign))
                        .foregroundStyle(isSelected ? (theme.isLightTheme ? .white : theme.backgroundColor) : theme.primaryTextColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? theme.accentColor : theme.secondaryTextColor.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowLayoutView<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        _FlowLayout(spacing: spacing) {
            content()
        }
    }
}

struct _FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }
        
        return (CGSize(width: maxX, height: y + rowHeight), frames)
    }
}

// MARK: - Display Mode View

struct DisplayModeView: View {
    @EnvironmentObject private var settings: SettingsManager
    let sampleVerse: Verse?
    
    private var theme: AppTheme { settings.appTheme }
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    // Home Screen Section
                    homeScreenSection
                    
                    // Medium Widget Section
                    mediumWidgetSection
                    
                    // Large Widget Section
                    largeWidgetSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Display Mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.backgroundColor, for: .navigationBar)
        .toolbarColorScheme(theme.isLightTheme ? .light : .dark, for: .navigationBar)
        .onChange(of: settings.mediumWidgetMode) { _, _ in refreshWidgets() }
        .onChange(of: settings.largeWidgetTop) { _, _ in refreshWidgets() }
        .onChange(of: settings.largeWidgetBottom) { _, _ in refreshWidgets() }
    }
    
    // MARK: - Home Screen Section
    
    private var homeScreenSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "iphone")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.accentColor)
                Text("Home Screen")
                    .font(.headline)
                    .foregroundStyle(theme.primaryTextColor)
            }
            .padding(.horizontal, 4)
            
            // Options
            VStack(spacing: 0) {
                ForEach(HomeDisplayMode.allCases.filter { mode in
                    // Only show personalized mode if personalization is enabled and user has a name
                    if mode == .personalized {
                        return settings.personalizationEnabled && !settings.userName.isEmpty
                    }
                    return true
                }) { mode in
                    ThemedOptionRow(
                        title: mode.displayName,
                        subtitle: mode.description,
                        isSelected: settings.homeDisplayMode == mode,
                        theme: theme
                    ) {
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            settings.homeDisplayMode = mode
                        }
                    }
                    
                    if mode != HomeDisplayMode.allCases.last {
                        Divider()
                            .background(theme.secondaryTextColor.opacity(0.3))
                            .padding(.leading, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.buttonBackgroundColor)
            )
            
            Text("Choose what content to display on the home screen")
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
                .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Medium Widget Section
    
    private var mediumWidgetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "rectangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.accentColor)
                Text("Medium Widget")
                    .font(.headline)
                    .foregroundStyle(theme.primaryTextColor)
            }
            .padding(.horizontal, 4)
            
            // Preview
            ThemedMediumWidgetPreview(
                mode: settings.mediumWidgetMode,
                verse: sampleVerse,
                theme: theme
            )
            
            // Options
            VStack(spacing: 0) {
                ForEach(MediumWidgetMode.allCases) { mode in
                    ThemedOptionRow(
                        title: mode.displayName,
                        subtitle: mode.description,
                        isSelected: settings.mediumWidgetMode == mode,
                        theme: theme
                    ) {
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            settings.mediumWidgetMode = mode
                        }
                    }
                    
                    if mode != MediumWidgetMode.allCases.last {
                        Divider()
                            .background(theme.secondaryTextColor.opacity(0.3))
                            .padding(.leading, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.buttonBackgroundColor)
            )
            
            Text("Choose what content to display in the medium widget")
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
                .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Large Widget Section
    
    private var largeWidgetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.accentColor)
                Text("Large Widget")
                    .font(.headline)
                    .foregroundStyle(theme.primaryTextColor)
            }
            .padding(.horizontal, 4)
            
            // Preview
            ThemedLargeWidgetPreview(
                topMode: settings.largeWidgetTop,
                bottomMode: settings.largeWidgetBottom,
                verse: sampleVerse,
                theme: theme
            )
            
            // Top Section Options
            VStack(alignment: .leading, spacing: 10) {
                Text("TOP SECTION")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.accentColor)
                    .padding(.horizontal, 4)
                
                VStack(spacing: 0) {
                    ForEach(LargeWidgetTop.allCases) { mode in
                        ThemedOptionRow(
                            title: mode.displayName,
                            subtitle: mode.description,
                            isSelected: settings.largeWidgetTop == mode,
                            theme: theme
                        ) {
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                settings.largeWidgetTop = mode
                            }
                        }
                        
                        if mode != LargeWidgetTop.allCases.last {
                            Divider()
                                .background(theme.secondaryTextColor.opacity(0.3))
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.buttonBackgroundColor)
                )
            }
            
            // Bottom Section Options
            VStack(alignment: .leading, spacing: 10) {
                Text("BOTTOM SECTION")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.accentColor)
                    .padding(.horizontal, 4)
                
                VStack(spacing: 0) {
                    ForEach(LargeWidgetBottom.allCases) { mode in
                        ThemedOptionRow(
                            title: mode.displayName,
                            subtitle: mode.description,
                            isSelected: settings.largeWidgetBottom == mode,
                            theme: theme
                        ) {
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                settings.largeWidgetBottom = mode
                            }
                        }
                        
                        if mode != LargeWidgetBottom.allCases.last {
                            Divider()
                                .background(theme.secondaryTextColor.opacity(0.3))
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.buttonBackgroundColor)
                )
            }
            
            Text("Large widget shows two sections - customize each independently")
                .font(.caption)
                .foregroundStyle(theme.secondaryTextColor)
                .padding(.horizontal, 4)
        }
    }
    
    private func refreshWidgets() {
        WidgetHelper.reloadAllTimelines()
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(SettingsManager.shared)
}
