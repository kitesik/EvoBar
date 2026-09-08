import SwiftUI

@main
struct EvoBarApplication: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(model: appDelegate.model)
                .frame(width: EvoStyle.width, height: EvoStyle.height)
                .background(EvoStyle.background)
                .tint(EvoStyle.accent)
        }
    }
}
