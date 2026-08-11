import Foundation
import Vision

struct RecognizedLine: Codable {
    let text: String
    let confidence: Float
    let x: Double
    let y: Double
}

@main
struct VisionOCR {
    static func main() async throws {
        let arguments = CommandLine.arguments
        guard arguments.count == 7,
              arguments[1] == "--input-dir",
              arguments[3] == "--text-dir",
              arguments[5] == "--json-dir" else {
            FileHandle.standardError.write(
                Data(
                    "usage: vision_ocr --input-dir pages --text-dir text --json-dir json\n".utf8
                )
            )
            Foundation.exit(2)
        }

        let fileManager = FileManager.default
        let inputDirectory = URL(fileURLWithPath: arguments[2], isDirectory: true)
        let textDirectory = URL(fileURLWithPath: arguments[4], isDirectory: true)
        let jsonDirectory = URL(fileURLWithPath: arguments[6], isDirectory: true)
        try fileManager.createDirectory(
            at: textDirectory,
            withIntermediateDirectories: true
        )
        try fileManager.createDirectory(
            at: jsonDirectory,
            withIntermediateDirectories: true
        )

        let images = try fileManager.contentsOfDirectory(
            at: inputDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension.lowercased() == "png" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        for source in images {
            let lines = try await recognize(source)
            let stem = source.deletingPathExtension().lastPathComponent
            let text = lines.map(\.text).joined(separator: "\n") + "\n"
            try text.write(
                to: textDirectory.appendingPathComponent("\(stem).txt"),
                atomically: true,
                encoding: .utf8
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            try encoder.encode(lines).write(
                to: jsonDirectory.appendingPathComponent("\(stem).json"),
                options: .atomic
            )
            let average = lines.isEmpty
                ? 0
                : lines.reduce(0) { $0 + Double($1.confidence) } / Double(lines.count)
            print("\(stem)\t\(lines.count)\t\(String(format: "%.3f", average))")
        }
    }

    private static func recognize(_ source: URL) async throws -> [RecognizedLine] {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = false
        request.recognitionLanguages = [
            Locale.Language(identifier: "zh-Hant"),
            Locale.Language(identifier: "en-US"),
        ]
        request.minimumTextHeightFraction = 0.005

        let observations = try await request.perform(on: source)
        let sorted = observations.sorted { lhs, rhs in
            let lhsTop = lhs.topLeft.y
            let rhsTop = rhs.topLeft.y
            if abs(lhsTop - rhsTop) > 0.008 {
                return lhsTop > rhsTop
            }
            return lhs.topLeft.x < rhs.topLeft.x
        }
        return sorted.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            return RecognizedLine(
                text: candidate.string,
                confidence: candidate.confidence,
                x: observation.topLeft.x,
                y: observation.topLeft.y
            )
        }
    }
}
