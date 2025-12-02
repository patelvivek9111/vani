//
//  ShareTemplate.swift
//  Vani
//
//  Share card template designs for verse sharing.
//

import Foundation
import SwiftUI

/// Different share card template designs
enum ShareTemplate: String, Codable, CaseIterable, Identifiable {
    case classic
    case minimal
    case ornate
    case quote
    case elegant
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .minimal: return "Minimal"
        case .ornate: return "Ornate"
        case .quote: return "Quote Style"
        case .elegant: return "Elegant"
        }
    }
    
    var description: String {
        switch self {
        case .classic: return "Original design with gradient background"
        case .minimal: return "Clean, text-focused design"
        case .ornate: return "Decorative borders and patterns"
        case .quote: return "Large text, minimal background"
        case .elegant: return "Sophisticated typography and spacing"
        }
    }
    
    var icon: String {
        switch self {
        case .classic: return "sparkles"
        case .minimal: return "text.aligncenter"
        case .ornate: return "square.fill"
        case .quote: return "quote.opening"
        case .elegant: return "textformat"
        }
    }
}




