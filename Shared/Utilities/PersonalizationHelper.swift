//
//  PersonalizationHelper.swift
//  Vani
//
//  Helper for personalizing verse text with user's name.
//  Currently returns original text; architecture ready for vocative replacement.
//

import Foundation

/// Helper for personalizing verse text
enum PersonalizationHelper {
    
    // MARK: - Personalization
    
    /// Personalizes the given text by replacing {name} placeholder with user's name
    ///
    /// - Parameters:
    ///   - text: The text to personalize (should contain {name} placeholder)
    ///   - verse: The verse containing personalized field
    ///   - settings: User settings with name and personalization toggle
    /// - Returns: Personalized text with {name} replaced, or original text if personalization is disabled
    static func personalize(
        text: String,
        verse: Verse,
        settings: SettingsManager
    ) -> String {
        // Return original text if personalization is disabled or no name is set
        guard settings.personalizationEnabled,
              !settings.userName.isEmpty,
              verse.hasVocative,
              let personalizedText = verse.personalized else {
            return text
        }
        
        // Replace {name} placeholder with user's name
        return personalizedText.replacingOccurrences(of: "{name}", with: settings.userName)
    }
    
    // MARK: - Future Implementation Reference
    
    /*
     Example implementation for future:
     
     static func personalize(text: String, verse: Verse, settings: SettingsManager) -> String {
         guard settings.personalizationEnabled,
               !settings.userName.isEmpty,
               verse.hasVocative else {
             return text
         }
         
         var result = text
         let userName = settings.userName
         
         for term in verse.vocativeTerms {
             // Replace "O Arjuna" with "O [Name]"
             result = result.replacingOccurrences(of: "O \(term)", with: "O \(userName)")
             
             // Replace standalone terms
             result = result.replacingOccurrences(of: term, with: userName)
         }
         
         return result
     }
     */
}


