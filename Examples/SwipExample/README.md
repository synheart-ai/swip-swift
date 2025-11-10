# SWIP iOS Example App

This example app demonstrates how to integrate and use the SWIP iOS SDK in a real iOS application using SwiftUI.

## Features

- ✅ Session management (start/stop)
- ✅ Real-time SWIP score display
- ✅ Emotion recognition visualization
- ✅ Heart rate and HRV monitoring
- ✅ Session summary and results
- ✅ Modern SwiftUI interface

## Prerequisites

- Xcode 14.0 or newer
- iOS 13.0+ device or simulator
- Apple Developer account (for HealthKit entitlements)

## Setup

1. **Open in Xcode**:
   ```bash
   open sdks/ios/Examples/SwipExample/SwipExample.xcodeproj
   ```

2. **Configure Signing**:
   - Select your development team
   - Enable HealthKit capability
   - Configure bundle identifier

3. **Run**:
   - Select target device/simulator
   - Build and run (⌘R)

4. **Grant Permissions**:
   - When prompted, grant HealthKit permissions
   - Start a session

## How It Works

### 1. Initialize SDK

```swift
let swipManager = SwipSdkManager(
    config: SwipSdkConfig(enableLogging: true)
)

Task {
    try await swipManager.initialize()
    try await swipManager.requestPermissions()
}
```

### 2. Start a Session

```swift
Task {
    let sessionId = try await swipManager.startSession(
        appId: "ai.synheart.swip.example",
        metadata: ["screen": "main"]
    )
}
```

### 3. Subscribe to Scores

```swift
swipManager.scorePublisher
    .receive(on: DispatchQueue.main)
    .sink { score in
        print("SWIP Score: \(score.swipScore)")
        print("Emotion: \(score.dominantEmotion)")
    }
    .store(in: &cancellables)
```

### 4. Stop Session

```swift
Task {
    let results = try await swipManager.stopSession()
    let summary = results.getSummary()
    print("Average Score: \(summary["average_swip_score"])")
}
```

## UI Components

### SessionStatusCard
Shows current session state:
- Active/Idle status
- Session ID (truncated)
- Visual indicator

### ScoreCard
Displays current SWIP score:
- Wellness score (0-100) with color coding
- Dominant emotion with SF Symbol icon
- Confidence percentage
- Heart rate and HRV vitals

### SessionResultsCard
Session summary after completion:
- Duration
- Average score
- Dominant emotion
- Total data points

## SwiftUI Architecture

The app follows MVVM pattern:

- **SwipViewModel**: ObservableObject managing SDK interaction
- **ContentView**: Main UI presenting data
- **Reusable Components**: ScoreCard, VitalChip, etc.

## Testing

### Without Real Data

1. Use iOS Health app to add sample heart rate data
2. Or use Xcode's Health simulation
3. The example app will visualize any data stream

### With Apple Watch

1. Pair Apple Watch
2. Record workout with heart rate
3. Data automatically syncs to HealthKit

## Customization

### Change Theme

Modify colors in each view:
```swift
.foregroundColor(.blue) // Change to your brand color
```

### Add Features

- Export session data to JSON/CSV
- Charts for historical trends
- Multi-session comparisons
- Consent management UI
- Apple Watch companion app

## HealthKit Setup

### Required Entitlements

Add to your `.entitlements` file:
```xml
<key>com.apple.developer.healthkit</key>
<true/>
<key>com.apple.developer.healthkit.background-delivery</key>
<true/>
```

### Info.plist Keys

Already configured in Info.plist:
- `NSHealthShareUsageDescription`
- `NSHealthUpdateUsageDescription`

## Troubleshooting

**HealthKit not available**:
- Use a real device (simulator has limitations)
- Check entitlements are configured
- Verify app signing

**No data flowing**:
- Check if Health app has data
- Verify permissions are granted
- Enable SDK logging to debug
- Try adding sample data in Health app

**Build errors**:
- Clean build folder (⌘⇧K)
- Update package dependencies
- Check minimum deployment target

## License

Apache 2.0 - See LICENSE file
