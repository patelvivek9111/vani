# App Store Screenshots

## 📱 Generated Screenshots

### iPhone (6.7" - iPhone 15 Pro Max)
- **Resolution:** 1206 x 2622 pixels
- **Format:** PNG
- **Files:**
  1. `01_Home.png` - Home screen with verse display
  2. `02_Settings.png` - Settings screen
  3. `03_Themes.png` - Themes selection screen
  4. `04_Favorites.png` - Favorites screen

### iPad (12.9" - iPad Pro)
- **Resolution:** 2064 x 2752 pixels
- **Format:** PNG
- **Files:**
  1. `01_Home.png` - Home screen with verse display
  2. `02_Settings.png` - Settings screen
  3. `03_Themes.png` - Themes selection screen
  4. `04_Favorites.png` - Favorites screen

## 📋 App Store Connect Requirements

### iPhone Screenshots Required:
- **6.7" Display (iPhone 15 Pro Max, iPhone 14 Pro Max, iPhone 13 Pro Max, iPhone 12 Pro Max):**
  - Required: 1290 x 2796 pixels (portrait)
  - Optional: 2796 x 1290 pixels (landscape)

- **6.5" Display (iPhone 11 Pro Max, iPhone XS Max):**
  - Required: 1242 x 2688 pixels (portrait)
  - Optional: 2688 x 1242 pixels (landscape)

### iPad Screenshots Required:
- **12.9" iPad Pro (3rd generation and later):**
  - Required: 2048 x 2732 pixels (portrait)
  - Optional: 2732 x 2048 pixels (landscape)

- **12.9" iPad Pro (1st and 2nd generation):**
  - Required: 2048 x 2732 pixels (portrait)
  - Optional: 2732 x 2048 pixels (landscape)

## 🔧 Resizing Screenshots (if needed)

If you need to resize the screenshots to match exact App Store requirements, you can use:

```bash
# Using sips (built into macOS)
sips -z 2796 1290 iPhone/01_Home.png --out iPhone_Resized/01_Home_6.7.png

# Or using ImageMagick (if installed)
convert iPhone/01_Home.png -resize 1290x2796 iPhone_Resized/01_Home_6.7.png
```

## 📝 Notes

- Current screenshots are taken from the simulator
- You may want to manually navigate to each screen to ensure the best composition
- Consider adding text overlays or annotations for marketing purposes
- All screenshots are in portrait orientation
- Screenshots show the app's key features:
  1. **Home:** Main verse display with beautiful themes
  2. **Settings:** Account, Widget Settings, Personalization options
  3. **Themes:** Theme selection with previews
  4. **Favorites:** Saved verses

## ✅ Next Steps

1. Review screenshots for quality and composition
2. Resize if needed to match exact App Store requirements
3. Add marketing text/overlays if desired
4. Upload to App Store Connect

---

**Generated:** December 1, 2025  
**App Version:** 1.0  
**Status:** Ready for App Store submission

