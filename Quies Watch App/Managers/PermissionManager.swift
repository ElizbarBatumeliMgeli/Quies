//
//  PermissionManager.swift
//  Nappy
//
//  Created by Elizbar Kheladze on 14/01/26.
//

import Foundation
import HealthKit
import CoreMotion

@Observable class PermissionManager {
    var isAuthorized = false
    var isDenied = false
    
    private let healthStore = HKHealthStore()
    private let motionActivityManager = CMMotionActivityManager()
    
    init() {
        checkStatus()
    }
    
    func checkStatus() {
        let status = CMMotionActivityManager.authorizationStatus()
        
        DispatchQueue.main.async {
            self.isAuthorized = (status == .authorized)
            
            self.isDenied = (status == .denied || status == .restricted)
        }
    }
    
    func requestPermissions() {
        if HKHealthStore.isHealthDataAvailable() {
            let typesToShare: Set = [HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!]
            let typesToRead: Set = [
                HKObjectType.quantityType(forIdentifier: .heartRate)!,
                HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
            ]
            healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { _, _ in }
        }
        
        let now = Date()
        motionActivityManager.queryActivityStarting(from: now, to: now, to: .main) { _, _ in
            self.checkStatus()
        }
    }
}
