import Foundation

enum Transcriber {
    static var whisperPath: String {
        Bundle.main.executableURL?.deletingLastPathComponent()
            .appendingPathComponent("whisper-cli").path
            ?? "/opt/homebrew/bin/whisper-cli"
    }

    static var modelPath: String {
        ModelManager.modelPath.path
    }

    /// Transcribes a WAV file using whisper-cpp. Runs synchronously — call from a background thread.
    /// If deleteAfter is true, the file is deleted after transcription.
    static func transcribe(fileURL: URL, deleteAfter: Bool = true) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: whisperPath)
        process.arguments = [
            "--model", modelPath,
            "--no-timestamps",
            "--language", "en",
            "--threads", "8",
            fileURL.path
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            var trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.hasPrefix("[") || trimmed.hasPrefix("(") {
                trimmed = ""
            }

            if deleteAfter {
                try? FileManager.default.removeItem(at: fileURL)
            }

            print("Transcription: \(trimmed)")
            return trimmed
        } catch {
            print("Transcription failed: \(error)")
            if deleteAfter {
                try? FileManager.default.removeItem(at: fileURL)
            }
            return ""
        }
    }
}
