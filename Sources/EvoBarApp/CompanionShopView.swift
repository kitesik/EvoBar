import EvoBarCore
import SwiftUI

struct ShopView: View {
  @ObservedObject var model: AppModel
  @State private var optionsExpanded: Bool
  @State private var previewItem: GameItemDefinition?

  init(model: AppModel, optionsExpanded: Bool = false) {
    self.model = model
    _optionsExpanded = State(initialValue: optionsExpanded)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text(L10n.text("Shop")).font(.system(size: 15, weight: .semibold, design: .rounded))
          Spacer()
          EvoBadge(
            title: "\(AppModel.compactTokens(model.tokenCoins)) \(L10n.text("coins"))", icon: "circle.hexagongrid")
            .accessibilityLabel("\(model.tokenCoins) \(L10n.text("coins"))")
        }

        Text(L10n.text("ui.shopPurpose", fallback: "Meet a new companion, or give yours a little care. Growth comes from your everyday work."))
          .font(.system(size: 11)).foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)

        ForEach(model.shopEssentials) { item in
          itemCard(item)
        }

        if !model.shopScenery.isEmpty {
          Text(L10n.text("ui.sceneryGallery", fallback: "Browse scenery"))
            .font(.system(size: 13, weight: .semibold))
          ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 10) {
              ForEach(model.shopScenery) { item in
                itemCard(item).frame(width: 214)
              }
            }.padding(.bottom, 4)
          }
          .accessibilityIdentifier("shop.scenery")
        }

        DisclosureGroup(isExpanded: $optionsExpanded) {
          VStack(spacing: 10) {
            ForEach(model.shopExtras) { item in itemCard(item) }
          }.padding(.top, 8)
        } label: {
          Text(L10n.text("ui.shopExtras", fallback: "More items"))
            .font(.system(size: 12, weight: .medium))
        }
        .accessibilityIdentifier("shop.extras")

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
    .sheet(item: $previewItem) { item in
      if let theme = SceneTheme(itemID: item.id) {
        VStack(alignment: .leading, spacing: 14) {
          HStack {
            Text(L10n.item(item)).font(.headline)
            Spacer()
            Button(L10n.text("Done")) { previewItem = nil }
              .keyboardShortcut(.cancelAction)
          }
          sceneryPreview(theme, height: 190)
          Text(L10n.text("ui.sceneryPreviewHint", fallback: "Preview only. Your coins and current scenery stay unchanged."))
            .font(.caption).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20).frame(width: 360)
      }
    }
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
        if let theme = SceneTheme(itemID: item.id), item.kind == .sceneTheme {
          Button { previewItem = item } label: {
            sceneryPreview(theme, height: 100)
          }
          .buttonStyle(.plain)
          .accessibilityLabel(L10n.format("ui.previewScenery", fallback: "Preview %@ scenery", L10n.item(item)))
          .accessibilityIdentifier("shop.preview.\(theme.rawValue)")
        }
        HStack(spacing: 12) {
          if item.kind != .sceneTheme {
            Image(systemName: itemSymbol(item.kind))
              .font(.system(size: 23, weight: .light)).foregroundStyle(EvoStyle.accent)
              .frame(width: 44, height: 44)
              .background(EvoStyle.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 11))
          }
          VStack(alignment: .leading, spacing: 4) {
            Text(L10n.item(item)).font(.system(size: 13, weight: .semibold))
            if item.kind != .sceneTheme {
              Text(itemDescription(item)).font(.system(size: 11)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
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
            .accessibilityLabel("\(L10n.text(worn ? "ui.wearing" : "ui.wear", fallback: worn ? "Wearing" : "Wear")), \(L10n.item(item))")
            .accessibilityAddTraits(worn ? [.isSelected] : [])
          } else if item.kind == .shinyCharm, model.hasShinyCharm {
            EvoBadge(title: L10n.text("Owned"), icon: "checkmark")
          } else if model.purchasingItemID == item.id {
            ProgressView().controlSize(.small)
          } else {
            Button(L10n.text("ui.getItem", fallback: "Get item")) { model.purchaseGameItem(item) }
              .buttonStyle(EvoActionStyle())
              .accessibilityLabel("\(L10n.text("ui.getItem", fallback: "Get item")), \(L10n.item(item))")
              .accessibilityValue(model.freeItems
                ? L10n.text("ui.free", fallback: "Free")
                : "\(item.tokenCoinPrice) \(L10n.text("coins"))")
              .accessibilityIdentifier("shop.get.\(item.id)")
              .disabled(
                (!model.freeItems && model.tokenCoins < item.tokenCoinPrice)
                  || model.purchasingItemID != nil)
          }
        }
      }
    }
  }

  // Read-only shared preview, also exercised by the isolated native review.
  func sceneryPreview(_ theme: SceneTheme, height: CGFloat) -> some View {
    GeometryReader { geometry in
      if let animal = model.currentAnimal {
        CompanionSceneView(
          reference: ManifestAnimalAssetProvider().asset(
            for: animal, stageIndex: model.acknowledgedStageIndex,
            isShiny: model.currentAnimalInstance?.isShiny ?? false, visualState: .idle),
          visualState: .idle, locomotion: animal.locomotion ?? .walk,
          themeColor: Color(hex: animal.themeColorHex), quality: .powerSaver,
          sceneTheme: theme, isActive: false, width: geometry.size.width,
          height: height, spriteSize: height > 120 ? 84 : 60)
      } else {
        SceneLandscapeView(theme: theme, time: 0, travel: 0, groundHeight: 22)
          .clipShape(RoundedRectangle(cornerRadius: 12))
      }
    }
    .frame(height: height)
    .accessibilityHidden(true)
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
