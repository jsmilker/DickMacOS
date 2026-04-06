import AVFoundation

class AudioRecorder: @unchecked Sendable {
    static let shared = AudioRecorder()
    
    private var recorder: AVAudioRecorder?
    private var currentURL: URL?
    private var onAudioChunk: ((URL) -> Void)?
    var chunkDuration: TimeInterval = 2.0
    private var chunkTimer: Timer?
    private var recordingStartTime: Date?
    private var chunkCount = 0
    private var chunkURLs: [URL] = []

    private init() {}
    
    func setChunkCallback(_ callback: @escaping (URL) -> Void) {
        onAudioChunk = callback
    }

    func startRecording() {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("whisper-dictation-\(UUID().uuidString).wav")
        currentURL = url
        chunkURLs = [url]
        recordingStartTime = Date()
        chunkCount = 0

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.record()
            print("Recording started: \(url.lastPathComponent)")
            
            chunkTimer = Timer.scheduledTimer(withTimeInterval: chunkDuration, repeats: false) { [weak self] _ in
                self?.triggerChunk()
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    private func triggerChunk() {
        guard let callback = onAudioChunk else { return }
        
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("whisper-chunk-\(chunkCount).wav")
        chunkCount += 1
        
        recorder?.pause()
        let prevURL = currentURL
        currentURL = url
        
        do {
            recorder = try AVAudioRecorder(url: url, settings: [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ])
            recorder?.isMeteringEnabled = true
            recorder?.record()
        } catch {
            print("Failed to create chunk file: \(error)")
        }
        
        if let prevURL = prevURL {
            chunkURLs.append(prevURL)
            print("Chunk \(chunkCount) triggered: \(prevURL.lastPathComponent)")
            callback(prevURL)
        }
        
        chunkTimer = Timer.scheduledTimer(withTimeInterval: chunkDuration, repeats: false) { [weak self] _ in
            self?.triggerChunk()
        }
    }

    func stopRecording() -> URL {
        chunkTimer?.invalidate()
        chunkTimer = nil
        recorder?.stop()
        recorder = nil
        
        let url = currentURL ?? URL(fileURLWithPath: "/dev/null")
        
        if let lastURL = chunkURLs.last, lastURL != url {
            chunkURLs.append(url)
        }
        
        print("Recording stopped: \(url.lastPathComponent)")
        
        if chunkURLs.count > 1 {
            return concatenateChunks()
        }
        return url
    }
    
    private func concatenateChunks() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let finalURL = tempDir.appendingPathComponent("whisper-dictation-final-\(UUID().uuidString).wav")
        
        let audioFiles = chunkURLs.compactMap { url -> AVAudioFile? in
            try? AVAudioFile(forReading: url)
        }
        
        guard let firstFile = audioFiles.first else { return finalURL }
        
        let format = firstFile.processingFormat
        _ = audioFiles.reduce(0) { $0 + Int($1.length) }
        
        do {
            let outputFile = try AVAudioFile(forWriting: finalURL, settings: [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ])
            
            for audioFile in audioFiles {
                let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(audioFile.length))
                try audioFile.read(into: buffer!)
                try outputFile.write(from: buffer!)
            }
            
            for url in chunkURLs {
                try? FileManager.default.removeItem(at: url)
            }
            
            print("Concatenated \(audioFiles.count) chunks into \(finalURL.lastPathComponent)")
        } catch {
            print("Failed to concatenate chunks: \(error)")
        }
        
        return finalURL
    }
    
    func getRecordingDuration() -> TimeInterval {
        guard let start = recordingStartTime else { return 0 }
        return Date().timeIntervalSince(start)
    }
}
