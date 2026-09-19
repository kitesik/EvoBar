import EvoBarCore
import SwiftUI

/// One small invitation below the companion. Full egg management stays in Collection.
struct IncubatorPrompt: View {
  @ObservedObject var model: AppModel

  private var egg: IncubatingEgg? { IncubatingEgg.focus(in: model.incubator) }

  var body: some View {
    EvoCard {
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 10) {
          EvoEggView(tint: EvoStyle.accent, size: 28)
          VStack(alignment: .leading, spacing: 3) {
            Text(egg?.isReady == true
                 ? L10n.text("incubator.ready", fallback: "Ready to open")
                 : L10n.text("incubator.title", fallback: "Incubator"))
              .font(.system(size: 12, weight: .semibold))
            if let egg, !egg.isReady {
              Text(L10n.format("incubator.remaining", fallback: "%lld more working days", Int64(egg.daysRemaining)))
                .font(.system(size: 10)).foregroundStyle(.secondary)
            } else if egg == nil {
              Text(L10n.text("incubator.held", fallback: "An egg is waiting to grow."))
                .font(.system(size: 10)).foregroundStyle(.secondary)
            }
          }
          Spacer(minLength: 0)
          if let egg, egg.isReady {
            Button(L10n.text("incubator.open", fallback: "Open egg")) { model.openEgg(id: egg.id) }
              .buttonStyle(EvoActionStyle(prominent: true)).disabled(!model.canOpenEgg)
          } else if egg == nil, model.randomEggCount > 0 {
            Button(L10n.text("incubator.place", fallback: "Place an egg")) { model.placeEggInIncubator() }
              .buttonStyle(EvoActionStyle()).disabled(!model.canPlaceEgg)
          } else {
            Button(L10n.text("incubator.details", fallback: "View")) { model.selectedSection = .collection }
              .buttonStyle(EvoActionStyle())
          }
        }
        if let message = model.incubatorMessage {
          Text(message).font(.caption2).foregroundStyle(.secondary)
        }
      }
    }
    .accessibilityIdentifier("home.nextEgg")
  }
}
