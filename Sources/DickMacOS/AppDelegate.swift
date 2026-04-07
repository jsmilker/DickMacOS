import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, @unchecked Sendable {

    private var statusItem: NSStatusItem!
    private var statusMenuItem: NSMenuItem!
    private var recordMenuItem: NSMenuItem!
    private var keyMonitor: KeyMonitor!
    private var contextMenu: NSMenu!

    private var modelReady = false
    private var isRecording = false
    private var currentTranscription = ""

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.log("App launched")
        NSApp.setActivationPolicy(.accessory)

        Task { @MainActor in
            self.setupMenuBar()
        }

        PermissionChecker.requestAllPermissions {
            Task { @MainActor in
                Logger.log("Menu bar ready, checking model...")
                self.ensureModel()
            }
        }
    }

    @MainActor private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(toggleRecording)
            button.image = NSImage(named: "Inactive")
            button.image?.isTemplate = false
        }

        // Build context menu
        contextMenu = NSMenu()

        statusMenuItem = NSMenuItem(title: "Status: Idle", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        contextMenu.addItem(statusMenuItem)

        recordMenuItem = NSMenuItem(title: "Start Recording", action: #selector(toggleRecording), keyEquivalent: "")
        recordMenuItem.target = self
        contextMenu.addItem(recordMenuItem)

        contextMenu.addItem(NSMenuItem.separator())

        let changeShortcutMenuItem = NSMenuItem(title: "Change Shortcut...", action: #selector(changeShortcut), keyEquivalent: "")
        changeShortcutMenuItem.target = self
        contextMenu.addItem(changeShortcutMenuItem)

        let audioSourceMenuItem = NSMenuItem(title: " \(AudioRecorder.shared.currentAudioDeviceName)", action: nil, keyEquivalent: "")
        audioSourceMenuItem.isEnabled = false
        contextMenu.addItem(audioSourceMenuItem)

        contextMenu.addItem(NSMenuItem.separator())
        contextMenu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        // No menu attached - click always triggers recording
        // Right-click users can use the menu items in the future
    }

    @MainActor @objc private func toggleRecording() {
        Logger.log("toggleRecording called, isRecording=\(isRecording)")
        if isRecording {
            handleKeyReleased()
        } else {
            handleRecordingTriggered()
        }
    }

    @MainActor @objc private func changeShortcut() {
        let alert = NSAlert()
        alert.messageText = "Change Hotkey Shortcut"
        alert.informativeText = "Enter shortcut format: Modifier+Modifier+Key\nExample: Option+Shift+D or Ctrl+Alt+K"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.placeholderString = "Option+Shift+D"
        textField.stringValue = UserDefaults.standard.string(forKey: "HotkeyShortcut") ?? "Option+Shift+D"
        alert.accessoryView = textField

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let newShortcut = textField.stringValue
            UserDefaults.standard.set(newShortcut, forKey: "HotkeyShortcut")

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
    }

    private func updateStatus(_ text: String, recording: Bool) {
        DispatchQueue.main.async {
            self.statusMenuItem.title = "Status: \(text)"
            self.recordMenuItem.title = recording ? "Stop Recording" : "Start Recording"

            if let button = self.statusItem.button {
                button.image = recording ? NSImage(named: "Active") : NSImage(named: "Inactive")
                button.image?.isTemplate = false
            }
        }
    }

    @MainActor private func ensureModel() {
        Logger.log("Checking for model...")
        
        if ModelManager.modelExists {
            Logger.log("Model found at \(ModelManager.modelPath.path)")
            modelReady = true
            updateStatus("Idle", recording: false)
            setupKeyMonitor()
            setupAudioChunkHandler()
            Logger.log("Ready to record")
            return
        }

        if ModelManager.brewModelExists {
            Logger.log("Using brew model")
            modelReady = true
            updateStatus("Idle", recording: false)
            setupKeyMonitor()
            setupAudioChunkHandler()
            Logger.log("Ready to record")
            return
        }

        Logger.log("Model not found, downloading...")
        updateStatus("Downloading model...", recording: false)
        DownloadPanel.shared.show()

        ModelManager.ensureModel(progress: { [weak self] pct in
            Task { @MainActor in
                DownloadPanel.shared.updateProgress(pct)
                self?.updateStatus("Downloading model... \(Int(pct * 100))%", recording: false)
            }
        }, completion: { [weak self] success in
            Task { @MainActor in
                DownloadPanel.shared.hide()
                if success {
                    self?.modelReady = true
                    self?.updateStatus("Idle", recording: false)
                    self?.setupKeyMonitor()
                    self?.setupAudioChunkHandler()
                } else {
                    self?.updateStatus("Model download failed", recording: false)
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
