//
//  QuiesWidget.swift
//  Quies
//
//  Created by Elizbar Kheladze on 29/01/26.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct QuiesWidgetEntry: TimelineEntry {
    let date: Date
    let wakeTime: Date?
    let mode: String
    let isActive: Bool
}

// MARK: - Widget Provider
struct QuiesWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuiesWidgetEntry {
        QuiesWidgetEntry(date: Date(), wakeTime: nil, mode: "napping", isActive: false)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuiesWidgetEntry) -> Void) {
        let entry = loadWidgetData()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuiesWidgetEntry>) -> Void) {
        let entry = loadWidgetData()
        let nextUpdate = Date().addingTimeInterval(30)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    // MARK: - Load Widget Data
    private func loadWidgetData() -> QuiesWidgetEntry {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.quies.watch"),
           let data = sharedDefaults.data(forKey: "QuiesWidgetData"),
           let widgetData = try? JSONDecoder().decode(QuiesWidgetData.self, from: data) {
            return QuiesWidgetEntry(
                date: Date(),
                wakeTime: widgetData.wakeTime,
                mode: widgetData.mode,
                isActive: widgetData.isActive
            )
        }
        return QuiesWidgetEntry(date: Date(), wakeTime: nil, mode: "napping", isActive: false)
    }
}

// MARK: - Widget View
struct QuiesWidgetView: View {
    let entry: QuiesWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if entry.isActive, let wakeTime = entry.wakeTime {
            switch family {
            case .accessoryCorner:
                cornerView(wakeTime: wakeTime)
            case .accessoryCircular:
                circularView(wakeTime: wakeTime)
            case .accessoryRectangular:
                rectangularView(wakeTime: wakeTime)
            default:
                rectangularView(wakeTime: wakeTime)
            }
        } else {
            inactiveView
        }
    }
    
    // MARK: - Corner View
    private func cornerView(wakeTime: Date) -> some View {
        ZStack {
            Image(systemName: entry.mode == "napping" ? "moon.zzz.fill" : "alarm.fill")
                .widgetLabel {
                    Text(wakeTime, style: .time)
                        .fontWeight(.bold)
                }
        }
        .foregroundStyle(.red)
        .containerBackground(.black, for: .widget)
    }
    
    // MARK: - Circular View
    private func circularView(wakeTime: Date) -> some View {
        ZStack {
            Circle()
                .stroke(Color.red.opacity(0.3), lineWidth: 2)
            
            VStack(spacing: 2) {
                Image(systemName: entry.mode == "napping" ? "moon.zzz.fill" : "alarm.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                
                Text(wakeTime, style: .time)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.red)
            }
        }
        .containerBackground(.black, for: .widget)
    }
    
    // MARK: - Rectangular View
    private func rectangularView(wakeTime: Date) -> some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Image(systemName: entry.mode == "napping" ? "moon.zzz.fill" : "alarm.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 14))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(wakeTime, style: .time)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.red)
                
                Text(timeRemainingString(to: wakeTime))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.red.opacity(0.7))
            }
            
            Spacer()
            
            progressCircle(to: wakeTime)
        }
        .containerBackground(.black, for: .widget)
    }
    
    // MARK: - Progress Circle
    private func progressCircle(to wakeTime: Date) -> some View {
        let progress = calculateProgress(to: wakeTime)
        
        return ZStack {
            Circle()
                .stroke(Color.red.opacity(0.2), lineWidth: 3)
                .frame(width: 24, height: 24)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.red, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 24, height: 24)
                .rotationEffect(.degrees(-90))
        }
        .containerBackground(.black, for: .widget)
    }
    
    // MARK: - Inactive View
    private var inactiveView: some View {
        Image(systemName: "moon.stars")
            .foregroundStyle(.gray)
            .containerBackground(.black, for: .widget)
    }
    
    // MARK: - Calculate Progress
    private func calculateProgress(to wakeTime: Date) -> Double {
        let total = wakeTime.timeIntervalSince(Date().addingTimeInterval(-3600))
        let remaining = wakeTime.timeIntervalSince(Date())
        let progress = 1.0 - (remaining / total)
        return min(max(progress, 0), 1)
    }
    
    // MARK: - Time Remaining String
    private func timeRemainingString(to wakeTime: Date) -> String {
        let remaining = wakeTime.timeIntervalSince(Date())
        if remaining <= 0 { return "Time's Up" }
        
        let hours = Int(remaining) / 3600
        let minutes = Int(remaining) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
}

// MARK: - Widget Configuration
struct QuiesWidget: Widget {
    let kind: String = "QuiesWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuiesWidgetProvider()) { entry in
            QuiesWidgetView(entry: entry)
        }
        .configurationDisplayName("Quies Alarm")
        .description("View your active alarm")
        .supportedFamilies([.accessoryCorner, .accessoryCircular, .accessoryRectangular])
    }
}


@main
struct QuiesWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuiesWidget()
    }
}
