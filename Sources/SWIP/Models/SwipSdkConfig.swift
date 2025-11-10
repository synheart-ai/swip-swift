import Foundation

/// Configuration for SWIP SDK
public struct SwipSdkConfig {
    public let swipConfig: SwipConfig
    public let emotionConfig: EmotionConfig
    public let enableLogging: Bool
    public let enableLocalStorage: Bool
    public let localStoragePath: String?

    public init(
        swipConfig: SwipConfig = SwipConfig(),
        emotionConfig: EmotionConfig = EmotionConfig(),
        enableLogging: Bool = true,
        enableLocalStorage: Bool = true,
        localStoragePath: String? = nil
    ) {
        self.swipConfig = swipConfig
        self.emotionConfig = emotionConfig
        self.enableLogging = enableLogging
        self.enableLocalStorage = enableLocalStorage
        self.localStoragePath = localStoragePath
    }
}

/// Configuration for SWIP Score computation
public struct SwipConfig {
    public let weightHrv: Double
    public let weightCoherence: Double
    public let weightRecovery: Double
    public let beneficialThreshold: Double
    public let harmfulThreshold: Double

    public init(
        weightHrv: Double = 0.5,
        weightCoherence: Double = 0.3,
        weightRecovery: Double = 0.2,
        beneficialThreshold: Double = 0.2,
        harmfulThreshold: Double = -0.2
    ) {
        self.weightHrv = weightHrv
        self.weightCoherence = weightCoherence
        self.weightRecovery = weightRecovery
        self.beneficialThreshold = beneficialThreshold
        self.harmfulThreshold = harmfulThreshold
    }
}

/// Configuration for Emotion Recognition
public struct EmotionConfig {
    public let modelPath: String?
    public let useOnDeviceModel: Bool
    public let confidenceThreshold: Double

    public init(
        modelPath: String? = nil,
        useOnDeviceModel: Bool = true,
        confidenceThreshold: Double = 0.6
    ) {
        self.modelPath = modelPath
        self.useOnDeviceModel = useOnDeviceModel
        self.confidenceThreshold = confidenceThreshold
    }

    public static let defaultConfig = EmotionConfig()
}

/// Session configuration
public struct SWIPSessionConfig {
    public let appId: String
    public let metadata: [String: Any]

    public init(appId: String, metadata: [String: Any] = [:]) {
        self.appId = appId
        self.metadata = metadata
    }
}
