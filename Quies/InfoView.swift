import SwiftUI

struct InfoView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 32) {
                        headerSection
                        featuresSection
                        howItWorksSection
                        benefitsSection
                        disclaimerSection
                    }
                    .padding()
                }
            }
            .navigationTitle("About Quies")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [.black, .purple.opacity(0.2)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Quies")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundColor(.white)
            
            Text("Your intelligent sleep companion")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.gray)
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Features")
            
            FeatureCard(
                icon: "moon.zzz.fill",
                title: "Power Naps",
                description: "Quick preset timers (1h–2.5h) designed to recharge you without grogginess. Perfect for midday energy boosts.",
                color: .indigo
            )
            
            FeatureCard(
                icon: "alarm.waves.left.and.right.fill",
                title: "Smart Wake",
                description: "Monitors your sleep phases and wakes you during light sleep within 30 minutes of your target time for a refreshed wake-up.",
                color: .orange
            )
            
            FeatureCard(
                icon: "applewatch",
                title: "Watch Integration",
                description: "Seamless synchronization between iPhone and Apple Watch ensures reliable sleep monitoring and alarms.",
                color: .blue
            )
            
            FeatureCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Sleep History",
                description: "Track your naps and wake times over time to understand your sleep patterns and optimize your rest.",
                color: .green
            )
        }
    }
    
    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "How It Works")
            
            VStack(spacing: 12) {
                StepCard(
                    number: 1,
                    title: "Set Your Alarm",
                    description: "Choose a quick nap duration or set a smart alarm for your desired wake time."
                )
                
                StepCard(
                    number: 2,
                    title: "Monitor Sleep",
                    description: "Your Apple Watch monitors your movement and heart rate to detect sleep phases."
                )
                
                StepCard(
                    number: 3,
                    title: "Smart Wake",
                    description: "The alarm activates during light sleep within 30 minutes of your target time for optimal refreshment."
                )
                
                StepCard(
                    number: 4,
                    title: "Backup Alarm",
                    description: "iPhone provides a backup alarm if the watch isn't available, ensuring you never oversleep."
                )
            }
        }
    }
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Benefits")
            
            VStack(spacing: 12) {
                BenefitRow(
                    icon: "bolt.fill",
                    title: "Increased Energy",
                    description: "Wake during light sleep to feel more energized and alert"
                )
                
                BenefitRow(
                    icon: "brain.head.profile",
                    title: "Better Focus",
                    description: "Optimize sleep cycles for improved cognitive function"
                )
                
                BenefitRow(
                    icon: "heart.fill",
                    title: "Health Benefits",
                    description: "Regular power naps support overall health and wellbeing"
                )
                
                BenefitRow(
                    icon: "gauge.with.dots.needle.67percent",
                    title: "Productivity",
                    description: "Strategic rest periods enhance performance throughout the day"
                )
            }
        }
    }
    
    private var disclaimerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("Important Notice")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("Quies is not a medical device and should not be used as your sole alarm method. Always use as a backup aid. Reliability depends on battery life, sensor accuracy, and watch connectivity. Consult healthcare professionals for sleep disorders.")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
                .background(.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(.title2, design: .rounded, weight: .bold))
            .foregroundColor(.white)
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StepCard: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Text("\(number)")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
