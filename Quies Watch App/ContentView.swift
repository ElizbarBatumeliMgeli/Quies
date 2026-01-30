//
//  ContentView.swift
//  Nappy Watch App
//
//  Created by Elizbar Kheladze on 05/01/26.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @StateObject private var alarmManager = AlarmManager()
    @StateObject private var permissionManager = PermissionManager()
    
    @AppStorage("showOnboarding") private var showOnboarding = true
    
    @State private var selectedTime = Date()
    @State private var isSelectingTime = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if !permissionManager.isAuthorized {
                    PermissionView(manager: permissionManager)
                } else if showOnboarding {
                    OnboardingView(isOnboarding: $showOnboarding)
                        .transition(.opacity)
                } else {
                    if alarmManager.currentMode == .idle {
                        mainAppView
                    } else {
                        activeSessionView
                    }
                }
            }
        }
        .sheet(isPresented: $isSelectingTime) {
            VStack(spacing: 15) {
                Text("Set Wake Up Time")
                    .font(.headline)
                
                DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.automatic)
                    .frame(height: 50)
                
                Button(action: {
                    alarmManager.setSmartAlarm(at: selectedTime)
                    isSelectingTime = false
                }) {
                    Text("Start Alarm").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .clipShape(Capsule())
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HandleBackgroundTask"))) { notification in
            if let task = notification.object as? WKApplicationRefreshBackgroundTask {
                alarmManager.handleBackgroundTask(task: task)
            }
        }
    }
    
    var mainAppView: some View {
        ZStack(alignment: .topLeading) {
            
            TabView(selection: $selectedTab) {
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    Text("Quick Naps")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.accentColor)
                        .padding(.bottom, 10)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        NapButton(hours: 1.0, label: "1", color: .indigo, manager: alarmManager)
                        NapButton(hours: 1.5, label: "1.5", color: .indigo, manager: alarmManager)
                        NapButton(hours: 2.0, label: "2", color: .purple, manager: alarmManager)
                        NapButton(hours: 2.5, label: "2.5", color: .purple, manager: alarmManager)
                    }
                    .padding(.horizontal, 8)
                    
                    Spacer()
                }
                .tag(0)
                .containerBackground(.black.gradient, for: .tabView)
                
                VStack(spacing: 20) {
                    Spacer()
                    Text("Smart Alarm")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.orange)
                    
                    Button(action: { isSelectingTime = true }) {
                        VStack(spacing: 5) {
                            Image(systemName: "alarm.fill").font(.largeTitle)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                    .glassEffect()
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .clipShape(ContainerRelativeShape())
                    .padding(.horizontal)
                    Spacer()
                }
                .tag(1)
                .containerBackground(.black.gradient, for: .tabView)
            }
            .tabViewStyle(.verticalPage)
            
            if selectedTab == 0 {
                Button(action: {
                    withAnimation { showOnboarding = true }
                }) {
                    Image(systemName: "info")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.2))
                        .clipShape(Circle())
                        .glassEffect()
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
                .padding(.top, 25)
                .ignoresSafeArea()
            }
        }
    }
    
    var activeSessionView: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 4)
                        .frame(width: geo.size.width * 0.25, height: geo.size.width * 0.25)
                    Image(systemName: alarmManager.currentMode == .napping ? "moon.zzz.fill" : "alarm.fill")
                        .font(.title)
                        .foregroundColor(.red)
                }
                .padding(.bottom, 10)
                Text(alarmManager.timerString)
                    .font(.system(size: 60, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 1.0, green: 0.1, blue: 0.1))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .padding(.horizontal)
                if let target = alarmManager.targetWakeTime {
                    VStack(spacing: 2) {
                        Text(alarmManager.statusMessage.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)
                        Text("BELL: \(target.formatted(date: .omitted, time: .shortened))")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Color.red.opacity(0.8))
                    }
                }
                Spacer()
                Button(action: { withAnimation { alarmManager.stop() } }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Stop Session").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderless)
                .background(Color.red.opacity(0.15))
                .foregroundColor(.red)
                .clipShape(Capsule())
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}

struct NapButton: View {
    let hours: Double
    let label: String
    let color: Color
    @ObservedObject var manager: AlarmManager
    var body: some View {
        Button(action: { manager.startNap(duration: hours * 3600) }) {
            VStack(spacing: 0) {
                Text(label)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("HRS")
                    .font(.system(size: 8, weight: .bold))
                    .opacity(0.6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .glassEffect()
        .tint(color)
        .clipShape(ContainerRelativeShape())
    }
}
