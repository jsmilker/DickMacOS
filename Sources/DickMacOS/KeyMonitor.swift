import Cocoa

class KeyMonitor {
    private let onRecordingTriggered: () -> Void
    private let onKeyReleased: () -> Void
    private var monitor: Any?
    private var isRecording = false

    init(onRecordingTriggered: @escaping () -> Void, onKeyReleased: @escaping () -> Void) {
        self.onRecordingTriggered = onRecordingTriggered
        self.onKeyReleased = onKeyReleased
    }

    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.control, .shift]) && event.keyCode == 2 {
                self?.toggleRecording()
            }
        }
        Logger.log("KeyMonitor started (Ctrl+Shift+D)")
    }

    private func toggleRecording() {
        if isRecording {
            isRecording = false
            onKeyReleased()
        } else {
            isRecording = true
            onRecordingTriggered()
        }
    }
}
