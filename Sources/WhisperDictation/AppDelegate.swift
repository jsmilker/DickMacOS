import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, @unchecked Sendable {

    private var statusItem: NSStatusItem!
    private var statusMenuItem: NSMenuItem!
    private var recordMenuItem: NSMenuItem!
    private var keyMonitor: KeyMonitor!

    private var modelReady = false
    private var isRecording = false
    private var currentTranscription = ""

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.log("App launched")
        NSApp.setActivationPolicy(.accessory)

        Task { @MainActor in
            self.setupMenuBar()
        }
        Logger.log("Menu bar ready, checking model...")
        ensureModel()
    }

    @MainActor private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(toggleRecording)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Whisper Dictation")
        }

        let menu = NSMenu()

        statusMenuItem = NSMenuItem(title: "Status: Idle", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        recordMenuItem = NSMenuItem(title: "Start Recording", action: #selector(toggleRecording), keyEquivalent: "")
        recordMenuItem.target = self
        menu.addItem(recordMenuItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    @objc private func toggleRecording() {
        Task { @MainActor in
            if isRecording {
                handleKeyReleased()
            } else {
                handleRecordingTriggered()
            }
        }
    }

    private func updateStatus(_ text: String, recording: Bool) {
        DispatchQueue.main.async {
            self.statusMenuItem.title = "Status: \(text)"
            self.recordMenuItem.title = recording ? "Stop Recording" : "Start Recording"

            if let button = self.statusItem.button {
                let image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Whisper Dictation")

                if recording {
                    let config = NSImage.SymbolConfiguration(paletteColors: [.red])
                    button.image = image?.withSymbolConfiguration(config)
                } else {
                    button.image = image
                }
            }
        }
    }

    private func ensureModel() {
        Logger.log("Model exists: \(ModelManager.modelExists) at \(ModelManager.modelPath.path)")
        if ModelManager.modelExists {
            modelReady = true
            updateStatus("Idle", recording: false)
            setupKeyMonitor()
            setupAudioChunkHandler()
            Logger.log("Ready to record")
            return
        }

        updateStatus("Downloading model...", recording: false)

        ModelManager.ensureModel(progress: { pct in
            DispatchQueue.main.async {
                let percent = Int(pct * 100)
                self.updateStatus("Downloading model... \(percent)%", recording: false)
            }
        }, completion: { success in
            DispatchQueue.main.async {
                if success {
                    self.modelReady = true
                    self.updateStatus("Idle", recording: false)
                    self.setupKeyMonitor()
                    self.setupAudioChunkHandler()
                } else {
                    self.updateStatus("Model download failed", recording: false)
                }
            }
        })
    }

    private func setupKeyMonitor() {
        keyMonitor = KeyMonitor(
            onRecordingTriggered: { [weak self] in
                self?.handleRecordingTriggered()
            },
            onKeyReleased: { [weak self] in
                self?.handleKeyReleased()
            }
        )
        keyMonitor.start()
    }
    
    private func setupAudioChunkHandler() {
        AudioRecorder.shared.setChunkCallback { [weak self] chunkURL in
            self?.transcribeChunk(url: chunkURL)
        }
    }
    
    private func transcribeChunk(url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            let text = Transcriber.transcribe(fileURL: url, deleteAfter: true)
            
            DispatchQueue.main.async {
                if !text.isEmpty {
                    self.currentTranscription = self.currentTranscription.isEmpty ? text : self.currentTranscription + " " + text
                    RecordingPanel.shared.updateText(text: self.currentTranscription)
                    Logger.log("Modal updated: \(self.currentTranscription)")
                }
            }
        }
    }

    private func handleRecordingTriggered() {
        guard modelReady else { return }
        isRecording = true
        currentTranscription = ""
        AudioRecorder.shared.startRecording()
        
        Task { @MainActor in
            RecordingPanel.shared.show()
            self.updateStatus("Recording...", recording: true)
            NSSound(named: "Tink")?.play()
        }
    }

private func handleKeyReleased() {
    isRecording = false
    let fileURL = AudioRecorder.shared.stopRecording()
    
    updateStatus("Transcribing...", recording: false)

    DispatchQueue.global(qos: .userInitiated).async {
        let text = Transcriber.transcribe(fileURL: fileURL, deleteAfter: true)

        DispatchQueue.main.async {
            let finalText = self.currentTranscription.isEmpty ? text : 
                (text.isEmpty ? self.currentTranscription : self.currentTranscription + " " + text)
            
            Paster.paste(text: finalText)
            
            // Update the panel one last time, wait a second, then hide it
            RecordingPanel.shared.updateText(text: finalText.isEmpty ? "No speech detected" : finalText)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                RecordingPanel.shared.hide() // <--- ADD THIS
            }
            
            if !finalText.isEmpty {
                NSSound(named: "Pop")?.play()
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(finalText, forType: .string)
            }
            
            self.currentTranscription = ""
            self.updateStatus("Idle", recording: false)
        }
    }
}

    @objc private func quit() {
        DispatchQueue.main.async {
            NSApp.terminate(nil)
        }
    }
}
