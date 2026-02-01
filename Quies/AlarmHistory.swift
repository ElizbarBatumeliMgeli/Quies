import Foundation
import Combine
import SwiftUI

struct AlarmHistoryEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var wakeTime: Date
    var actualWakeTime: Date?
    var mode: AlarmMode
    var wasSuccessful: Bool
    var napDuration: TimeInterval?
    var reason: String?
    
    var sleepQuality: SleepQuality {
        guard let actual = actualWakeTime else { return .unknown }
        let difference = abs(actual.timeIntervalSince(wakeTime))
        
        if difference < 300 {
            return .excellent
        } else if difference < 900 {
            return .good
        } else {
            return .needsImprovement
        }
    }
}

enum SleepQuality: String, Codable {
    case excellent
    case good
    case needsImprovement
    case unknown
    
    var displayText: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .needsImprovement: return "Needs Improvement"
        case .unknown: return "Unknown"
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .needsImprovement: return "orange"
        case .unknown: return "gray"
        }
    }
}

@MainActor
class AlarmHistory: ObservableObject {
    @Published var entries: [AlarmHistoryEntry] = []
    
    private let saveKey = "alarmHistory"
    
    init() {
        loadHistory()
    }
    
    func addEntry(_ entry: AlarmHistoryEntry) {
        entries.insert(entry, at: 0)
        saveHistory()
    }
    
    func deleteEntry(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        saveHistory()
    }
    
    var statistics: Statistics {
        let total = entries.count
        let successful = entries.filter { $0.wasSuccessful }.count
        let naps = entries.filter { $0.mode == .nap }
        let smartAlarms = entries.filter { $0.mode == .smartAlarm }
        
        let avgNapDuration = naps.compactMap { $0.napDuration }.reduce(0, +) / Double(max(naps.count, 1))
        
        return Statistics(
            totalAlarms: total,
            successfulAlarms: successful,
            totalNaps: naps.count,
            totalSmartAlarms: smartAlarms.count,
            averageNapDuration: avgNapDuration
        )
    }
    
    struct Statistics {
        let totalAlarms: Int
        let successfulAlarms: Int
        let totalNaps: Int
        let totalSmartAlarms: Int
        let averageNapDuration: TimeInterval
        
        var successRate: Double {
            guard totalAlarms > 0 else { return 0 }
            return Double(successfulAlarms) / Double(totalAlarms) * 100
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([AlarmHistoryEntry].self, from: data) {
            entries = decoded
        }
    }
}
