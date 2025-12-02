//
//  Speaker.swift
//  Vani
//
//  Enum representing speakers in the Bhagavad Gita.
//

import Foundation

/// Speakers in the Bhagavad Gita
enum Speaker: String, Codable, CaseIterable {
    case krishna = "Krishna"
    case arjuna = "Arjuna"
    case sanjaya = "Sanjaya"
    case dhritarashtra = "Dhritarashtra"
    
    /// Human-readable display name
    var displayName: String { rawValue }
}





