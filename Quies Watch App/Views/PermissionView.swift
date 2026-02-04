//
//  PermissionView.swift
//  Quies
//
//  Created by Elizbar Kheladze on 20/01/26.
//

import SwiftUI

struct PermissionView: View {
    @Bindable var manager: PermissionManager
    
    var body: some View {
        ScrollView {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            if manager.isDenied {
                Text("Access Denied")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Quies cannot work without sensors.\n\nPlease open Settings on your Apple Watch:\nPrivacy > Motion & Fitness > Quies > Turn ON.")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button(action: { manager.checkStatus() }) {
                    Text("I Fixed It")
                }
                .buttonStyle(.bordered)
                
            } else {
                Text("Permissions Needed")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("To detect your sleep phase, Quies needs access to your Health and Motion sensors.")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button(action: {
                    manager.requestPermissions()
                }) {
                    Text("Allow Access")
                        .fontWeight(.bold)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .padding(.top, 10)
            }
        }
        .containerBackground(.black.gradient, for: .tabView)
    }
}
