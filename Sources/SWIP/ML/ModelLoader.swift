import Foundation

/// ML Model loader for SVM models
public class ModelLoader {

    /// Load SVM model from bundle
    public static func loadSvmModel(modelName: String = "svm_linear_v1_0") -> SvmModel? {
        guard let url = Bundle.module.url(forResource: modelName, withExtension: "json") else {
            print("Model file not found: \(modelName).json")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(SvmModel.self, from: data)
        } catch {
            print("Failed to load model: \(error)")
            return nil
        }
    }
}

/// SVM Model structure matching JSON format
public struct SvmModel: Codable {
    public let type: String
    public let version: String
    public let featureOrder: [String]
    public let scalerMean: [Double]
    public let scalerScale: [Double]
    public let classes: [String]
    public let weights: [[Double]]
    public let bias: [Double]
    public let modelHash: String
    public let exportTimeUtc: String
    public let trainingCommit: String
    public let dataManifestId: String
}
