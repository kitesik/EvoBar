import SwiftUI

@main
struct EvoBarApplication: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            StandaloneSettingsView(model: appDelegate.model)
        }
    }
}
