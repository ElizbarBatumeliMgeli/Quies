//
//  WidgetManager.swift
//  Quies
//
//  Created by Elizbar Kheladze on 29/01/26.
//

import Foundation
import WidgetKit
import Combine

// MARK: - Widget Manager
class WidgetManager: ObservableObject {
    private let appGroupID = "group.com.quies.watch"
    
    // MARK: - Update Widget Data
    func updateWidget(wakeTime: Date, mode: AppMode, isActive: Bool) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            print("Failed to access app group")
            return
        }
        
        let widgetData = QuiesWidgetData(
            wakeTime: wakeTime,
            mode: mode == .napping ? "napping" : "smart",
            isActive: isActive
        )
        
        if let encoded = try? JSONEncoder().encode(widgetData) {
            sharedDefaults.set(encoded, forKey: "QuiesWidgetData")
            sharedDefaults.synchronize()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // MARK: - Clear Widget
    func clearWidget() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else { return }
        
        let widgetData = QuiesWidgetData(
            wakeTime: Date(),
            mode: "napping",
            isActive: false
        )
        
        if let encoded = try? JSONEncoder().encode(widgetData) {
            sharedDefaults.set(encoded, forKey: "QuiesWidgetData")
            sharedDefaults.synchronize()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

