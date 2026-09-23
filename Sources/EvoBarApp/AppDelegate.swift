import AppKit
import EvoBarCore
import Foundation
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let runtime: AppRuntimeEnvironment
    let model: AppModel
    private var statusItemController: StatusItemController?
    private var desktopPetController: DesktopPetController?
#if DEBUG
    private var interactiveReviewController: InteractiveReviewController?
#endif

    override init() {
        let runtime = AppRuntimeEnvironment.current
        self.runtime = runtime
        self.model = AppModel(runtime: runtime)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItemController = StatusItemController(model: model)
        desktopPetController = DesktopPetController(model: model)
        model.load()
        runSmokeTestIfRequested()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // Launching the app again from Finder, Spotlight, or the Dock lands here.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        statusItemController?.presentForActivation()
        return false
    }

    // Cmd+Tab and other activations arrive here. A key window means the user is
    // already interacting with a popover or the desktop pet, so leave it alone.
    func applicationDidBecomeActive(_ notification: Notification) {
        guard NSApp.keyWindow == nil, runtime.smokeTestOutputURL == nil else { return }
        statusItemController?.presentForActivation()
    }

    func applicationWillTerminate(_ notification: Notification) {
        model.stopTracking()
    }

    private func runSmokeTestIfRequested() {
        guard let outputURL = runtime.smokeTestOutputURL else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            for _ in 0..<100 {
                switch self.model.loadState {
                case .ready:
#if DEBUG
                    if ProcessInfo.processInfo.environment["EVOBAR_INTERACTIVE_REVIEW"] == "1",
                       Bundle.main.bundleIdentifier == "com.evobar.interactive-review" {
                        // Include a waiting individual so naming and retry can
                        // be exercised without touching a real companion.
                        let scenario = ProcessInfo.processInfo.environment["EVOBAR_INTERACTIVE_REVIEW_SCREEN"]
                        if scenario == "lifecycle" || scenario == "hatch-adopt" {
                            do { try await self.model.prepareLifecycleReview(readyEgg: scenario == "hatch-adopt") }
                            catch {
                                self.writeSmokeTestReport(AppSmokeTestReport(status: "failed", detail: "Lifecycle fixture failed."), to: outputURL)
                                NSApp.terminate(nil)
                                return
                            }
                        } else if scenario == "first-session" {
                            self.model.prepareVisualReview(empty: true)
                            self.model.selectedSection = .home
                        } else {
                            self.model.prepareVisualReview(
                                incubating: scenario != "collection-locked",
                                collectionDuplicate: scenario == "collection-duplicates",
                                previewLockedAnimals: scenario == "collection-locked")
                            self.model.selectedSection = .collection
                        }
                        let controller = InteractiveReviewController(model: self.model)
                        self.interactiveReviewController = controller
                        controller.show()
                        self.writeSmokeTestReport(self.smokeTestReport(), to: outputURL)
                        return
                    }
                    if let directory = ProcessInfo.processInfo.environment["EVOBAR_VISUAL_REVIEW_DIRECTORY"],
                       directory.hasPrefix("/"), directory != "/" {
                        do {
                            try await WindowLayoutReview.verify(model: self.model)
                            try await KeyboardNavigationReview.verify(model: self.model)
                            try await VisualReviewExporter.export(model: self.model, directory: URL(fileURLWithPath: directory))
                        } catch {
                            self.writeSmokeTestReport(
                                AppSmokeTestReport(status: "failed", detail: "Visual review export failed."),
                                to: outputURL
                            )
                            NSApp.terminate(nil)
                            return
                        }
                    }
#endif
                    self.writeSmokeTestReport(self.smokeTestReport(), to: outputURL)
                    NSApp.terminate(nil)
                    return
                case .failed(let message):
                    self.writeSmokeTestReport(
                        AppSmokeTestReport(status: "failed", detail: message),
                        to: outputURL
                    )
                    NSApp.terminate(nil)
                    return
                case .loading:
                    try? await Task.sleep(for: .milliseconds(100))
                }
            }
            self.writeSmokeTestReport(
                AppSmokeTestReport(status: "failed", detail: "App initialization timed out."),
                to: outputURL
            )
            NSApp.terminate(nil)
        }
    }

    private func smokeTestReport() -> AppSmokeTestReport {
        guard let catalog = model.catalog,
              catalog.animals.count == 7,
              let storefront = model.storefront,
              !storefront.products.isEmpty,
              let asset = model.menuBarAsset,
              BundledAnimalSpriteStore.imageData(for: asset) != nil,
              (try? AppConfiguration.bundled()) != nil else {
            return AppSmokeTestReport(
                status: "failed",
                detail: "Required manifest, configuration, or companion asset was unavailable."
            )
        }
        return AppSmokeTestReport(
            status: "ready",
            detail: "Initialized isolated persistence, app configuration, manifests, and menu-bar companion."
        )
    }

    private func writeSmokeTestReport(_ report: AppSmokeTestReport, to outputURL: URL) {
        do {
            try FileManager.default.createDirectory(
                at: outputURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(report).write(to: outputURL, options: .atomic)
        } catch {
            FileHandle.standardError.write(Data("Could not write EvoBar smoke report.\n".utf8))
        }
    }
}

private struct AppSmokeTestReport: Encodable {
    let status: String
    let detail: String
}
