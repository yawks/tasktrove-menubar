import SwiftUI
import AppKit

@main
struct TaskerApp: App {
    // Observe the shared configuration service
    @StateObject private var configService = ConfigurationService.shared

    // The TaskListViewModel is now created dynamically when configuration is available.
    @State private var taskListViewModel: TaskListViewModel?
    // Lightweight fallback: monitor right-clicks near the top of the screen
    // and present a Quit menu. This helps when MenuBarExtra doesn't forward
    // right-click events to embedded AppKit views.
    @State private var rightClickMonitor: Any?

    var body: some Scene {
        MenuBarExtra {
            // Using a Group to attach the onAppear modifier to the view's content
            Group {
                // Conditionally show SettingsView or ContentView
                if configService.isConfigured, let viewModel = taskListViewModel {
                    ContentView()
                        .environmentObject(viewModel)
                } else {
                    SettingsView()
                }
            }
            .onAppear {
                // Initial setup when the app starts.
                setupServices()
                installRightClickFallback()
            }
            // Ensure the menu window can grow a bit to accommodate the larger list
            .frame(minWidth: 450, maxWidth: 600, minHeight: 500, maxHeight: 550)
        } label: {
            // Show a SwiftUI Image for the visible menubar icon (reliable rendering)
            // and overlay a transparent AppKit view to intercept right-clicks.
            ZStack {
                Image(systemName: "checklist")
                    .imageScale(.small)
                    .frame(width: 18, height: 18)

                // Transparent click-catcher. When systemName is nil/empty the NSView won't
                // draw an image and will simply capture mouse events.
                RightClickableIcon(systemName: "")
                    .frame(width: 18, height: 18)
            }
            // Keep SwiftUI contextMenu as a fallback
            .contextMenu {
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .menuBarExtraStyle(.window)
        .onChange(of: configService.isConfigured) {
            // React to configuration changes.
            setupServices()
        }
    }

    /// Sets up the necessary services based on the current configuration.
    /// If configuration is invalid, it will be cleared.
    private func setupServices() {
        if configService.isConfigured {
            guard let config = configService.configuration else {
                return
            }

            do {
                let networkService = try NetworkService(configuration: config)
                self.taskListViewModel = TaskListViewModel(networkService: networkService)
            } catch {
                // If creating the service fails (e.g., invalid URL), clear the bad config.
                print("Failed to create network service with saved config: \(error.localizedDescription). Clearing configuration.")
                try? configService.clearConfiguration()
                self.taskListViewModel = nil
            }

        } else {
            // If configuration is cleared, destroy the view model.
            self.taskListViewModel = nil
        }
    }

    // MARK: - Fallback right-click monitor
    private func installRightClickFallback() {
        // Avoid installing multiple monitors
        if rightClickMonitor != nil { return }

        // Threshold in points from the top of the main screen to consider
        // the click as originating from the system menubar area.
        let topThreshold: CGFloat = 40

        rightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseUp) { event in
            // Global mouse location in screen coordinates
            let mouse = NSEvent.mouseLocation

            guard let screen = NSScreen.main else { return event }

            // If the click is within the topThreshold from the top of the screen,
            // treat it as a menubar click and show the Quit menu.
            if mouse.y > (screen.frame.size.height - topThreshold) {
                // Diagnostic
                print("Right-click fallback: detected menubar-area click at \(mouse)")

                let menu = NSMenu()
                let quit = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
                menu.addItem(quit)

                // Pop-up the menu at the mouse location. Passing `in: nil` uses
                // the screen coordinate space which is what we want here.
                menu.popUp(positioning: nil, at: NSPoint(x: mouse.x, y: mouse.y), in: nil)

                // Returning nil swallows the event to avoid duplicate handling
                // by other monitors/handlers.
                return nil
            }

            return event
        }
    }

    private func removeRightClickFallback() {
        if let monitor = rightClickMonitor {
            NSEvent.removeMonitor(monitor)
            rightClickMonitor = nil
        }
    }
}

// MARK: - Right-clickable status icon
/// A tiny NSViewRepresentable that hosts an image and intercepts right-clicks to
/// show a small NSMenu with a Quit action. Using AppKit directly is the most
/// reliable way to capture right-clicks on the menubar icon.
struct RightClickableIcon: NSViewRepresentable {
    let systemName: String

    func makeNSView(context: Context) -> ClickableImageView {
        // Give the view a sensible initial size so the status item has visible content
        let view = ClickableImageView(frame: NSRect(x: 0, y: 0, width: 18, height: 18))
        let img = (NSImage(systemSymbolName: systemName, accessibilityDescription: nil) ?? NSImage())
        // Prefer template rendering so the symbol adapts to the menubar appearance
        img.isTemplate = true
        view.image = img
        return view
    }

    func updateNSView(_ nsView: ClickableImageView, context: Context) {
        // no-op; image is set on creation
    }
}

/// NSView subclass that displays an image and responds to right mouse clicks.
final class ClickableImageView: NSView {
    private let imageView = NSImageView()
    private var trackingArea: NSTrackingArea?

    override init(frame frameRect: NSRect = .zero) {
        super.init(frame: frameRect)
        wantsLayer = true

        // Configure image view to resize with its parent
        imageView.frame = bounds
        imageView.wantsLayer = true
        imageView.autoresizingMask = [.width, .height]
        imageView.imageScaling = .scaleProportionallyDown
        imageView.imageAlignment = .alignCenter
        addSubview(imageView)
    }

    // Provide a sensible intrinsic content size so SwiftUI/MenuBarExtra can size the status item
    override var intrinsicContentSize: NSSize {
        if let img = imageView.image {
            return NSSize(width: img.size.width, height: img.size.height)
        }
        return NSSize(width: 18, height: 18)
    }

    // Ensure clicks are delivered to this view even if the window isn't key
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    // Make sure hit-testing returns this view so clicks are captured
    override func hitTest(_ point: NSPoint) -> NSView? {
        return self.bounds.contains(point) ? self : nil
    }

    // For diagnostics while testing, log left clicks (will appear in Xcode console)
    override func mouseDown(with event: NSEvent) {
        // print can help verify that clicks reach this view when running from Xcode
        print("ClickableImageView.mouseDown at: \(event.locationInWindow)")
        super.mouseDown(with: event)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    var image: NSImage? {
        didSet { imageView.image = image }
    }

    override func layout() {
        super.layout()
        imageView.frame = bounds
        // Update tracking area to match the current bounds so mouse events are delivered
        if let ta = trackingArea {
            removeTrackingArea(ta)
            trackingArea = nil
        }
        let options: NSTrackingArea.Options = [.activeAlways, .inVisibleRect, .mouseEnteredAndExited, .mouseMoved, .enabledDuringMouseDrag]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        if let ta = trackingArea { addTrackingArea(ta) }
    }

    // Right-click -> show a small menu with Quit
    override func rightMouseDown(with event: NSEvent) {
        // Diagnostic log to verify runtime event delivery
        print("ClickableImageView.rightMouseDown at: \(event.locationInWindow)")

        // Try the explicit popup as a fallback - also useful during debugging when
        // menu(for:) may not be queried by the system depending on the view/window setup.
        let menu = NSMenu()
        let quit = NSMenuItem(title: "Quit", action: #selector(quitApp(_:)), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)

        // Pop the menu anchored to the view (appear below the icon)
        let point = NSPoint(x: bounds.midX, y: bounds.maxY)
        menu.popUp(positioning: nil, at: point, in: self)
    }

    // Provide the contextual menu via the standard AppKit hook. In some host
    // configurations the system will call this instead of delivering a raw
    // rightMouseDown event, so implementing both increases reliability.
    override func menu(for event: NSEvent) -> NSMenu? {
        print("ClickableImageView.menu(for:) invoked")
        let menu = NSMenu()
        let quit = NSMenuItem(title: "Quit", action: #selector(quitApp(_:)), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)
        return menu
    }

    @objc private func quitApp(_ sender: Any?) {
        NSApplication.shared.terminate(nil)
    }
}