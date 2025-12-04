# Vani - Bhagavad Gita Widget App

<div align="center">

**Daily wisdom from the Bhagavad Gita, beautifully delivered to your Home and Lock Screen**

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![WidgetKit](https://img.shields.io/badge/WidgetKit-2.0-purple.svg)](https://developer.apple.com/widgets/)

</div>

---

## 📖 About

**Vani** is a beautifully designed iOS app that brings the timeless wisdom of the Bhagavad Gita directly to your iPhone. Experience Krishna's teachings through elegant widgets on your Home and Lock Screen, with a premium in-app experience for deeper exploration.

The app features carefully curated verses spoken by Krishna, presented with Sanskrit text, transliteration, and English translations. Each verse is thoughtfully selected to provide daily inspiration and spiritual guidance.

---

## ✨ Features

### 🎨 **Beautiful Themes**
Choose from 6 stunning themes, each with unique animations and visual effects:
- **Celestial** - Starry night sky with shooting stars
- **Sacred Lotus** - Serene lotus pond with gentle ripples
- **Forest Ashram** - Peaceful forest with floating leaves
- **Cherry Blossom** - Delicate cherry blossoms in spring
- **Sunset Meditation** - Warm sunset gradients
- **Ocean Serenity** - Calm ocean waves

### 📱 **Home & Lock Screen Widgets**
- **Small Widget** - Quick verse summary
- **Medium Widget** - Verse with Sanskrit or transliteration
- **Large Widget** - Full verse display with multiple text layers
- Automatic daily updates
- Respects your display preferences and filters

### 🎯 **Personalization**
- Set your name for personalized verses
- Customize which text layers to display (Sanskrit, Transliteration, Translation)
- Filter verses by key concepts (duty, devotion, wisdom, etc.)
- Choose your preferred display mode

### ⭐ **Favorites System**
- Save your favorite verses for quick access
- Organize and revisit meaningful teachings
- Share your favorites with others

### 🔔 **Smart Notifications**
- Daily verse notifications at your preferred time
- Mindfulness reminders
- Customizable notification schedule
- Respects your device's Do Not Disturb settings

### 🎨 **Share Templates**
Share verses beautifully with 5 different template designs:
- Classic
- Minimal
- Elegant
- Modern
- Traditional

### 📚 **Complete Verse View**
- View full Sanskrit text
- See transliteration
- Read complete English translation
- Explore key concepts and themes
- Learn about chapter context

### ⚙️ **Comprehensive Settings**
- Account management
- Widget customization
- Display preferences
- Verse rotation schedule
- Notification preferences
- Theme selection

### 🚀 **Onboarding Experience**
- Welcome screen
- Name setup
- Theme selection
- Notification setup
- Widget configuration guide

---

## 🏗️ Architecture

### **Clean & Scalable Design**
- **Modular Architecture** - Separation of concerns with Models, Services, Utilities, and Views
- **Protocol-Based Repository** - Easy to swap data sources
- **Shared Codebase** - Common code between app and widget extension
- **App Group** - Seamless data sharing between app and widgets

### **Technologies Used**
- **SwiftUI** - Modern declarative UI framework
- **WidgetKit** - Home and Lock Screen widgets
- **Combine** - Reactive programming for settings
- **UserDefaults** - Persistent storage with App Groups
- **Codable** - JSON parsing and encoding

### **Key Components**

#### **Data Layer**
- `GitaRepository` - Data loading and management
- `Verse` - Verse data model
- `Chapter` - Chapter metadata
- `GitaData` - Root data container

#### **Business Logic**
- `VerseFilter` - Filtering by speaker and key concepts
- `VerseSelector` - Verse selection algorithms
- `PersonalizationHelper` - Text personalization
- `SettingsManager` - User preferences management

#### **UI Components**
- `HomeView` - Main verse display
- `FullVerseView` - Detailed verse view
- `SettingsView` - Comprehensive settings
- `ThemesView` - Theme selection
- `FavoritesView` - Saved verses
- `OnboardingView` - First-time user experience

#### **Widget Extension**
- `VaniWidget` - Widget implementation
- `VaniTimelineProvider` - Widget timeline management
- Small, Medium, and Large widget views

---

## 📦 Installation

### **Requirements**
- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### **Setup**
1. Clone the repository
2. Open `Vani.xcodeproj` in Xcode
3. Configure your Apple Developer Team
4. Build and run on simulator or device

### **App Group Configuration**
The app uses an App Group (`group.com.vani.shared`) for sharing data between the main app and widget extension. Ensure this is configured in:
- Main app target capabilities
- Widget extension target capabilities

---

## 🎯 Usage

### **Getting Started**
1. Launch the app
2. Complete the onboarding flow
3. Choose your preferred theme
4. Set up notifications (optional)
5. Add widgets to your Home Screen

### **Viewing Verses**
- **Home Tab** - See the current verse with your preferred display mode
- **Tap Verse** - View full details with all text layers
- **New Verse** - Get a random verse from eligible verses
- **Favorites** - Access your saved verses

### **Customizing Widgets**
1. Go to Settings → Widget Settings
2. Choose display mode for each widget size
3. Widgets update automatically

### **Personalization**
1. Go to Settings → Account
2. Enter your name
3. Enable personalization in Settings → Personalization
4. Verses with vocative terms will use your name

### **Filtering Verses**
1. Go to Settings → Key Concepts
2. Select concepts you're interested in
3. Only verses matching selected concepts will appear

---

## 📊 Data

The app uses a local JSON dataset (`bhagavad_gita.json`) containing:
- Chapter metadata (name, theme, verse counts)
- Verse data with:
  - Sanskrit text (Devanagari)
  - Transliteration
  - English translation
  - Widget-friendly summary
  - Personalized version (with `{name}` placeholder)
  - Key concept tags
  - Vocative terms (for personalization)

The dataset is designed to be easily expandable to include all 18 chapters of the Bhagavad Gita.

---

## 🎨 Design Philosophy

**Vani** is designed with these principles:
- **Minimalism** - Clean, uncluttered interface
- **Beauty** - Thoughtful design and animations
- **Accessibility** - Support for Dynamic Type and accessibility features
- **Performance** - Fast loading and smooth animations
- **Respect** - Honoring the sacred nature of the content

---

## 🔮 Future Enhancements

The architecture is designed to easily support:
- Multi-chapter navigation
- Audio playback of verses
- Commentary and notes
- Search functionality
- Apple Watch complications
- Additional themes and customization options

---

## 📱 Screenshots

Screenshots are available in the `AppStore_Screenshots/` directory for:
- iPhone (6.7" - iPhone 15 Pro Max)
- iPad (12.9" - iPad Pro)

---

## 🤝 Contributing

This is a personal project, but suggestions and feedback are welcome!

---

## 📄 License

All rights reserved. The Bhagavad Gita text and translations are used with appropriate permissions.

---

## 🙏 Acknowledgments

- The timeless wisdom of the Bhagavad Gita
- All translators and scholars who have made this text accessible
- The Swift and SwiftUI communities

---

## 📞 Support

For issues, questions, or feedback, please contact through the app's support channels.

---

## 🔒 Privacy Policy

**Vāṇī** is committed to protecting your privacy. We do not collect, store, or transmit any personal information from your device.

### Key Privacy Points:
- ✅ **No Data Collection** - We do not collect any personal information
- ✅ **Local Storage Only** - All data (preferences, favorites, settings) is stored locally on your device
- ✅ **No Tracking** - No analytics, no tracking, no third-party services
- ✅ **No Server Communication** - The app operates entirely offline
- ✅ **Widget Privacy** - Widget extension only accesses local data, never transmits anything

### Your Data:
- All app preferences and settings are stored locally using iOS UserDefaults
- Your name (if entered for personalization) is stored only on your device
- Favorite verses are saved locally
- No data is ever transmitted to us or any third parties

### Full Privacy Policy:
For complete details, please read our [Privacy Policy](https://patelvivek9111.github.io/vani/privacy-policy.html).

---

<div align="center">

**Made with ❤️ for spiritual seekers**

*"The soul is eternal, unborn, and indestructible"* - Bhagavad Gita 2.20

</div>

