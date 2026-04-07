import AppKit
import AVFoundation
@preconcurrency import ApplicationServices

class PermissionChecker {
    private static let accessibilityUsageDescription = "DickMacOS needs Accessibility access to detect global hotkeys."
    private static let microphoneUsageDescription = "DickMacOS needs microphone access to record speech for transcription."
    private static let appleEventsUsageDescription = "DickMacOS needs to paste transcribed text into the active application."

    static var hasAllPermissions: Bool {
        return AXIsProcessTrusted() && hasMicrophoneAccess() && hasAppleEventsAccess()
    }

    static func requestAllPermissions(completion: @escaping @Sendable () -> Void) {
        if hasAllPermissions {
            Logger.log("All permissions already granted")
            completion()
            return
        }

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Permission Setup Required"
            alert.informativeText = "DickMacOS requires Accessibility, Microphone, and Apple Events permissions to function."
            alert.addButton(withTitle: "Continue")
            alert.addButton(withTitle: "Quit")

            let response = alert.runModal()
            if response != .alertFirstButtonReturn {
                NSApp.terminate(nil)
                return
            }

            openSystemSettings()

            let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if hasAllPermissions {
                    timer.invalidate()
                    Logger.log("All permissions granted")
                    completion()
                }
            }
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    private static func hasMicrophoneAccess() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        return status == .authorized
    }

    private static func hasAppleEventsAccess() -> Bool {
        let script = NSAppleScript(source: "tell application \"System Events\" to get the name of every process")
        var error: NSDictionary?
        _ = script?.executeAndReturnError(&error)
        return error == nil
    }

    private static func openSystemSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
        }
    }
}
