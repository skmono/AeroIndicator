import Foundation

struct AppDataType: Equatable, Identifiable {
    var id: String { "\(workspaceId)|\(bundleId)|\(appName)" }
    var workspaceId: String
    var bundleId: String
    var appName: String
}
