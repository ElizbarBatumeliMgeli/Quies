import SwiftUI
import Charts

struct HistoryView: View {
    @StateObject private var history = AlarmHistory()
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 24) {
                        if !history.entries.isEmpty {
                            statisticsSection
                            chartSection
                            historyListSection
                        } else {
                            emptyStateView
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Sleep History")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [.black, .blue.opacity(0.2)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            Text("Statistics")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(
                    title: "Total Alarms",
                    value: "\(history.statistics.totalAlarms)",
                    icon: "bell.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Success Rate",
                    value: String(format: "%.0f%%", history.statistics.successRate),
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Naps",
                    value: "\(history.statistics.totalNaps)",
                    icon: "moon.zzz.fill",
                    color: .indigo
                )
                
                StatCard(
                    title: "Smart Alarms",
                    value: "\(history.statistics.totalSmartAlarms)",
                    icon: "alarm.fill",
                    color: .orange
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Overview")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)
            
            if #available(iOS 26.0, *) {
                Chart(history.entries.prefix(7)) { entry in
                    BarMark(
                        x: .value("Date", entry.wakeTime, unit: .day),
                        y: .value("Duration", entry.napDuration ?? 0)
                    )
                    .foregroundStyle(entry.mode == .nap ? .indigo : .orange)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.day())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }
    
    private var historyListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ForEach(history.entries) { entry in
                HistoryCard(entry: entry)
                    .padding(.horizontal)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("No History Yet")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(.white)
            
            Text("Your sleep sessions will appear here")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct HistoryCard: View {
    let entry: AlarmHistoryEntry
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(modeColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: modeIcon)
                    .foregroundColor(modeColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.mode == .nap ? "Nap" : "Smart Alarm")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.white)
                
                Text(entry.wakeTime, style: .time)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: entry.wasSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(entry.wasSuccessful ? .green : .red)
                
                Text(entry.wakeTime, style: .date)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var modeIcon: String {
        entry.mode == .nap ? "moon.zzz.fill" : "alarm.fill"
    }
    
    private var modeColor: Color {
        entry.mode == .nap ? .indigo : .orange
    }
}
