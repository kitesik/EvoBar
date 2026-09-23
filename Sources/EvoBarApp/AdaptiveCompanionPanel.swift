import Combine
import SwiftUI

struct HomeContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

struct HomeViewportHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private struct CompanionPanelSizeKey: EnvironmentKey {
    static let defaultValue = CGSize(width: EvoStyle.width, height: EvoStyle.height)
}

extension EnvironmentValues {
    var companionPanelSize: CGSize {
        get { self[CompanionPanelSizeKey.self] }
        set { self[CompanionPanelSizeKey.self] = newValue }
    }
}

/// Updating the dimensions keeps the same SwiftUI root and its navigation,
/// search, and sheet state when the panel moves to a differently sized display.
@MainActor
final class CompanionPanelLayout: ObservableObject {
    @Published var size = CGSize(width: EvoStyle.width, height: EvoStyle.height)
    /// Room kept clear at the top for window chrome drawn over the content.
    @Published var topInset: CGFloat = 0
    @Published var preferredHeight: CGFloat = EvoStyle.height
}

struct AdaptiveCompanionPanel: View {
    @ObservedObject var model: AppModel
    @ObservedObject var layout: CompanionPanelLayout
    @State private var contentHeight: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0

    var body: some View {
        RootPopoverView(
            model: model, panelHeight: layout.size.height, panelWidth: layout.size.width,
            topInset: layout.topInset)
        .onPreferenceChange(HomeContentHeightKey.self) { height in
            Task { @MainActor in contentHeight = height; resizeHome() }
        }
        .onPreferenceChange(HomeViewportHeightKey.self) { height in
            Task { @MainActor in viewportHeight = height; resizeHome() }
        }
        .onChange(of: model.selectedSection) { _, _ in resizeHome() }
    }

    private func resizeHome() {
        let height: CGFloat
        if model.selectedSection == .home, model.onboardingCompleted,
           contentHeight > 0, viewportHeight > 0 {
            // Measure the actual chrome too: translations and update banners can change it.
            height = ceil(layout.size.height - viewportHeight + contentHeight)
        } else {
            height = EvoStyle.height
        }
        if abs(layout.preferredHeight - height) > 1 { layout.preferredHeight = height }
    }
}
