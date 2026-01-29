//
//  QuiesWidgetAttributes.swift
//  Quies
//
//  Created by Elizbar Kheladze on 29/01/26.
//

import Foundation

// MARK: - Widget Data Structure
struct QuiesWidgetData: Codable {
    var wakeTime: Date
    var mode: String
    var isActive: Bool
}
