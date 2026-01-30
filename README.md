# Quies

A smart alarm app for Apple Watch that wakes you during light sleep instead of jarring you awake at the worst possible moment.

## The Problem

Ever notice how sometimes your alarm goes off and you feel like you got hit by a truck, but other times you wake up feeling great? That's because sleep cycles matter. Waking up during deep sleep = terrible morning. Waking up during light sleep = actually feeling refreshed.

Most alarm apps just go off at the exact time you set. Quies monitors your movement during the last 30 minutes before your alarm and wakes you up when you're in light sleep. If you don't hit light sleep, it wakes you at your set time anyway (we're not monsters).

## Features

**Quick Naps**
Preset timers for 1, 1.5, 2, and 2.5 hour naps. Tap a button and you're done. The app monitors the last 30 minutes and wakes you during light sleep or at the end time, whichever comes first.

**Smart Alarm**
Set a wake time (like 7:00 AM) and the app handles the rest. It'll start monitoring at 6:30 AM and wake you during light sleep within that 30-minute window, or at 7:00 if you're sleeping like a rock.

**Watch Complications**
Your alarm shows up on your watch face. Available in three styles:
- Corner: Small icon with time
- Circular: Icon with time in a circle
- Rectangular: Full display with countdown

All use the same red theme as the main app because consistency matters.

## How It Works

### Movement Detection
Uses the watch's accelerometer to detect movement. When you're in deep sleep, you barely move. During light sleep and REM, you move around more. The app tracks this and identifies the best wake-up window.

### The 30-Minute Window
- Set alarm for 7:00 AM
- App starts monitoring at 6:30 AM
- Detects light sleep at 6:47 AM
- Wakes you up at 6:47 AM
- You feel way better than waking up at 7:00

If you don't hit light sleep during that window, it wakes you at 7:00 anyway. The goal is to catch light sleep, not make you late.

### Battery Strategy
The app is designed to be lightweight:
- **Before monitoring starts**: Nearly zero battery usage (one check per hour)
- **Last 30 minutes**: Normal monitoring (similar to a workout app)
- **Overall**: Minimal overnight drain

### Why It Won't Die Overnight

Earlier versions had a problem where watchOS would kill the app during long alarms. We fixed this with a layered approach:

1. **Keep-alive timer**: Updates the widget every hour so watchOS knows we're still alive
2. **Background task**: Scheduled 35 minutes before wake time
3. **Silent notification**: Backup at 30 minutes before
4. **Backup alarm**: Loud notification at exact time if everything else fails

It's like having four alarm clocks. If one fails, the others have your back.

## Setup

### Requirements
- Apple Watch Series 4 or newer
- watchOS 11.0 or later
- Motion & Fitness permissions
- Health permissions (optional, for sleep data)
- Notification permissions (for backup alarms)

### Installation
1. Build and run the Xcode project
2. Grant permissions when prompted (motion, health, notifications)
3. Add the Quies complication to your watch face (optional but recommended)

### App Group Configuration
The watch app and widget share data via an App Group. You need to set this up in Xcode:

**Watch App Target:**
1. Signing & Capabilities → Add "App Groups"
2. Create group: `group.com.quies.watch`
3. Enable it (checkmark)

**Widget Extension Target:**
1. Signing & Capabilities → Add "App Groups"
2. Select the same group: `group.com.quies.watch`
3. Enable it (checkmark)

Without this, the widget won't work. With it, your alarm shows up on your watch face.

## Technical Details

### Architecture
- **AlarmManager**: Core logic for alarm scheduling, movement monitoring, session management
- **BioSensors**: Accelerometer data processing and movement scoring
- **WidgetManager**: Updates watch complications via shared UserDefaults
- **PermissionManager**: Handles motion and health permissions
- **QuiesWidget**: Watch complication in three sizes

### Extended Runtime Sessions
The app uses `WKExtendedRuntimeSession` to stay active during the monitoring window. This is a watchOS API specifically designed for apps that need to run for extended periods (like workout apps).

Sessions can run for several hours but aren't guaranteed forever. That's why we have the layered backup system.

### Movement Scoring
The accelerometer reports x, y, z acceleration values at 10 Hz. We calculate the magnitude and compare it to gravity (1.0). Movement above a threshold (0.15) indicates light sleep.

The threshold was determined through testing with actual sleep data. Too sensitive and it wakes you from any slight movement. Too insensitive and it misses light sleep windows.

### Notification Strategy
Three types of notifications:
1. **Silent wake notification** (30 min before): Wakes the app if background task fails
2. **Backup alarm** (exact time): Loud sound if everything else fails
3. All marked as `timeSensitive` to bypass Do Not Disturb

## Project Structure

```
Quies/
├── Watch App/
│   ├── QuiesApp.swift           # App entry point, notification delegate
│   ├── ContentView.swift         # Main UI with nap buttons and alarm picker
│   ├── AlarmManager.swift        # Core alarm logic
│   ├── BioSensor.swift          # Movement detection
│   ├── WidgetManager.swift       # Widget data management
│   ├── PermissionManager.swift   # Permission handling
│   ├── PermissionView.swift      # Permission request UI
│   ├── OnboardingView.swift      # First-run walkthrough
│   └── SettingsManager.swift     # App settings (unused currently)
│
└── Widget Extension/
    ├── QuiesWidget.swift         # Complication views
    └── QuiesWidgetAttributes.swift # Widget data structure
```

## Known Issues

### Background Tasks Aren't Guaranteed
watchOS background tasks are "best effort" - the system decides if and when they run based on battery level, usage patterns, and other factors. That's why we have the notification fallback.

### Notifications Don't Auto-Launch App
On watchOS, unlike iOS, notifications don't automatically relaunch killed apps. The notification will fire with sound, but you need to tap it to open the app. This is standard watchOS behavior.

### Extended Sessions Can Expire
If the watch is off your wrist for too long or battery gets very low, watchOS may terminate the extended runtime session early. The backup alarm will still fire.

## Testing

### Quick Test (2 minutes)
1. Set alarm for 2 minutes from now
2. Check Console logs - should see confirmation messages
3. Wait with watch on wrist
4. Should trigger alarm

### Overnight Test
1. Set alarm for 7+ hours in the future
2. Keep watch on charger (recommended)
3. Check Console in the morning
4. Should see keep-alive ticks every hour
5. Should wake you at the right time

### Force Kill Test
1. Set alarm for 5 minutes from now
2. Force quit the app
3. Wait
4. Notification should still fire (sound + banner)

## Debugging

Console logs are your friend. Look for:
- `✅` Good things happening
- `⚠️` Warnings (non-critical issues)
- `❌` Errors (things that failed)
- `🔄` Background tasks firing
- `⏰` Keep-alive timer ticks
- `📬` Notification events

Common issues:
- "App Group NOT accessible" → Check capabilities configuration
- "Failed to schedule notification" → Check notification permissions
- Session invalidated early → Watch off wrist or low battery

## Future Ideas

Things that might be worth adding:
- Sleep quality tracking over time
- Custom monitoring window lengths (15 min? 45 min?)
- Smart snooze that waits for next light sleep
- Integration with Apple Health sleep data
- Different haptic patterns for different alarm types
- Sunrise simulation using watch brightness

## Credits

Built by someone who was tired of waking up tired. If this app helps you wake up feeling better, that's all the credit needed.

also special thanks to Alfonos & Matteo, who are Mentors at Apple Developer Academy Napoli, they provided guidance and much needed feedback 

## License

Do whatever you want with this code. Make it better. Make it worse. Make it play Sandstorm when the alarm goes off. I'm not your boss.

## Disclaimer

This is not a medical device. Don't rely on it for critical wake-ups like catching a flight. Set a backup alarm on your phone if it really matters. The app does its best but watchOS can be unpredictable.

Also, if you sleep through all four layers of alarms (keep-alive, background task, notification, backup), that's impressive and you might want to talk to a doctor about sleep issues.
