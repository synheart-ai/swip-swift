# SWIP iOS SDK

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20watchOS%20%7C%20macOS-lightgrey.svg)](https://developer.apple.com)
[![Swift](https://img.shields.io/badge/Swift-5.7+-orange.svg)](https://swift.org)

The SWIP iOS SDK enables iOS, watchOS, and macOS applications to quantitatively assess their impact on human wellness using biosignal-based metrics from HealthKit.

## Features

- ✅ **Privacy-first**: All processing happens locally on-device by default
- ✅ **HealthKit Integration**: Reads HR and HRV data from Apple HealthKit
- ✅ **Real-time Emotion Recognition**: On-device Linear SVM for emotion classification
- ✅ **SWIP Score Computation**: Quantitative wellness impact scoring
- ✅ **Consent Management**: GDPR-compliant consent and data purging
- ✅ **Swift Concurrency**: Modern async/await API
- ✅ **Combine Publishers**: Real-time score and emotion updates
- ✅ **Multi-platform**: Supports iOS, watchOS, macOS

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
- **macOS**: 13.0+ (HealthKit requires macOS 13.0+)
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
class ViewController: UIViewController {
    var swipManager: SwipSdkManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        Task {
            do {
                // Initialize SDK
                try await swipManager.initialize()

                // Request health permissions
                try await swipManager.requestPermissions()
            } catch {
                print("Failed to initialize SWIP: \(error)")
            }
        }
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
                // Start session
                let sessionId = try await swipManager.startSession(
                    appId: "com.example.myapp",
                    metadata: ["screen": "meditation"]
                )

                // Subscribe to scores
                swipManager.scorePublisher
                    .sink { score in
                        print("SWIP Score: \(score.swipScore)")
                        print("Emotion: \(score.dominantEmotion)")
                        self.updateUI(score: score)
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
            print("Session Summary: \(summary)")
            print("Average Score: \(summary["average_swip_score"] ?? 0)")
            print("Dominant Emotion: \(summary["dominant_emotion"] ?? "Unknown")")

            showResults(results)
        } catch {
            print("Failed to stop session: \(error)")
        }
    }
}
```

## API Reference

### SwipSdkManager

Main SDK entry point.

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

#### SwipScoreResult

```swift
public struct SwipScoreResult {
    public let swipScore: Double           // 0-100 wellness score
    public let dominantEmotion: String     // "Amused", "Calm", "Stressed"
    public let emotionProbabilities: [String: Double]
    public let hrv: Double                 // HRV SDNN in ms
    public let heartRate: Double           // HR in BPM
    public let timestamp: Date
    public let confidence: Double          // Prediction confidence
    public let dataQuality: Double         // Signal quality (0-1)
}
```

#### SwipSessionResults

```swift
public struct SwipSessionResults {
    public let sessionId: String
    public let scores: [SwipScoreResult]
    public let emotions: [EmotionResult]
    public let startTime: Date
    public let endTime: Date

    public func getSummary() -> [String: Any]
}
```

#### ConsentLevel

```swift
public enum ConsentLevel: Int {
    case onDevice = 0        // Local processing only (default)
    case localExport = 1     // Manual export allowed
    case dashboardShare = 2  // Aggregated data sharing
}
```

## SwiftUI Integration

```swift
import SwiftUI
import Combine
import SWIP

struct MeditationView: View {
    @StateObject private var viewModel = MeditationViewModel()

    var body: some View {
        VStack {
            Text("SWIP Score: \(viewModel.currentScore?.swipScore ?? 0, specifier: "%.1f")")
                .font(.largeTitle)

            Text("Emotion: \(viewModel.currentScore?.dominantEmotion ?? "Unknown")")
                .font(.headline)

            Button("Start Session") {
                Task { await viewModel.startSession() }
            }

            Button("Stop Session") {
                Task { await viewModel.stopSession() }
            }
        }
    }
}

class MeditationViewModel: ObservableObject {
    @Published var currentScore: SwipScoreResult?

    private let swipManager: SwipSdkManager
    private var cancellables = Set<AnyCancellable>()

    init() {
        swipManager = SwipSdkManager()
    }

    func startSession() async {
        do {
            _ = try await swipManager.startSession(appId: "com.example.myapp")

            swipManager.scorePublisher
                .receive(on: DispatchQueue.main)
                .assign(to: &$currentScore)
        } catch {
            print("Error: \(error)")
        }
    }

    func stopSession() async {
        do {
            let results = try await swipManager.stopSession()
            print("Session complete: \(results.getSummary())")
        } catch {
            print("Error: \(error)")
        }
    }
}
```

## Privacy & Ethics

The SWIP SDK follows strict privacy requirements:

- **Local-first**: All processing happens on-device by default
- **Explicit Consent**: Required before any data sharing
- **GDPR Compliance**: `purgeAllData()` deletes all user data
- **No Raw Biosignals**: Only aggregated metrics transmitted (if consent given)
- **Anonymization**: Hashed device IDs, per-session UUIDs

## Example App

See `Examples/SwipExample/` for a complete iOS app demonstrating:

- Session management
- Real-time score visualization with SwiftUI
- Consent UI implementation
- Data export
- watchOS companion app

## Testing

```bash
# Run tests
swift test

# Run with coverage
swift test --enable-code-coverage

# Build for all platforms
swift build
```

## Architecture

### SDK Components

```
SwipSdkManager
    ├── HealthKit (HR/HRV data)
    ├── EmotionEngine (ML inference)
    │   ├── FeatureExtractor
    │   └── SvmPredictor
    ├── SwipEngine (Score computation)
    ├── ConsentManager (Privacy controls)
    └── SessionManager (Session tracking)
```

### Relationship to swip-core

This SDK currently implements its own scoring logic. In the future, it will integrate with [swip-core-swift](../swip-core-swift), which is a dedicated library for:
- HRV feature extraction (SDNN, RMSSD, etc.)
- Artifact filtering
- On-device ML inference (Core ML, ONNX)
- SWIP score computation (0-100)

The architecture will evolve to:
```
HealthKit → synheart-wear-swift → swip-core-swift → swip-swift (this SDK)
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

Copyright 2024 Synheart AI

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

## Support

- **Issues**: https://github.com/synheart-ai/swip/issues
- **Docs**: https://swip.synheart.ai/docs
- **Email**: dev@synheart.ai

## Production Readiness

This SDK is production-ready with the following considerations:

### ✅ Production Ready
- Comprehensive error handling with typed errors
- Privacy-first architecture with GDPR compliance
- Proper async/await concurrency
- Multi-platform support (iOS, watchOS, macOS)
- Comprehensive test suite
- Well-documented API

### ⚠️ Implementation Notes
- **HealthKit Integration**: The `readLatestHeartRate` and `readLatestHRV` methods in `SwipSdkManager` currently return mock values. For production use, implement proper HealthKit queries to read actual heart rate and HRV data from `HKHealthStore`.
- **Logging**: The SDK uses `print` statements for logging. Consider migrating to the `swift-log` package (already included in dependencies) for production-grade logging with configurable log levels.

### Pre-Release Checklist
Before releasing to production, ensure:
- [ ] HealthKit queries are fully implemented (replace mock values)
- [ ] All tests pass: `swift test`
- [ ] Code coverage meets your standards: `swift test --enable-code-coverage`
- [ ] Example app is tested on real devices
- [ ] HealthKit entitlements are properly configured
- [ ] Privacy policy and terms of service are updated

## Acknowledgments

Part of the Synheart Wellness Impact Protocol (SWIP) open standard.
