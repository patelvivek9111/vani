//
//  ConnectionErrorHandler.swift
//  Vani
//
//  Handles and suppresses harmless connection errors from SwiftUI Previews and debugger.
//

import Foundation

/// Handles connection errors that occur during development (previews, debugger)
enum ConnectionErrorHandler {
    
    /// Checks if we're in a development environment where connection errors are expected
    static var isDevelopmentEnvironment: Bool {
        #if DEBUG
        // Check for preview mode
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return true
        }
        
        // Check for UI testing
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return true
        }
        
        // Check if running in simulator (more likely to have connection issues)
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
        #else
        return false
        #endif
    }
    
    /// Logs a connection error with context
    /// - Parameters:
    ///   - error: The error description
    ///   - source: Where the error originated (e.g., "Preview", "Debugger", "Widget")
    static func logConnectionError(_ error: String, source: String = "Unknown") {
        // Debug logging removed
    }
    
    /// Suppresses connection invalidated errors in development
    static func shouldSuppressError(_ error: String) -> Bool {
        guard isDevelopmentEnvironment else { return false }
        
        // Suppress common preview/debugger connection errors
        let suppressableErrors = [
            "Connection invalidated",
            "connection invalidated",
            "Connection Invalidated"
        ]
        
        return suppressableErrors.contains { error.contains($0) }
    }
}

