//
//  GitaRepository.swift
//  Vani
//
//  Data repository for loading and accessing Bhagavad Gita data.
//

import Foundation

// MARK: - Repository Protocol

/// Protocol defining the interface for accessing Gita data
protocol GitaRepositoryProtocol {
    func loadData() throws -> GitaData
    func getAllVerses(from data: GitaData) -> [Verse]
    func getKrishnaVerses(from data: GitaData) -> [Verse]
    func getChapter(from data: GitaData) -> Chapter
    func getAllChapters(from data: GitaData) -> [Chapter]
    func getVerses(from data: GitaData, chapterNumber: Int) -> [Verse]
    func getKrishnaVerses(from data: GitaData, chapterNumber: Int) -> [Verse]
}

// MARK: - Repository Errors

enum GitaRepositoryError: Error, LocalizedError {
    case fileNotFound
    case decodingFailed(Error)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "The Gita data file could not be found."
        case .decodingFailed(let error):
            return "Failed to decode Gita data: \(error.localizedDescription)"
        case .invalidData:
            return "The Gita data is invalid or corrupted."
        }
    }
}

// MARK: - Bundle Repository Implementation

/// Loads Gita data from the app bundle
final class BundleGitaRepository: GitaRepositoryProtocol {
    
    private let bundle: Bundle
    private let filename: String
    private let fileExtension: String
    
    /// Cached data to avoid repeated parsing
    private var cachedData: GitaData?
    
    init(
        bundle: Bundle = .main,
        filename: String = AppConstants.DataFiles.gitaVersesFilename,
        fileExtension: String = AppConstants.DataFiles.gitaVersesExtension
    ) {
        self.bundle = bundle
        self.filename = filename
        self.fileExtension = fileExtension
    }
    
    // MARK: - GitaRepositoryProtocol
    
    func loadData() throws -> GitaData {
        // Return cached data if available
        if let cached = cachedData {
            return cached
        }
        
        // Find the file in the bundle
        guard let url = bundle.url(forResource: filename, withExtension: fileExtension) else {
            throw GitaRepositoryError.fileNotFound
        }
        
        // Load and decode
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let gitaData = try decoder.decode(GitaData.self, from: data)
            
            // Cache the result
            cachedData = gitaData
            
            return gitaData
        } catch let error as DecodingError {
            throw GitaRepositoryError.decodingFailed(error)
        } catch {
            throw GitaRepositoryError.invalidData
        }
    }
    
    func getAllVerses(from data: GitaData) -> [Verse] {
        data.allVerses
    }
    
    func getKrishnaVerses(from data: GitaData) -> [Verse] {
        data.allVerses.filter { $0.speaker == Speaker.krishna.rawValue }
    }
    
    func getChapter(from data: GitaData) -> Chapter {
        // Return first chapter for backward compatibility, or get a specific chapter
        data.chapterInfo ?? data.chapters.first?.chapterInfo ?? Chapter.sample
    }
    
    /// Get all available chapters
    func getAllChapters(from data: GitaData) -> [Chapter] {
        data.chapters.map { $0.chapterInfo }
    }
    
    /// Get verses from a specific chapter
    func getVerses(from data: GitaData, chapterNumber: Int) -> [Verse] {
        data.verses(for: chapterNumber)
    }
    
    /// Get Krishna verses from a specific chapter
    func getKrishnaVerses(from data: GitaData, chapterNumber: Int) -> [Verse] {
        data.verses(for: chapterNumber).filter { $0.speaker == Speaker.krishna.rawValue }
    }
    
    // MARK: - Helpers
    
    /// Clears the cached data (useful for testing or forced reload)
    func clearCache() {
        cachedData = nil
    }
}


