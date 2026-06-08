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
                            ForEach(model.workspaces, id: \.self) { workspace in
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
                    ForEach(apps, id: \.bundleId) { app in
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
