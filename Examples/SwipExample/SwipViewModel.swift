import Foundation
import Combine
import SWIP

@MainActor
class SwipViewModel: ObservableObject {
    @Published var sessionActive = false
    @Published var currentScore: SwipScoreResult?
    @Published var sessionId: String?
    @Published var sessionResults: SwipSessionResults?
    @Published var error: Error?

    private let swipManager: SwipSdkManager
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.swipManager = SwipSdkManager(
            config: SwipSdkConfig(enableLogging: true)
        )

        // Initialize SDK
        Task {
            do {
                try await swipManager.initialize()
                try await swipManager.requestPermissions()
            } catch {
                self.error = error
                print("Failed to initialize SWIP: \(error)")
            }
        }
    }

    func startSession() async {
        do {
            let id = try await swipManager.startSession(
                appId: "ai.synheart.swip.example",
                metadata: ["screen": "main"]
            )

            sessionId = id
            sessionActive = true
            sessionResults = nil

            // Subscribe to scores
            swipManager.scorePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] score in
                    self?.currentScore = score
                }
                .store(in: &cancellables)

        } catch {
            self.error = error
            print("Failed to start session: \(error)")
        }
    }

    func stopSession() async {
        do {
            let results = try await swipManager.stopSession()

            sessionResults = results
            sessionActive = false
            currentScore = nil
            cancellables.removeAll()

        } catch {
            self.error = error
            print("Failed to stop session: \(error)")
        }
    }
}
