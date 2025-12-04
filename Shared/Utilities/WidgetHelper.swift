//
//  WidgetHelper.swift
//  Vani
//
//  Helper for safely reloading widgets, preventing errors in preview mode.
//

import Foundation
import WidgetKit

/// Helper for safely managing widget reloads
enum WidgetHelper {
    
    /// Safely reloads all widget timelines, preventing errors in preview mode
    /// This prevents "Connection invalidated" errors when running in SwiftUI Previews
    static func reloadAllTimelines() {
        // Check if we're running in preview mode
        #if DEBUG
        // Check for preview environment variable set by Xcode when running previews
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        let isUITesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        
        if isPreview || isUITesting {
            // Skip widget reload in preview/test mode to prevent connection errors
            return
        }
        #endif
        
        // Perform widget reload on main thread
        // Note: WidgetCenter.shared.reloadAllTimelines() doesn't throw, so no error handling needed
        let reloadBlock = {
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        if Thread.isMainThread {
            reloadBlock()
        } else {
            DispatchQueue.main.async {
                reloadBlock()
            }
        }
    }
}

