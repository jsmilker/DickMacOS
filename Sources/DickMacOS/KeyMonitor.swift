import Cocoa

class KeyMonitor {
    private let onRecordingTriggered: () -> Void
    private let onKeyReleased: () -> Void
    private var monitor: Any?
    private var isRecording = false

    private let triggerKeyCode: UInt16
    private let triggerModifiers: NSEvent.ModifierFlags

    init(onRecordingTriggered: @escaping () -> Void, onKeyReleased: @escaping () -> Void) {
        self.onRecordingTriggered = onRecordingTriggered
        self.onKeyReleased = onKeyReleased

        let savedShortcut = UserDefaults.standard.string(forKey: "HotkeyShortcut") ?? "Option+Shift+D"
        (self.triggerKeyCode, self.triggerModifiers) = KeyMonitor.parseShortcut(savedShortcut)
    }

    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if modifiers == self!.triggerModifiers && event.keyCode == self!.triggerKeyCode {
                self?.toggleRecording()
            }
        }
        let shortcutDesc = UserDefaults.standard.string(forKey: "HotkeyShortcut") ?? "Option+Shift+D"
        Logger.log("KeyMonitor started (\(shortcutDesc))")
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

    private static func parseShortcut(_ shortcut: String) -> (UInt16, NSEvent.ModifierFlags) {
        let parts = shortcut.components(separatedBy: "+")
        var modifiers: NSEvent.ModifierFlags = []
        var keyCode: UInt16 = 2

        for part in parts {
            switch part.trimmingCharacters(in: .whitespaces).lowercased() {
            case "command", "cmd":
                modifiers.formUnion(.command)
            case "control", "ctrl":
                modifiers.formUnion(.control)
            case "option", "alt":
                modifiers.formUnion(.option)
            case "shift":
                modifiers.formUnion(.shift)
            default:
                if let key = part.trimmingCharacters(in: .whitespaces).uppercased().first {
                    keyCode = getKeyCode(for: key)
                }
            }
        }

        return (keyCode, modifiers)
    }

    private static func getKeyCode(for character: Character) -> UInt16 {
        let keyCodes: [Character: UInt16] = [
            "A": 0, "B": 11, "C": 8, "D": 2, "E": 14, "F": 3, "G": 5, "H": 4,
            "I": 34, "J": 38, "K": 40, "L": 37, "M": 46, "N": 45, "O": 31,
            "P": 35, "Q": 12, "R": 15, "S": 1, "T": 17, "U": 32, "V": 9,
            "W": 13, "X": 7, "Y": 16, "Z": 21
        ]
        return keyCodes[Character(String(character).uppercased())] ?? 2
    }
}
