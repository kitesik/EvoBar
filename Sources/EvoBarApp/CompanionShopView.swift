import EvoBarCore
import SwiftUI

struct ShopView: View {
  @ObservedObject var model: AppModel
  @State private var showingItems = false
  @State private var showTestOptions = false

  init(model: AppModel, showingItems: Bool = false) {
    self.model = model
    _showingItems = State(initialValue: showingItems)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        HStack(alignment: .firstTextBaseline) {
          VStack(alignment: .leading, spacing: 3) {
            Text(L10n.text("Shop")).font(.system(size: 21, weight: .bold, design: .rounded))
            Text(
              L10n.text("ui.shopSubtitle", fallback: "Find your next companion. Make it a story.")
            )
            .font(.system(size: 11)).foregroundStyle(.secondary)
          }
          Spacer()
          EvoBadge(
            title: AppModel.compactTokens(model.tokenCoins), icon: "circle.hexagongrid",
            tint: .orange)
        }
        Picker(L10n.text("Shop"), selection: $showingItems) {
          Text("Animals").tag(false)
          Text("Items").tag(true)
        }.pickerStyle(.segmented).labelsHidden()

        if showingItems {
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
        } else {
          if model.isStorefrontTestMode {
            DisclosureGroup(isExpanded: $showTestOptions) {
              Picker(
                "Outcome",
                selection: Binding(
                  get: { model.storefrontTestScenario },
                  set: { model.updateStorefrontTestScenario($0) }
                )
              ) {
                ForEach(StorefrontTestScenario.allCases) { Text($0.displayName).tag($0) }
              }.pickerStyle(.segmented)
              Text(
                "No real charge is made. Entitlements are stored locally for development testing."
              )
              .font(.caption2).foregroundStyle(.secondary)
            } label: {
              Label("Storefront test mode", systemImage: "hammer")
                .font(.system(size: 11, weight: .medium))
            }
            .padding(10).background(
              Color.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
          } else if !model.purchasesAvailable {
            Label(
              L10n.text(
                "ui.shopPreview", fallback: "A preview of what's next. Purchases open soon."),
              systemImage: "info.circle"
            )
            .font(.system(size: 11)).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
          }
          ForEach(products) { product in productCard(product) }
          HStack {
            Button("Restore purchases") { model.restorePurchases() }
              .disabled(!model.purchasesAvailable || model.purchasingProductID != nil)
            Spacer()
            if model.licenseImportAvailable {
              Button("Import license…") { model.importLicense() }
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
      if let message = showingItems ? model.itemPurchaseMessage : model.purchaseMessage {
        Label(message, systemImage: "info.circle")
          .font(.system(size: 11))
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(12)
          .background(EvoStyle.surface)
          .overlay(alignment: .top) { Divider() }
          .accessibilityIdentifier("shop.feedback")
      }
    }
  }

  private var products: [StorefrontProductDefinition] {
    (model.storefront?.products ?? []).sorted {
      let firstPending = model.productAwaitsArtwork($0)
      let secondPending = model.productAwaitsArtwork($1)
      if firstPending != secondPending { return !firstPending }
      return $0.sortOrder < $1.sortOrder
    }
  }

  private func productCard(_ product: StorefrontProductDefinition) -> some View {
    let animal =
      product.kind == .animal
      ? model.catalog?.animals.first { $0.id == product.grantsAnimalIDs.first }
      : nil
    let owned = product.grantsAnimalIDs.allSatisfy { model.ownedAnimalIDs.contains($0) }
    let pending = model.productAwaitsArtwork(product)
    return EvoCard {
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 12) {
          if let animal, BundledAnimalSpriteStore.hasArtwork(for: animal) {
            AnimalSpriteView(animal: animal, size: 46)
              .frame(width: 54, height: 54)
              .background(
                Color(hex: animal.themeColorHex).opacity(0.06),
                in: RoundedRectangle(cornerRadius: 12))
          } else {
            Image(systemName: product.kind == .animal ? "pawprint.fill" : "square.stack.3d.up")
              .font(.system(size: 24)).foregroundStyle(.tertiary)
              .frame(width: 54, height: 54)
              .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
          }
          VStack(alignment: .leading, spacing: 4) {
            Text(L10n.product(product)).font(.system(size: 13, weight: .semibold)).lineLimit(2)
            Text(
              product.kind == .animal
                ? L10n.text("Original five-stage evolution line")
                : L10n.format(
                  "product.bundle.lines", fallback: "Bundle of %lld animal lines",
                  Int64(product.grantsAnimalIDs.count))
            )
            .font(.system(size: 10)).foregroundStyle(.secondary)
          }
          Spacer(minLength: 0)
          if owned {
            EvoBadge(title: L10n.text("Owned"), icon: "checkmark")
          } else if pending {
            EvoBadge(title: L10n.text("shop.comingSoon", fallback: "Coming soon"), tint: .secondary)
          } else if model.purchasingProductID == product.id {
            ProgressView().controlSize(.small)
          } else {
            Button("$\(product.fallbackPriceUSD)") { model.purchase(product.id) }
              .buttonStyle(EvoActionStyle())
              .disabled(!model.purchasesAvailable || model.purchasingProductID != nil)
          }
        }
        if let animal, !pending {
          EvolutionJourney(animal: animal, discoveredStage: 0, preview: true)
        }
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
          Text("\(item.tokenCoinPrice) \(L10n.text("coins"))")
            .font(.system(size: 11)).foregroundStyle(.secondary)
          Spacer()
          if item.kind == .shinyCharm, model.hasShinyCharm {
            EvoBadge(title: L10n.text("Owned"), icon: "checkmark")
          } else if model.purchasingItemID == item.id {
            ProgressView().controlSize(.small)
          } else {
            Button(L10n.text("ui.getItem", fallback: "Get item")) { model.purchaseGameItem(item) }
              .buttonStyle(EvoActionStyle())
              .disabled(model.tokenCoins < item.tokenCoinPrice || model.purchasingItemID != nil)
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
      L10n.text("ui.eggDescription", fallback: "Start a surprise companion after graduation.")
    case .treat: L10n.text("ui.treatDescription", fallback: "A small treat to bring you closer.")
    }
  }
}
