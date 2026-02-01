
import Foundation
import WatchConnectivity
import SwiftUI
import Combine

@MainActor
class WatchConnectionManager: NSObject, ObservableObject {
    @Published var isWatchPaired = false
    @Published var isWatchAppInstalled = false
    @Published var isWatchReachable = false
    @Published var currentAlarm: AlarmData?
    
    private var session: WCSession?
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    func sendAlarmToWatch(_ alarm: AlarmData) {
        guard let session = session, session.isReachable else {
            print("Watch not reachable")
            return
        }
        
        let message = [
            "action": "setAlarm",
            "alarm": alarm.toDictionary()
        ] as [String : Any]
        
        session.sendMessage(message, replyHandler: { reply in
            print("Watch replied: \(reply)")
        }, errorHandler: { error in
            print("Error sending to watch: \(error.localizedDescription)")
        })
    }
    
    func stopAlarmOnWatch() {
        guard let session = session, session.isReachable else {
            print("Watch not reachable")
            return
        }
        
        let message = ["action": "stopAlarm"]
        
        session.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("Error stopping alarm: \(error.localizedDescription)")
        })
        
        currentAlarm = nil
    }
    
    func wakeWatchApp() {
        guard let session = session else { return }
        
        let message = ["action": "wakeUp"]
        session.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("Wake error: \(error.localizedDescription)")
        })
    }
    
    func updateContext(alarm: AlarmData?) {
        guard let session = session else { return }
        
        do {
            if let alarm = alarm {
                let context = ["currentAlarm": alarm.toDictionary()]
                try session.updateApplicationContext(context)
            } else {
                try session.updateApplicationContext([:])
            }
        } catch {
            print("Context update error: \(error.localizedDescription)")
        }
    }
}

extension WatchConnectionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            isWatchPaired = session.isPaired
            isWatchAppInstalled = session.isWatchAppInstalled
            isWatchReachable = session.isReachable
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        Task { @MainActor in
            isWatchReachable = false
        }
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            isWatchReachable = false
        }
        session.activate()
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isWatchReachable = session.isReachable
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            if let action = message["action"] as? String {
                switch action {
                case "alarmTriggered":
                    if let alarmDict = message["alarm"] as? [String: Any],
                       let alarm = AlarmData.fromDictionary(alarmDict) {
                        handleAlarmTriggered(alarm)
                    }
                case "alarmStopped":
                    currentAlarm = nil
                default:
                    break
                }
            }
        }
    }
    
    private func handleAlarmTriggered(_ alarm: AlarmData) {
        currentAlarm = nil
    }
}
