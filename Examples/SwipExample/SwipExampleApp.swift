import SwiftUI
import SWIP

@main
struct SwipExampleApp: App {
    @StateObject private var viewModel = SwipViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var viewModel: SwipViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Session Status Card
                SessionStatusCard(
                    isActive: viewModel.sessionActive,
                    sessionId: viewModel.sessionId
                )

                // Current Score Card
                if let score = viewModel.currentScore {
                    ScoreCard(score: score)
                } else if !viewModel.sessionActive {
                    PlaceholderCard()
                }

                Spacer()

                // Session Controls
                if !viewModel.sessionActive {
                    Button(action: {
                        Task { await viewModel.startSession() }
                    }) {
                        Label("Start Session", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button(action: {
                        Task { await viewModel.stopSession() }
                    }) {
                        Label("Stop Session", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .controlSize(.large)
                }

                // Session Results
                if let results = viewModel.sessionResults {
                    SessionResultsCard(results: results)
                }
            }
            .padding()
            .navigationTitle("SWIP SDK Example")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
}

struct SessionStatusCard: View {
    let isActive: Bool
    let sessionId: String?

    var body: some View {
        GroupBox {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Session Status")
                        .font(.headline)
                    Text(isActive ? "Active" : "Idle")
                        .font(.title2)
                        .fontWeight(.bold)
                    if let id = sessionId {
                        Text("ID: \(String(id.prefix(8)))...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: isActive ? "waveform.path.ecg" : "circle")
                    .font(.system(size: 40))
                    .foregroundColor(isActive ? .green : .secondary)
            }
        }
    }
}

struct ScoreCard: View {
    let score: SwipScoreResult

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                Text("Current SWIP Score")
                    .font(.headline)

                // Score Display
                HStack(alignment: .firstTextBaseline) {
                    Text(String(format: "%.1f", score.swipScore))
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor(score.swipScore))

                    Spacer()
                }

                // Emotion
                HStack(spacing: 12) {
                    Image(systemName: emotionIcon(score.dominantEmotion))
                        .font(.title)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading) {
                        Text("Emotion: \(score.dominantEmotion)")
                            .font(.body)
                        Text("Confidence: \(String(format: "%.1f%%", score.confidence * 100))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // Vitals
                HStack(spacing: 32) {
                    VitalChip(
                        label: "HR",
                        value: String(format: "%.0f", score.heartRate),
                        unit: "BPM"
                    )

                    VitalChip(
                        label: "HRV",
                        value: String(format: "%.0f", score.hrv),
                        unit: "ms"
                    )
                }
            }
        }
    }

    func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }

    func emotionIcon(_ emotion: String) -> String {
        switch emotion.lowercased() {
        case "amused": return "face.smiling"
        case "calm": return "heart.fill"
        case "stressed": return "exclamationmark.triangle"
        default: return "info.circle"
        }
    }
}

struct VitalChip: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SessionResultsCard: View {
    let results: SwipSessionResults

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text("Session Complete!")
                    .font(.headline)
                    .fontWeight(.bold)

                let summary = results.getSummary()

                Text("Duration: \(summary["duration_seconds"] as? TimeInterval ?? 0, specifier: "%.0f") seconds")
                Text("Average Score: \(String(format: "%.1f", summary["average_swip_score"] as? Double ?? 0))")
                Text("Dominant Emotion: \(summary["dominant_emotion"] as? String ?? "Unknown")")
                Text("Total Scores: \(summary["score_count"] as? Int ?? 0)")
            }
        }
        .backgroundStyle(.green.opacity(0.1))
    }
}

struct PlaceholderCard: View {
    var body: some View {
        GroupBox {
            VStack(spacing: 16) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)

                Text("Start a session to see SWIP scores")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SwipViewModel())
    }
}
