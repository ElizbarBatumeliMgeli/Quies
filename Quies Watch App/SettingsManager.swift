//
//  SettingsManager.swift
//  Nappy
//
//  Created by Elizbar Kheladze on 17/01/26.
//

import Foundation
import SwiftUI
import Combine

class SettingsManager: ObservableObject {
    @AppStorage("selectedSound") var selectedSound: String = "alarm1"
    
    let sounds: [(file: String, name: String)] = [
        ("alarm1", "At Last"),
        ("alarm2", "Radiant Beginning"),
        ("alarm3", "Last Stand")
    ]
}
