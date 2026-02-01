import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            TabView(selection: $currentPage) {
                WelcomePage()
                    .tag(0)
                
                NapsPage()
                    .tag(1)
                
                SmartAlarmPage()
                    .tag(2)
                
                WatchPage()
                    .tag(3)
                
                DisclaimerPage()
                    .tag(4)
                
                GetStartedPage(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .tag(5)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [.black, .black],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse)
            
            VStack(spacing: 12) {
                Text("Welcome to Quies")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Your intelligent companion for better rest and energized wake-ups")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Text("Swipe to continue")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray)
                .padding(.bottom, 20)
        }
    }
}

struct NapsPage: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.indigo, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.bounce)
            
            VStack(spacing: 12) {
                Text("Power Naps")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Quick preset timers (1h–2.5h) designed to recharge you without grogginess. Perfect for midday energy boosts.")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

struct SmartAlarmPage: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "alarm.waves.left.and.right.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.variableColor.iterative)
            
            VStack(spacing: 12) {
                Text("Smart Wake")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Detects your lightest sleep phase within 30 minutes of your target time to wake you gently and naturally.")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

struct WatchPage: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "applewatch.watchface")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse)
            
            VStack(spacing: 12) {
                Text("Apple Watch Required")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Quies works with your Apple Watch to monitor sleep phases. Your iPhone provides backup alarms for added reliability.")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "1.circle.fill")
                        .foregroundColor(.blue)
                    Text("Pair your Apple Watch")
                        .font(.system(.callout, design: .rounded))
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "2.circle.fill")
                        .foregroundColor(.blue)
                    Text("Install Quies on Watch")
                        .font(.system(.callout, design: .rounded))
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "3.circle.fill")
                        .foregroundColor(.blue)
                    Text("Keep devices nearby")
                        .font(.system(.callout, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

struct DisclaimerPage: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            VStack(spacing: 12) {
                Text("Important Notice")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Quies is not a medical device and should be used as a backup aid only. Reliability depends on battery life, sensor accuracy, and device connectivity.")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 12) {
                WarningRow(text: "Not for critical wake-ups")
                WarningRow(text: "Requires charged devices")
                WarningRow(text: "Sensors may vary in accuracy")
                WarningRow(text: "Consult professionals for sleep issues")
            }
            .padding()
            .background(.yellow.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

struct WarningRow: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.yellow)
            Text(text)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.white)
            Spacer()
        }
    }
}

struct GetStartedPage: View {
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 12) {
                    Text("You're All Set!")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Start using Quies to optimize your sleep and wake cycles")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    hasCompletedOnboarding = true
                }
            }) {
                HStack {
                    Text("Get Started")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}
