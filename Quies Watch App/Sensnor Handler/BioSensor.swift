//
//  BioSensor.swift
//  Nappy
//
//  Created by Elizbar Kheladze on 05/01/26.
//

import Foundation
import CoreMotion

@Observable class BioSensors {
    private let motionManager = CMMotionManager()
    
    var movementScore: Double = 0.0
    
    private var recentmovements: [Double] = []
        
        var smoothedMovementScore: Double {
            guard !recentmovements.isEmpty else { return 0.0 }
            let sum = recentmovements.reduce(0, +)
            return sum / Double(recentmovements.count)
        }
    
    func startMonitoring() {
        guard motionManager.isAccelerometerAvailable else {
            print("Accelerometer not available")
            return
        }
        
        
        motionManager.accelerometerUpdateInterval = 1.0 / 10.0
                
                motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
                    guard let self = self, let data = data else { return }
                    
                    let x = data.acceleration.x
                    let y = data.acceleration.y
                    let z = data.acceleration.z
                    let magnitude = sqrt(x*x + y*y + z*z)
                    let deviation = abs(magnitude - 1.0)
                    
                    DispatchQueue.main.async {
                        self.recentmovements.append(deviation)
                        if self.recentmovements.count > 30 {
                            self.recentmovements.removeFirst()
                        }
                        self.movementScore = deviation
                    }
                }
    }
    
    func stopMonitoring() {
        motionManager.stopAccelerometerUpdates()
        self.movementScore = 0.0
    }
}
