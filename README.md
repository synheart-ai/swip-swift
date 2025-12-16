# SWIP iOS SDK

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20watchOS%20%7C%20macOS-lightgrey.svg)](https://developer.apple.com)
[![Swift](https://img.shields.io/badge/Swift-5.7+-orange.svg)](https://swift.org)

**Quantify your app's impact on human wellness using real-time biosignals and emotion inference**

## Features

- **🔒 Privacy-First**: All processing happens locally on-device by default
- **📱 Biosignal Collection**: Uses synheart-wear-swift to read HR and HRV from HealthKit
- **🧠 Emotion Recognition**: On-device emotion classification from biosignals
- **📊 SWIP Score**: Quantitative wellness impact scoring (0-100)
- **🔐 GDPR Compliant**: User consent management and data purging
- **⚡ Swift Concurrency**: Modern async/await API
- **🔄 Combine Publishers**: Real-time score and emotion updates
- **📲 Multi-Platform**: iOS, watchOS, macOS support

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/synheart-ai/swip.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Packages...
2. Enter: `https://github.com/synheart-ai/swip.git`
3. Select version: 1.0.0+

### CocoaPods

```ruby
pod 'SWIP', '~> 1.0'
```

## Requirements

- **iOS**: 13.0+
- **watchOS**: 6.0+
- **macOS**: 13.0+
- **Swift**: 5.7+
- **Xcode**: 14.0+

## Quick Start

### 1. Configure HealthKit Permissions

Add to your `Info.plist`:

```xml
<key>NSHealthShareUsageDescription</key>
<string>We need access to your heart rate data to measure wellness impact.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>We track wellness metrics to improve your experience.</string>
```

### 2. Initialize the SDK

```swift
import SWIP

class AppDelegate: UIResponder, UIApplicationDelegate {
    var swipManager: SwipSdkManager!

    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        swipManager = SwipSdkManager(
            config: SwipSdkConfig(
                enableLogging: true
            )
        )

        return true
    }
}
```

### 3. Request Permissions

```swift
Task {
    do {
        try await swipManager.initialize()
        try await swipManager.requestPermissions()
    } catch {
        print("Failed to initialize SWIP: \(error)")
    }
}
```

### 4. Start a Session

```swift
import Combine

class MeditationViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()

    func startMeditation() {
        Task {
            do {
                let sessionId = try await swipManager.startSession(
                    appId: "com.example.myapp",
                    metadata: ["screen": "meditation"]
                )

                swipManager.scorePublisher
                    .sink { score in
                        print("SWIP Score: \(score.swipScore)")
                        print("Emotion: \(score.dominantEmotion)")
                    }
                    .store(in: &cancellables)
            } catch {
                print("Session error: \(error)")
            }
        }
    }
}
```

### 5. Stop a Session

```swift
func stopMeditation() {
    Task {
        do {
            let results = try await swipManager.stopSession()
            let summary = results.getSummary()

            print("Average Score: \(summary["average_swip_score"] ?? 0)")
            print("Dominant Emotion: \(summary["dominant_emotion"] ?? "Unknown")")
        } catch {
            print("Failed to stop session: \(error)")
        }
    }
}
```

## API Reference

### SwipSdkManager

#### Methods

- `func initialize() async throws` - Initialize the SDK
- `func requestPermissions() async throws` - Request HealthKit permissions
- `func startSession(appId: String, metadata: [String: Any]) async throws -> String` - Start a session
- `func stopSession() async throws -> SwipSessionResults` - Stop the current session
- `func getCurrentScore() -> SwipScoreResult?` - Get current SWIP score
- `func getCurrentEmotion() -> EmotionResult?` - Get current emotion
- `func setUserConsent(level: ConsentLevel, reason: String) async throws` - Set consent level
- `func getUserConsent() -> ConsentLevel` - Get current consent level
- `func purgeAllData() async throws` - Delete all user data (GDPR compliance)

#### Publishers

- `scorePublisher: AnyPublisher<SwipScoreResult, Never>` - Real-time SWIP scores (~1 Hz)
- `emotionPublisher: AnyPublisher<EmotionResult, Never>` - Real-time emotion predictions

### Models

```swift
public struct SwipScoreResult {
    public let swipScore: Double           // 0-100 wellness score
    public let dominantEmotion: String     // "Calm", "Stressed", etc.
    public let emotionProbabilities: [String: Double]
    public let hrv: Double                 // HRV SDNN in ms
    public let heartRate: Double           // HR in BPM
    public let timestamp: Date
    public let confidence: Double
    public let dataQuality: Double
}

public enum ConsentLevel: Int {
    case onDevice = 0        // Local processing only (default)
    case localExport = 1     // Manual export allowed
    case dashboardShare = 2  // Aggregated data sharing
}
```

## Architecture

```
HealthKit → synheart-wear-swift → swip-core-swift → swip-swift
```

The SDK uses:
- **synheart-wear-swift** for biosignal collection from HealthKit
- **swip-core-swift** for HRV feature extraction and SWIP score computation
- **Internal emotion engine** for on-device emotion classification

## Privacy

- **Local-first**: All processing happens on-device by default
- **Explicit Consent**: Required before any data sharing
- **GDPR Compliance**: `purgeAllData()` deletes all user data
- **No Raw Biosignals**: Only aggregated metrics transmitted (if consent given)
- **Anonymization**: Hashed device IDs, per-session UUIDs

## Testing

```bash
# Run tests
swift test

# Run with coverage
swift test --enable-code-coverage

# Build for all platforms
swift build
```

## License

Copyright 2024 Synheart AI

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

## Support

- **Issues**: https://github.com/synheart-ai/swip/issues
- **Docs**: https://swip.synheart.ai/docs
- **Email**: dev@synheart.ai

---

Part of the Synheart Wellness Impact Protocol (SWIP) open standard.

## Patent Pending Notice

This project is provided under an open-source license. Certain underlying systems, methods, and architectures described or implemented herein may be covered by one or more pending patent applications.

Nothing in this repository grants any license, express or implied, to any patents or patent applications, except as provided by the applicable open-source license.
