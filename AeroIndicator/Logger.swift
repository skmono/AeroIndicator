import Foundation

/// Lightweight file logger for the running service.
///
/// Writes to `/tmp/aeroindicator-<pid>.log` (alongside the `/tmp/AeroIndicator`
/// socket). `shared` is created lazily, so short-lived client invocations that
/// never log won't create a file.
final class Log {
    static let shared = Log()

    let path: String
    private let handle: FileHandle?
    private let queue = DispatchQueue(label: "com.aeroindicator.log")
    private let formatter: DateFormatter

    private init() {
        path = "/tmp/aeroindicator-\(getpid()).log"
        FileManager.default.createFile(atPath: path, contents: nil)
        handle = FileHandle(forWritingAtPath: path)

        formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }

    func info(_ message: String) { write("INFO", message) }
    func warn(_ message: String) { write("WARN", message) }
    func error(_ message: String) { write("ERROR", message) }

    private func write(_ level: String, _ message: String) {
        let line = "\(formatter.string(from: Date())) [\(level)] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        queue.async { [weak self] in
            self?.handle?.write(data)
        }
    }
}
