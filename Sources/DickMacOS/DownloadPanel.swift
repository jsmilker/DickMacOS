import AppKit

@MainActor
class DownloadPanel {
    static let shared = DownloadPanel()

    private var panel: NSPanel!
    private var progressBar: NSProgressIndicator!
    private var label: NSTextField!

    private init() {}

    func setupIfNeeded() {
        guard panel == nil else { return }

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = NSColor.black.withAlphaComponent(0.8)
        panel.center()

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))

        label = NSTextField(labelWithString: "Downloading model...")
        label.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.alignment = .center
        label.frame = NSRect(x: 20, y: 60, width: 260, height: 20)
        contentView.addSubview(label)

        progressBar = NSProgressIndicator()
        progressBar.style = .bar
        progressBar.isIndeterminate = false
        progressBar.minValue = 0
        progressBar.maxValue = 1
        progressBar.frame = NSRect(x: 20, y: 30, width: 260, height: 20)
        contentView.addSubview(progressBar)

        panel.contentView = contentView
    }

    func show() {
        setupIfNeeded()
        panel.orderFrontRegardless()
    }

    func updateProgress(_ percent: Double) {
        progressBar.doubleValue = percent
        label.stringValue = String(format: "Downloading model... %d%%", Int(percent * 100))
    }

    func hide() {
        panel.orderOut(nil)
    }
}
