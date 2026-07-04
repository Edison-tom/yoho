import AppKit

/// 监听鼠标进出窗口，控制透明度
@MainActor
final class MouseTracker {
    private weak var window: NSWindow?
    private var monitor: Any?

    init(window: NSWindow) {
        self.window = window
    }

    func start() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self, let window = self.window else { return event }
            let mouseInWindow = window.contentView?.bounds.contains(
                window.contentView!.convert(event.locationInWindow, from: nil)
            ) ?? false

            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = Constants.alphaTransitionDuration
                window.animator().alphaValue = mouseInWindow
                    ? Constants.hoverAlpha
                    : Constants.idleAlpha
            }
            return event
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
