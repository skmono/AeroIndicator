import Cocoa
import Foundation

func isAppAlreadyRunning() -> Bool {
    let fileManager = FileManager.default
    return fileManager.fileExists(atPath: "/tmp/AeroIndicator")
}

func startApplication() {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: Bundle.main.executablePath!)
    process.arguments = ["--run-app"]
    try? process.run()
}

func runApplication() {
    let delegate = AppDelegate()
    NSApplication.shared.delegate = delegate
    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
}

func stopApplication() {
    var appsToWatch: [NSRunningApplication] = []

    if let bundleID = Bundle.main.bundleIdentifier {
        let runningApps = NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleID)

        for app in runningApps where app.processIdentifier != getpid() {
            app.forceTerminate()
            appsToWatch.append(app)
        }
    }

    let task = Process()
    task.launchPath = "/usr/bin/pkill"
    task.arguments = ["-ix", "aeroindicator"]
    try? task.run()
    task.waitUntilExit()

    // Wait for the old process to actually terminate (up to 3 seconds)
    let deadline = Date().addingTimeInterval(3.0)
    for app in appsToWatch {
        while !app.isTerminated && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }
    }

    try? FileManager.default.removeItem(atPath: "/tmp/AeroIndicator")
}

if CommandLine.arguments.count > 1 {
    let cmd = CommandLine.arguments[1]

    if cmd == "--start-service" {
        if isAppAlreadyRunning() {
            print("Error: Application is already running. Please provide command arguments.")
            exit(1)
        } else {
            startApplication()
        }
    } else if cmd == "--stop-service" {
        stopApplication()
        exit(0)
    } else if cmd == "--restart-service" {
        stopApplication()
        startApplication()
    } else if cmd == "--run-app" {
        runApplication()
    } else if cmd == "--help" || cmd == "-h" {
        print("Usage: AeroIndicator [COMMAND]")
        print("Commands:")
        print("  --start-service                 Start the AeroIndicator service")
        print("  --stop-service                  Stop the AeroIndicator service")
        print("  --restart-service               Restart the AeroIndicator service")
        print("  --help, -h                      Show this help message")
        print("  workspace-change WORKSPACE      Change to specified workspace")
        print("  focus-change                    Refresh application list")
        print("  workspace-created-or-destroyed  Create or destroy workspace")
        exit(0)
    } else if isAppAlreadyRunning() {
        let message = CommandLine.arguments[1...].joined(separator: " ")
        let client = Socket(isClient: true)
        client.send(message: message)
        exit(0)
    } else {
        print("Error: Application is not running. Run application first.")
        print("Use --help or -h to show available commands.")
        exit(1)
    }
} else {
    print("Usage: AeroIndicator [COMMAND]")
    print("Use --help or -h to show available commands.")
    exit(1)
}
