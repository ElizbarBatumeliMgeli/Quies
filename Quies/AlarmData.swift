import Foundation

enum AlarmMode: String, Codable {
    case nap
    case smartAlarm
}

struct AlarmData: Codable, Identifiable {
    var id: UUID = UUID()
    var wakeTime: Date
    var mode: AlarmMode
    var isActive: Bool
    var createdAt: Date = Date()
    
    var napDuration: TimeInterval? {
        guard mode == .nap else { return nil }
        return wakeTime.timeIntervalSince(createdAt)
    }
}

extension AlarmData {
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "wakeTime": wakeTime.timeIntervalSince1970,
            "mode": mode.rawValue,
            "isActive": isActive,
            "createdAt": createdAt.timeIntervalSince1970
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> AlarmData? {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let wakeTimeInterval = dict["wakeTime"] as? TimeInterval,
              let modeString = dict["mode"] as? String,
              let mode = AlarmMode(rawValue: modeString),
              let isActive = dict["isActive"] as? Bool,
              let createdAtInterval = dict["createdAt"] as? TimeInterval else {
            return nil
        }
        
        return AlarmData(
            id: id,
            wakeTime: Date(timeIntervalSince1970: wakeTimeInterval),
            mode: mode,
            isActive: isActive,
            createdAt: Date(timeIntervalSince1970: createdAtInterval)
        )
    }
}
