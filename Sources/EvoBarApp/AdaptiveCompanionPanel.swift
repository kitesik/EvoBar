import Combine
import SwiftUI

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
}

struct AdaptiveCompanionPanel: View {
    @ObservedObject var model: AppModel
    @ObservedObject var layout: CompanionPanelLayout

    var body: some View {
        RootPopoverView(
            model: model, panelHeight: layout.size.height, panelWidth: layout.size.width,
            topInset: layout.topInset)
    }
}
