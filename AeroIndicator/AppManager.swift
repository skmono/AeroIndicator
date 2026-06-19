import SwiftUI

class AppManager: ObservableObject {
    private var show = false
    private var window: MainWindow<AeroIndicatorApp>?
    private var server: Socket?
    private var screenChangeObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?

    @Published var workspaces: [String] = []
    @Published var focusWorkspace: String = ""
    @Published var allApps: [AppDataType] = []
    @Published var config: AeroConfig = readConfig()

    var isUpdatingApps = false

    deinit {
        // Clean up the screen change observer
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    func start() {
        Task {
            let workspace = getAllWorkspaces(source: config.source)
            let focusWorkspace = getFocusedWorkspace(source: config.source)
            let allApps = getAllApps(source: config.source)

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.workspaces = workspace
                self.focusWorkspace = focusWorkspace
                self.allApps = allApps

                self.createWindow()
                self.observeScreenChanges()
                self.observeWake()
            }
        }
        startListeningKey()
        startListeningCommand()
        Log.shared.info("Service started (pid \(getpid()))")
    }

    private func createWindow() {
        guard let screenFrame = NSScreen.main?.frame else { return }
        let statusBarHeight = NSStatusBar.system.thickness
        let contentRect = NSRect(
            x: 0,
            y: 0,
            width: screenFrame.size.width,
            height: screenFrame.size.height - statusBarHeight
        )

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.window = MainWindow(contentRect: contentRect) {
                AeroIndicatorApp(model: self)
            }

            self.window?.orderOut(nil)
        }
    }

    private func observeScreenChanges() {
        // Listen for screen parameter changes (resolution, display connect/disconnect, etc.)
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.recreateWindow()
        }
    }

    private func observeWake() {
        // On wake the key-release `flagsChanged` event that would normally hide
        // the bar may never have been delivered (it happened while asleep).
        // Reconcile against the actual modifier state instead of assuming.
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let optionHeld = NSEvent.modifierFlags.contains(.option)
            self.show = optionHeld
            if optionHeld {
                self.window?.orderFrontRegardless()
            } else {
                self.window?.orderOut(nil)
            }
            Log.shared.info("Woke from sleep, reconciled bar (optionHeld: \(optionHeld))")
        }
    }

    private func recreateWindow() {
        guard let screenFrame = NSScreen.main?.frame else { return }
        let statusBarHeight = NSStatusBar.system.thickness
        let contentRect = NSRect(
            x: 0,
            y: 0,
            width: screenFrame.size.width,
            height: screenFrame.size.height - statusBarHeight
        )

        // Preserve the current visibility state
        let wasVisible = self.window?.isVisible ?? false

        // Dismiss the existing window before dropping our reference to it.
        // Otherwise the old panel stays on screen as an orphan we can no longer
        // hide (the duplicate bar seen after sleep/wake display reconfiguration).
        self.window?.orderOut(nil)

        // Recreate the window with new screen dimensions
        self.window = MainWindow(contentRect: contentRect) {
            AeroIndicatorApp(model: self)
        }

        // Restore visibility state
        if wasVisible {
            self.window?.orderFrontRegardless()
        } else {
            self.window?.orderOut(nil)
        }
        Log.shared.info("Window recreated (wasVisible: \(wasVisible))")
    }

    private func startListeningCommand() {
        server = Socket(isClient: false) { message in
            // Security: Validate and sanitize input
            let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)

            // Reject messages that are too long (DOS protection)
            guard trimmedMessage.count > 0 && trimmedMessage.count < 1000 else { return }

            let splitMessages = trimmedMessage.split(separator: " ").map({ String($0) })
            guard splitMessages.count > 0 else { return }

            // Security: Only allow specific commands (allowlist approach)
            let validCommands = ["workspace-change", "focus-change", "workspace-created-or-destroyed"]
            guard validCommands.contains(splitMessages[0]) else {
                Log.shared.warn("Rejected invalid command: \(splitMessages[0])")
                return
            }

            if splitMessages[0] == "workspace-change" && splitMessages.count == 2 {
                // Security: Validate workspace name (alphanumeric and basic chars only)
                let workspace = splitMessages[1]
                let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
                guard workspace.rangeOfCharacter(from: allowedCharacters.inverted) == nil else {
                    Log.shared.warn("Rejected invalid workspace name: \(workspace)")
                    return
                }

                withAnimation {
                    self.focusWorkspace = workspace
                }
            } else if splitMessages[0] == "focus-change" {
                self.getAllWorkspaceApps()
            } else if splitMessages[0] == "workspace-created-or-destroyed" {
                self.workspaces = getAllWorkspaces(source: self.config.source)
            }
        }
        server?.startListening()
    }

    private func getAllWorkspaceApps() {
        if self.isUpdatingApps { return }
        Task {
            self.isUpdatingApps = true
            let allApps = getAllApps(source: config.source)
            DispatchQueue.main.async {
                self.allApps = allApps
                self.isUpdatingApps = false
            }
        }
    }

    private func startListeningKey() {
        func handleEvent(_ event: NSEvent) {
            if event.modifierFlags.contains(.option) {
                if !self.show {
                    Log.shared.info("Bar trigger: option pressed, showing bar")
                }
                self.show = true
                DispatchQueue.main.async {
                    self.window?.orderFrontRegardless()
                }
            } else if self.show {
                Log.shared.info("Bar trigger: option released, hiding bar")
                self.show = false
                DispatchQueue.main.async {
                    self.window?.orderOut(nil)
                }
            }
        }
        NSEvent.addGlobalMonitorForEvents(
            matching: [.flagsChanged],
            handler: { event in
                handleEvent(event)
            })

        NSEvent.addLocalMonitorForEvents(
            matching: [.flagsChanged],
            handler: { event in
                handleEvent(event)
                return nil
            })
    }
}
