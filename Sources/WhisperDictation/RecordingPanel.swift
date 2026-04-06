import AppKit
import Foundation
import QuartzCore

@MainActor
class RecordingPanel: @unchecked Sendable {

    static let shared = RecordingPanel()

    private var panel: NSPanel?
    private var textView: NSTextView?
    private var scrollView: NSScrollView?
    private var isShowing = false

    private init() {}

    func show() {
        guard !isShowing else { return }
        isShowing = true

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 240),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false
        )

        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear

        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.85).cgColor
        container.layer?.cornerRadius = 20

        // Create scroll view
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 40, height: 40)
        textView.textContainer?.lineFragmentPadding = 0
        textView.alignment = .left
        textView.textContainer?.widthTracksTextView = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        scrollView.documentView = textView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        panel.contentView = container
        self.textView = textView
        self.scrollView = scrollView
        self.panel = panel

        if let screen = NSScreen.main {
            panel.setFrameOrigin(NSPoint(x: (screen.frame.width - 760)/2, y: screen.frame.height * 0.3))
        }

        panel.makeKeyAndOrderFront(nil)
        updateText(text: "Listening...")
    }

    func updateText(text: String) {
        guard let textView = textView else { return }
        let displayText = text.isEmpty ? "Listening..." : text

        // Soft fade animation
        let transition = CATransition()
        transition.duration = 0.4
        transition.type = .fade
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        textView.layer?.add(transition, forKey: kCATransition)

        setAttributedText(displayText, on: textView)

        // Scroll to bottom after layout
        DispatchQueue.main.async {
            if let scrollView = self.scrollView {
                scrollView.contentView.scroll(to: NSPoint(x: 0, y: textView.bounds.height - scrollView.contentView.bounds.height))
                scrollView.reflectScrolledClipView(scrollView.contentView)
            }
        }
    }

    private func setAttributedText(_ text: String, on textView: NSTextView) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineSpacing = 6

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 32, weight: .semibold),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle
        ]

        let attrString = NSAttributedString(string: text, attributes: attrs)
        textView.textStorage?.setAttributedString(attrString)
        textView.alignment = .left
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
        textView = nil
        scrollView = nil
        isShowing = false
    }
}