//
//  GitaData.swift
//  Vani
//
//  Root data model for the Bhagavad Gita JSON dataset.
//

import Foundation

/// Represents a single chapter with its verses
struct ChapterData: Codable {
    /// Chapter-level metadata
    let chapterInfo: Chapter
    
    /// Array of verses in the chapter
    let verses: [Verse]
    
    enum CodingKeys: String, CodingKey {
        case chapterInfo = "chapter_info"
        case verses
    }
}

/// Root container for the Bhagavad Gita dataset
struct GitaData: Codable {
    
    /// Array of chapters (supports multiple chapters)
    let chapters: [ChapterData]
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case chapters
    }
    
    // MARK: - Convenience Accessors (for backward compatibility)
    
    /// Get the first chapter (for single-chapter compatibility)
    var chapterInfo: Chapter? {
        chapters.first?.chapterInfo
    }
    
    /// Get all verses from all chapters
    var allVerses: [Verse] {
        chapters.flatMap { $0.verses }
    }
    
    /// Get verses from a specific chapter
    func verses(for chapterNumber: Int) -> [Verse] {
        chapters.first(where: { $0.chapterInfo.chapterNumber == chapterNumber })?.verses ?? []
    }
    
    /// Get chapter by number
    func chapter(_ chapterNumber: Int) -> Chapter? {
        chapters.first(where: { $0.chapterInfo.chapterNumber == chapterNumber })?.chapterInfo
    }
}

// MARK: - Sample Data for Previews

extension GitaData {
    static let sample = GitaData(
        chapters: [
            ChapterData(
                chapterInfo: .sample,
                verses: [.sample]
            )
        ]
    )
}


