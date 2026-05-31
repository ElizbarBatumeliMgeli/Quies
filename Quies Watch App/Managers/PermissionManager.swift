//
//  PermissionManager.swift
//  Nappy
//
//  Created by Elizbar Kheladze on 14/01/26.
//

import Foundation
import HealthKit
import CoreMotion

@MainActor
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
        
        self.isAuthorized = (status == .authorized)
        self.isDenied = (status == .denied || status == .restricted)
    }
    
    func requestPermissions() {
        if HKHealthStore.isHealthDataAvailable() {
            let typesToShare: Set = [HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!]
            let typesToRead: Set = [
                HKObjectType.quantityType(forIdentifier: .heartRate)!,
                HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
            ]
            
            // MARK: - HealthKit Request
            Task {
                try? await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            }
        }
        
        let now = Date()
        motionActivityManager.queryActivityStarting(from: now, to: now, to: .main) { [weak self] _, _ in
            guard let self = self else { return }
            self.checkStatus()
        }
    }
}
