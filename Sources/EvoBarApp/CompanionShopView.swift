import EvoBarCore
import SwiftUI

struct ShopView: View {
  @ObservedObject var model: AppModel

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text(L10n.text("Shop")).font(.system(size: 15, weight: .semibold, design: .rounded))
          Spacer()
          EvoBadge(
            title: AppModel.compactTokens(model.tokenCoins), icon: "circle.hexagongrid",
            tint: .orange)
        }

        EvoCard(tint: .orange) {
          VStack(alignment: .leading, spacing: 5) {
            Text(L10n.text("Wallet")).font(.system(size: 11)).foregroundStyle(.secondary)
            Text("\(AppModel.compactTokens(model.tokenCoins)) \(L10n.text("coins"))")
              .font(.system(size: 27, weight: .semibold, design: .rounded)).monospacedDigit()
            Text(
              L10n.text(
                "ui.coinHint", fallback: "Earned from your work. Spend them on a little care.")
            )
            .font(.system(size: 11)).foregroundStyle(.secondary)
          }
        }

        ForEach((model.economy?.items ?? []).sorted { $0.tokenCoinPrice < $1.tokenCoinPrice }) {
          item in
          itemCard(item)
        }

        // Purchases are not live, so the only thing to restore is a signed
        // licence someone was given. Small, and at the bottom where it belongs.
        if model.purchasesAvailable || model.licenseImportAvailable {
          HStack {
            Button(L10n.text("Restore purchases")) { model.restorePurchases() }
              .disabled(!model.purchasesAvailable || model.purchasingProductID != nil)
            Spacer()
            if model.licenseImportAvailable {
              Button(L10n.text("Import license…")) { model.importLicense() }
                .disabled(model.purchasingProductID != nil)
            }
          }.font(.system(size: 11))
        }
      }
      .padding(.horizontal, EvoStyle.inset)
      .padding(.bottom, 16)
    }
    .scrollIndicators(.hidden)
    .safeAreaInset(edge: .bottom, spacing: 0) {
      if let message = model.itemPurchaseMessage {
        EvoFeedbackBanner(message: message) { model.dismissItemFeedback() }
          .accessibilityIdentifier("shop.feedback")
      }
    }
  }

  private func itemCard(_ item: GameItemDefinition) -> some View {
    EvoCard {
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 12) {
          Image(systemName: itemSymbol(item.kind))
            .font(.system(size: 23, weight: .light)).foregroundStyle(EvoStyle.accent)
            .frame(width: 44, height: 44)
            .background(EvoStyle.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 11))
          VStack(alignment: .leading, spacing: 4) {
            Text(L10n.item(item)).font(.system(size: 13, weight: .semibold))
            Text(itemDescription(item)).font(.system(size: 11)).foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        HStack {
          Text(
            model.freeItems
              ? L10n.text("ui.free", fallback: "Free")
              : "\(item.tokenCoinPrice) \(L10n.text("coins"))"
          )
          .font(.system(size: 11)).foregroundStyle(.secondary)
          Spacer()
          if item.kind == .sceneTheme, model.ownsItem(item.id) || model.freeItems {
            // A backdrop is worn or it is not; owning several is the point of any.
            let worn = model.sceneThemeID == item.id
            Button(
              worn
                ? L10n.text("ui.wearing", fallback: "Wearing")
                : L10n.text("ui.wear", fallback: "Wear")
            ) {
              model.setSceneTheme(item.id)
            }
            .buttonStyle(EvoActionStyle(prominent: worn))
          } else if item.kind == .shinyCharm, model.hasShinyCharm {
            EvoBadge(title: L10n.text("Owned"), icon: "checkmark")
          } else if model.purchasingItemID == item.id {
            ProgressView().controlSize(.small)
          } else {
            Button(L10n.text("ui.getItem", fallback: "Get item")) { model.purchaseGameItem(item) }
              .buttonStyle(EvoActionStyle())
              .disabled(
                (!model.freeItems && model.tokenCoins < item.tokenCoinPrice)
                  || model.purchasingItemID != nil)
          }
        }
      }
    }
  }
  private func itemSymbol(_ kind: GameItemKind) -> String {
    switch kind {
    case .rareCandy: "sparkles"
    case .mint: "leaf"
    case .shinyCharm: "star"
    case .randomEgg: "oval.portrait"
    case .treat: "heart"
    case .sceneTheme: "photo"
    }
  }
  private func itemDescription(_ item: GameItemDefinition) -> String {
    switch item.kind {
    case .rareCandy:
      L10n.format(
        "ui.candyDescription", fallback: "Give your companion %lld XP.", item.xpGrant ?? 0)
    case .mint:
      L10n.text("ui.mintDescription", fallback: "Discover a different side of their personality.")
    case .shinyCharm:
      L10n.text("ui.charmDescription", fallback: "A little more luck for future shiny hatches.")
    case .randomEgg:
      L10n.text("ui.eggDescription", fallback: "Incubate a surprise companion over three working days.")
    case .treat: L10n.text("ui.treatDescription", fallback: "A small treat to bring you closer.")
    case .sceneTheme:
      L10n.text("ui.sceneDescription", fallback: "A backdrop for the scene your companion walks in.")
    }
  }
}
