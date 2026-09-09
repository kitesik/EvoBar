import Combine
import SwiftUI

private struct CompanionPanelSizeKey: EnvironmentKey {
    static let defaultValue = CGSize(width: 420, height: 700)
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
}

struct AdaptiveCompanionPanel: View {
    @ObservedObject var model: AppModel
    @ObservedObject var layout: CompanionPanelLayout

    var body: some View {
        RootPopoverView(model: model, panelHeight: layout.size.height, panelWidth: layout.size.width)
    }
}
