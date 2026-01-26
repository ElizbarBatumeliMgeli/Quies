//
//  OnboardingView.swift
//  Quies
//
//  Created by Elizbar Kheladze on 20/01/26.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboarding: Bool
    
    var body: some View {
        TabView {
            // PAGE 1: Intro
            OnboardingPage(
                icon: "waveform.path.ecg",
                title: "Welcome to Quies",
                description: "Your smart companion for better rest and energized wake-ups."
            )
            
            // PAGE 2: Naps
            OnboardingPage(
                icon: "moon.zzz.fill",
                title: "Power Naps",
                description: "Quick preset timers (1h–2.5h) designed to recharge you without grogginess."
            )
            
            // PAGE 3: Alarm
            OnboardingPage(
                icon: "alarm.waves.left.and.right.fill",
                title: "Smart Wake",
                description: "Detects your lightest sleep phase within 30 mins to wake you gently."
            )
            
            // PAGE 4: Disclaimer & Start (SCROLLABLE NOW)
            ScrollView {
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                        .padding(.bottom, 5)
                    
                    Text("Important Note")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("This is not a medical device. Use as a backup aid only. Reliability depends on battery and sensors.")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                        .frame(height: 5)
                }
                .padding()
            }
            .containerBackground(.black.gradient, for: .tabView)
            
            VStack {
                Button(action: {
                    withAnimation {
                        isOnboarding = false
                    }
                }) {
                    Text("Get Started")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .clipShape(Capsule())
            }
            .containerBackground(.black.gradient, for: .tabView)
        }
        .tabViewStyle(.page)
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 5)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(description)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
        }
        .containerBackground(.black.gradient, for: .tabView)
    }
}
