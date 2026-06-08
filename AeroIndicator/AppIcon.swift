import SwiftUI

class AppIcon {
    static let shared = AppIcon()

    private var map: [String: NSImage] = [:]

    func get(_ bundleID: String, appName: String? = nil) -> NSImage? {
        let key = bundleID.isEmpty || bundleID == "NULL-APP-BUNDLE-ID" ? (appName ?? bundleID) : bundleID
        if let image = map[key] {
            return image
        }
        let workspace = NSWorkspace.shared
        if bundleID != "NULL-APP-BUNDLE-ID" && !bundleID.isEmpty,
           let appURL = workspace.urlForApplication(withBundleIdentifier: bundleID) {
            let image = workspace.icon(forFile: appURL.path)
            map[key] = image
            return image
        }
        if let name = appName, let appURL = findAppByName(name) {
            let image = workspace.icon(forFile: appURL.path)
            map[key] = image
            return image
        }
        return nil
    }

    private func findAppByName(_ name: String) -> URL? {
        let searchDirs = [
            "/Applications",
            "/System/Applications",
            NSHomeDirectory() + "/Applications"
        ]
        let fileManager = FileManager.default
        for dir in searchDirs {
            if let contents = try? fileManager.contentsOfDirectory(atPath: dir) {
                for item in contents where item.hasSuffix(".app") {
                    let appNameFromFile = (item as NSString).deletingPathExtension
                    if appNameFromFile.localizedCaseInsensitiveCompare(name) == .orderedSame
                        || appNameFromFile.localizedCaseInsensitiveContains(name)
                        || name.localizedCaseInsensitiveContains(appNameFromFile) {
                        return URL(fileURLWithPath: "\(dir)/\(item)")
                    }
                }
            }
        }
        return nil
    }
}
