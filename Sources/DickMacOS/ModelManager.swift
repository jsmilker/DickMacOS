import Foundation

enum ModelManager {
    static let defaultModelName = "ggml-medium.bin"
    static let defaultModelURL = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin"

    static var modelName: String {
        ProcessInfo.processInfo.environment["WHISPER_MODEL_PATH"].map { URL(fileURLWithPath: $0).lastPathComponent }
            ?? defaultModelName
    }

    static var modelDir: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("WhisperDictation")
    }

    static var modelPath: URL {
        if let customPath = ProcessInfo.processInfo.environment["WHISPER_MODEL_PATH"] {
            return URL(fileURLWithPath: customPath)
        }
        return modelDir.appendingPathComponent(modelName)
    }

    static var modelURL: String {
        ProcessInfo.processInfo.environment["WHISPER_MODEL_PATH"] ?? defaultModelURL
    }

    static var modelExists: Bool {
        FileManager.default.fileExists(atPath: modelPath.path) || brewModelExists
    }

    static var brewModelPath: URL? {
        let brewPrefixes = [
            "/opt/homebrew/share/whisper-cpp/models/ggml-medium.bin",
            "/usr/local/share/whisper-cpp/models/ggml-medium.bin"
        ]
        for path in brewPrefixes {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }

    static var brewModelExists: Bool {
        brewModelPath != nil
    }

    /// Downloads the model if needed. Calls progress with 0.0-1.0, then completion with success/failure.
    static func ensureModel(progress: @escaping (Double) -> Void, completion: @escaping (Bool) -> Void) {
        if modelExists {
            Logger.log("Model found at \(modelPath.path)")
            completion(true)
            return
        }

        if let brewPath = brewModelPath {
            Logger.log("Using brew model at \(brewPath.path)")
            completion(true)
            return
        }

        try? FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true)

        Logger.log("Downloading model from \(modelURL)...")

        let session = URLSession(configuration: .default, delegate: DownloadDelegate(progress: progress, completion: { url in
            guard let url = url else {
                completion(false)
                return
            }

            do {
                try FileManager.default.moveItem(at: url, to: modelPath)
                Logger.log("Model downloaded to \(modelPath.path)")
                completion(true)
            } catch {
                Logger.log("Failed to move downloaded model: \(error)")
                completion(false)
            }
        }), delegateQueue: nil)

        guard let url = URL(string: modelURL) else {
            completion(false)
            return
        }

        session.downloadTask(with: url).resume()
    }
}

private class DownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    let progress: (Double) -> Void
    let completion: (URL?) -> Void

    init(progress: @escaping (Double) -> Void, completion: @escaping (URL?) -> Void) {
        self.progress = progress
        self.completion = completion
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        completion(location)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            let pct = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            progress(pct)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            Logger.log("Download failed: \(error)")
            completion(nil)
        }
    }
}
