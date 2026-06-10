import SwiftUI

struct AeroIndicatorApp: View {
    @ObservedObject var model: AppManager

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if ["bottom-left", "bottom-center", "bottom-right", "center"]
                    .contains(model.config.position)
                {
                    Spacer()
                }
                HStack(spacing: 0) {
                    if ["bottom-right", "bottom-center", "top-right", "top-center", "center"]
                        .contains(model.config.position)
                    {
                        Spacer()
                    }
                    HStack(spacing: 0) {
                        if !model.workspaces.isEmpty {
                            ForEach(
                                Array(model.workspaces.enumerated()), id: \.element
                            ) { index, workspace in
                                if index > 0 && model.config.separator.enabled {
                                    SeparatorView(config: model.config.separator, iconSize: model.config.iconSize)
                                }
                                AeroIndicatorWorkspace(
                                    workspace: workspace,
                                    model: model
                                )
                            }
                        }
                    }
                    .padding(model.config.innerPadding)
                    .visualEffect(material: .popover, blendingMode: .behindWindow)
                    .clipShape(
                        RoundedRectangle(cornerRadius: model.config.borderRadius)
                    )
                    if ["bottom-left", "bottom-center", "top-left", "top-center", "center"]
                        .contains(model.config.position)
                    {
                        Spacer()
                    }
                }
                .padding(.horizontal, model.config.outerPadding)
                if ["top-left", "top-center", "top-right", "center"].contains(model.config.position)
                {
                    Spacer()
                }
            }
            .padding(.vertical, model.config.outerPadding)
            .offset(x: model.config.offsetX, y: -model.config.offsetY)
            .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
        }
    }
}

struct AeroIndicatorWorkspace: View {
    var workspace: String
    @ObservedObject var model: AppManager
    @State var apps: [AppDataType] = []

    var body: some View {
        HStack(spacing: 0) {
            if workspace == model.focusWorkspace || !apps.isEmpty {
                HStack {
                    Text(workspace)
                        .font(
                            Font(
                                NSFont
                                    .monospacedSystemFont(
                                        ofSize: model.config.fontSize ?? NSFont.systemFontSize,
                                        weight: .regular
                                    )
                            )
                        )
                        .foregroundColor(
                            model.focusWorkspace == workspace ? Color.red : Color.primary)
                    ForEach(apps) { app in
                        AeroIndicatorWorkspaceApp(app: app, model: model)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .onChange(of: model.allApps) { newValue in
            self.apps = newValue.filter({ $0.workspaceId == workspace })
        }
        .onAppear {
            self.apps = model.allApps.filter({ $0.workspaceId == workspace })
        }
    }
}

struct AeroIndicatorWorkspaceApp: View {
    var app: AppDataType
    @ObservedObject var model: AppManager

    var body: some View {
        if let image = AppIcon.shared.get(app.bundleId, appName: app.appName) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: model.config.iconSize, height: model.config.iconSize)
        }
    }
}

struct SeparatorView: View {
    var config: SeparatorConfig
    var iconSize: Double

    var body: some View {
        Rectangle()
            .fill(parseColor(config.color))
            .frame(width: config.width, height: iconSize * config.height)
            .padding(.horizontal, 4)
    }

    private func parseColor(_ value: String) -> Color {
        if value.hasPrefix("#") {
            let hex = String(value.dropFirst())
            guard hex.count == 6, let rgb = UInt64(hex, radix: 16) else {
                return .gray
            }
            let r = Double((rgb >> 16) & 0xFF) / 255.0
            let g = Double((rgb >> 8) & 0xFF) / 255.0
            let b = Double(rgb & 0xFF) / 255.0
            return Color(red: r, green: g, blue: b)
        }
        switch value.lowercased() {
        case "white": return .white
        case "black": return .black
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        default: return .gray
        }
    }
}
