import EvoBarCore
import EvoBarEvolution
import SwiftUI

struct CompanionHomeView: View {
  @ObservedObject var model: AppModel
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isShowingGraduation = false
  @State private var ceremonyStartedAt: Date?
  @State private var hatchStartedAt: Date?
  @State private var petResponse = false
  @State private var bursts: [CareBurst] = []
  @State private var anchors: [String: CGRect] = [:]
  @State private var heartsBeat = false
  /// Names the roll for a moment after a lucky or golden arrival.
  @State private var bonusNote: String?
  /// What the companion is saying, while it says it.
  @State private var bubble: SpeechBubble?

  var body: some View {
    content
      .overlay { ceremonyOverlay }
      .sheet(isPresented: $isShowingGraduation) { GraduationView(model: model) }
      .onAppear(perform: appeared)
      .task {
        // Now and then, while the panel stays open, the companion says something.
        while !Task.isCancelled {
          try? await Task.sleep(for: .seconds(Double.random(in: 45...90)))
          guard !Task.isCancelled, model.isPanelVisible else { continue }
          say(.idle)
        }
      }
      .onChange(of: model.evolutionCeremony, ceremonyChanged)
      .onChange(of: model.hatchCeremony, hatchChanged)
      .onChange(of: model.pendingXP, pendingChanged)
      .onChange(of: model.absorptionCount, absorptionChanged)
  }

  private var content: some View {
    ScrollView {
      VStack(spacing: 12) {
        if let recap = model.weeklyRecap {
          WeeklyRecapCard(recap: recap, stages: model.stagesReached(from: recap.start, to: recap.end)) {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
              model.dismissWeeklyRecap()
            }
          }
        }
        companionCard
        todayCard
        weekCard
      }
      .padding(.horizontal, EvoStyle.inset)
      .padding(.bottom, 16)
    }
    .scrollIndicators(.hidden)
  }

  private func ceremonyChanged(_ previous: EvolutionCeremony?, _ ceremony: EvolutionCeremony?) {
    ceremonyStartedAt = ceremony == nil ? nil : Date()
  }

  private func hatchChanged(_ previous: HatchCeremony?, _ hatch: HatchCeremony?) {
    hatchStartedAt = hatch == nil ? nil : Date()
  }

  private func pendingChanged(_ previous: Int64, _ waiting: Int64) {
    if waiting > 0 { model.absorbGrowthIfNeeded() }
  }

  private func absorptionChanged(_ previous: Int, _ count: Int) {
    showArrival()
    say(.growth)
  }

  private func appeared() {
    model.absorbGrowthIfNeeded()
    model.hatchReadyEggIfNeeded()
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(400))
      say(.greeting)
    }
  }

  /// Picks a line for the moment in the companion's own voice and shows it
  /// over the scene for a few seconds. A newer line replaces an older one.
  private func say(_ occasion: VoiceOccasion) {
    guard let nature = model.currentAnimalInstance?.natureID else { return }
    let key = CompanionVoice.key(
      nature: nature, mood: model.affectionMood, state: model.companionVisualState,
      occasion: occasion, roll: Int.random(in: 0..<600))
    let text = L10n.text(key, fallback: "")
    guard !text.isEmpty else { return }
    let spoken = SpeechBubble(text: text)
    withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7)) { bubble = spoken }
    Task { @MainActor in
      try? await Task.sleep(for: .seconds(4.5))
      guard bubble == spoken else { return }
      withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) { bubble = nil }
    }
  }

  /// An evolution or a hatch plays over the whole tab; never both at once.
  @ViewBuilder private var ceremonyOverlay: some View {
    if let ceremony = model.evolutionCeremony {
      TimelineView(.animation(minimumInterval: reduceMotion ? 0.25 : 1 / 30)) { context in
        EvolutionCeremonyView(
          ceremony: ceremony,
          elapsed: context.date.timeIntervalSince(ceremonyStartedAt ?? context.date)
        )
      }
      .transition(.opacity)
    } else if let hatch = model.hatchCeremony {
      TimelineView(.animation(minimumInterval: reduceMotion ? 0.25 : 1 / 30)) { context in
        HatchCeremonyView(
          ceremony: hatch,
          elapsed: context.date.timeIntervalSince(hatchStartedAt ?? context.date)
        )
      }
      .transition(.opacity)
    }
  }

  /// XP has just landed: fly it to the companion and, for a lucky or golden
  /// roll, name the roll for a moment.
  private func showArrival() {
    guard let arrived = model.lastAbsorption else { return }
    burst(.growth, from: nil, xp: arrived.total, tier: arrived.tier)
    let note = [Self.bonusText(arrived), Self.giftText(arrived.gift)]
      .compactMap { $0 }.joined(separator: "  ")
    guard !note.isEmpty else { return }
    withAnimation(.easeOut(duration: 0.2)) { bonusNote = note }
    Task { @MainActor in
      try? await Task.sleep(for: .seconds(4))
      withAnimation(.easeOut(duration: 0.3)) { bonusNote = nil }
    }
  }

  private static func bonusText(_ arrived: GrowthAbsorption) -> String? {
    switch arrived.tier {
    case .golden:
      L10n.format(
        "care.bonus.golden", fallback: "Golden! +%lld XP and %lld coins on top",
        arrived.bonus, arrived.coins)
    case .lucky:
      L10n.format("care.bonus.lucky", fallback: "Lucky! +%lld XP on top", arrived.bonus)
    case nil:
      nil
    }
  }

  /// The first growth of a day always brings something, so this names what.
  private static func giftText(_ gift: DailyGift?) -> String? {
    guard let gift else { return nil }
    if gift.eggs > 0 {
      return L10n.format(
        "care.gift.egg", fallback: "Today's gift: %lld coins and a Random Egg", gift.coins)
    }
    if gift.xp > 0 {
      return L10n.format(
        "care.gift.candy", fallback: "Today's gift: %lld coins and +%lld XP", gift.coins, gift.xp)
    }
    return L10n.format("care.gift.coins", fallback: "Today's gift: %lld coins", gift.coins)
  }

  private var companionCard: some View {
    EvoCard(tint: model.isEvolutionReady ? EvoStyle.accent : nil) {
      companionCardContent
        .coordinateSpace(name: "companionCard")
        .onPreferenceChange(CareAnchorKey.self) { value in
          Task { @MainActor in anchors = value }
        }
        .overlay { CareBurstLayer(bursts: bursts) }
    }
  }

  private var companionCardContent: some View {
      VStack(alignment: .leading, spacing: 12) {
        if let animal = model.currentAnimal {
          GeometryReader { geometry in
            CompanionSceneView(
              reference: ManifestAnimalAssetProvider().asset(
                for: animal, stageIndex: model.acknowledgedStageIndex,
                isShiny: model.currentAnimalInstance?.isShiny ?? false,
                visualState: model.companionVisualState),
              visualState: model.companionVisualState,
              locomotion: animal.locomotion ?? .walk,
              themeColor: Color(hex: animal.themeColorHex),
              quality: model.animationQuality,
              sceneTheme: model.sceneTheme,
              width: geometry.size.width, height: 116, spriteSize: 72
            )
          }
          .frame(height: 116)
          .overlay(alignment: .top) {
            if let bubble {
              SpeechBubbleView(text: bubble.text)
                .padding(.top, 8)
                .offset(x: 14)
                .transition(.scale(scale: 0.8, anchor: .bottom).combined(with: .opacity))
            }
          }
          .careAnchor("scene")
          .scaleEffect(petResponse && !reduceMotion ? 1.02 : 1)
          .overlay(alignment: .topTrailing) {
            // With motion reduced the burst is skipped, so the heart appears here.
            if petResponse, reduceMotion {
              Image(systemName: "heart.fill").foregroundStyle(.pink)
                .font(.system(size: 14)).padding(8).transition(.opacity)
            }
          }
          .contentShape(Rectangle())
          .onTapGesture(count: 1, coordinateSpace: .named("companionCard")) { location in
            pet(from: location)
          }
          .help(L10n.text("care.pet.hint", fallback: "Click your companion to pet it"))
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(L10n.text("care.pet.action", fallback: "Pet"))
          .accessibilityAddTraits(.isButton)
        }
        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Text(model.companionName)
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .lineLimit(1).truncationMode(.tail)
            .help(model.companionName)
          if model.currentAnimalInstance?.isShiny == true {
            Image(systemName: "sparkles").foregroundStyle(CareBurstLayer.gold).font(.system(size: 12))
              .help(L10n.text("hatch.shiny", fallback: "Shiny"))
          }
          if let nature = model.currentAnimalInstance?.natureID {
            Text(L10n.nature(nature))
              .font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
              .lineLimit(1).fixedSize()
              .help(L10n.natureFlavor(nature))
          }
          Spacer(minLength: 6)
          EvoBadge(title: stateTitle, icon: stateIcon)
        }
        HStack(spacing: 6) {
          Text(model.currentStage.map(L10n.stage) ?? L10n.text("Growing companion"))
            .font(.system(size: 12, weight: .medium)).lineLimit(1)
          Text(
            L10n.format(
              "ui.stageOf", fallback: "Stage %lld / %lld", Int64(model.acknowledgedStageIndex),
              Int64(model.currentAnimal?.stages.count ?? 5))
          )
          .font(.system(size: 10)).foregroundStyle(.secondary)
          if let rarity = model.currentAnimalInstance?.rarity, rarity != .common {
            EvoBadge(title: L10n.rarity(rarity), tint: EvoStyle.rarityColor(rarity))
          }
          Spacer(minLength: 6)
          HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
              Image(systemName: index < filledHearts ? "heart.fill" : "heart")
                .font(.system(size: 9))
                .foregroundStyle(
                  index < filledHearts ? Color.pink.opacity(0.8) : Color.secondary.opacity(0.35))
            }
            // The hearts already say how the companion feels; the words beside
            // them say how far the two of you have come, which keeps rising
            // long after the hearts have filled.
            Text(L10n.text(model.bondLevel.titleKey, fallback: "Companion"))
              .font(.system(size: 10, weight: .medium))
              .foregroundStyle(model.bondLevel == .inseparable ? CareBurstLayer.gold : .secondary)
              .padding(.leading, 3).lineLimit(1).fixedSize()
          }
          .scaleEffect(heartsBeat ? 1.18 : 1, anchor: .trailing)
          .help(bondHelp)
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(bondHelp)
        }

        VStack(alignment: .leading, spacing: 7) {
          HStack(alignment: .firstTextBaseline) {
            Text(
              model.nextStage.map {
                L10n.format("home.toStage", fallback: "To %@", L10n.stage($0))
              } ?? L10n.text("Final evolution")
            )
            .font(.system(size: 11, weight: .medium)).lineLimit(1)
            Spacer()
            if model.pendingXP > 0 {
              // What is about to arrive, in the colour it will land in.
              Text(verbatim: "+\(model.pendingXP)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(EvoStyle.accent).monospacedDigit()
                .transition(.opacity)
            }
            Text(
              model.nextStage.map {
                L10n.format(
                  "ui.xpRemaining", fallback: "%lld XP to go",
                  max(0, $0.xpThreshold - model.currentXP))
              } ?? L10n.text("ui.journeyComplete", fallback: "Journey complete")
            )
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary).monospacedDigit()
            .contentTransition(.numericText(countsDown: true))
            .animation(reduceMotion ? nil : .smooth(duration: 0.9), value: model.currentXP)
          }
          EvoProgressBar(value: model.progress, preview: model.previewProgress)
            .careAnchor("growth")
        }

        if model.isEvolutionReady, let next = model.nextStage {
          Button {
            model.evolve()
          } label: {
            Label(
              L10n.format("ui.evolve", fallback: "Evolve to %@", L10n.stage(next)),
              systemImage: "sparkles"
            )
            .frame(maxWidth: .infinity)
          }
          .buttonStyle(EvoActionStyle(prominent: true))
          .disabled(model.isEvolving)
        } else if model.isGraduationReady {
          Button {
            isShowingGraduation = true
          } label: {
            Label("Graduate and choose what’s next", systemImage: "graduationcap.fill")
              .frame(maxWidth: .infinity)
          }.buttonStyle(EvoActionStyle(prominent: true))
        } else {
          HStack(spacing: 8) {
            Button {
              pet(from: nil)
            } label: {
              Label(L10n.text("care.pet.action", fallback: "Pet"), systemImage: "hand.draw")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(EvoActionStyle())
            .disabled(model.petsRemainingToday == 0)
            .careAnchor("pet")
            if let treat = model.treatItem {
              Button {
                model.purchaseGameItem(treat)
                burst(.treat, from: nil, xp: 0)
              } label: {
                Label(
                  L10n.format(
                    "care.treat.action", fallback: "Treat, %lld coins", treat.tokenCoinPrice),
                  systemImage: "heart.circle"
                ).frame(maxWidth: .infinity)
              }
              .buttonStyle(EvoActionStyle())
              .disabled(!model.canTreatNow)
              .careAnchor("treat")
            }
          }
        }
        if let bonusNote {
          Text(bonusNote).font(.system(size: 10, weight: .semibold))
            .foregroundStyle(CareBurstLayer.gold)
            .fixedSize(horizontal: false, vertical: true)
            .transition(.opacity)
        } else if let message = model.careMessage {
          Text(message).font(.caption2).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        } else if model.pendingXP == 0, !model.isEvolutionReady, !model.isGraduationReady {
          Text(
            L10n.text("ui.growthHint", fallback: "Work with AI and growth arrives here on its own."))
            .font(.system(size: 10)).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
  }

  private var todayCard: some View {
    EvoCard(tint: usageTone) {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Label(
            L10n.text("ui.todayTokens", fallback: "Today's tokens"),
            systemImage: usageTone == nil ? "chart.bar.xaxis" : "flame"
          )
          .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
          Spacer()
          Button {
            model.selectedSection = .usage
          } label: {
            Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .semibold))
          }.buttonStyle(.plain)
            .help(L10n.text("Open usage"))
            .accessibilityLabel(L10n.text("Open usage"))
        }
        HStack(alignment: .firstTextBaseline) {
          Text(AppModel.compactTokens(model.todayTokens))
            .font(.system(size: 30, weight: .semibold, design: .rounded))
            .tracking(-1).monospacedDigit()
            .contentTransition(.numericText())
          Spacer()
          if let usage = model.usageDashboard?.window(.today), let cost = usage.estimatedAPICostUSD
          {
            VStack(alignment: .trailing, spacing: 2) {
              Text(cost.formatted(.currency(code: "USD"))).font(
                .system(size: 15, weight: .semibold)
              ).monospacedDigit()
              Text(
                usage.costCoverage >= 0.999
                  ? L10n.text("ui.apiEstimate", fallback: "API estimate")
                  : L10n.format(
                    "ui.priced", fallback: "%lld%% priced",
                    Int64((usage.costCoverage * 100).rounded()))
              )
              .font(.system(size: 9)).foregroundStyle(.secondary)
            }
          }
        }
        UsageBandGauge(
          tokens: model.todayTokens, thresholds: model.usageBandThresholds,
          tone: usageTone ?? EvoStyle.accent)
        HStack(spacing: 0) {
          smallMetric(L10n.text("Growth"), value: "+\(model.todayXP) XP", icon: "sparkles")
          Divider().frame(height: 25).padding(.horizontal, 14)
          smallMetric(
            L10n.text("Wallet"), value: AppModel.compactTokens(model.tokenCoins),
            icon: "circle.hexagongrid")
          Spacer()
        }
        Divider()
        let providers = model.usageDashboard?.window(.today)?.providers ?? []
        if providers.isEmpty {
          VStack(alignment: .leading, spacing: 6) {
            Text(L10n.text("ui.noUsage", fallback: "Your next session starts the story."))
              .font(.system(size: 12, weight: .medium))
            Text(
              L10n.text(
                "ui.noUsageHint",
                fallback: "Use Claude Code or Codex as usual. New usage appears here automatically."
              )
            )
            .font(.system(size: 11)).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            Button(L10n.text("ui.trackingSettings", fallback: "Tracking settings")) {
              model.openSettings(page: .tracking)
            }
            .buttonStyle(EvoActionStyle())
          }
        } else {
          ForEach(providers) { provider in
            HStack(spacing: 8) {
              Circle().fill(EvoStyle.providerColor(provider.providerID)).frame(width: 6, height: 6)
              Text(EvoStyle.providerName(provider.providerID)).font(
                .system(size: 12, weight: .medium))
              Spacer()
              Text(AppModel.compactTokens(provider.usage.totalTokens)).font(
                .system(size: 12, weight: .semibold, design: .rounded)
              ).monospacedDigit()
              Text(
                "\(Int((Double(provider.usage.totalTokens) / Double(max(1, model.todayTokens)) * 100).rounded()))%"
              )
              .font(.system(size: 10)).foregroundStyle(.secondary)
              .frame(width: 32, alignment: .trailing)
            }
          }
        }
      }
    }
  }

  private var weekCard: some View {
    EvoCard {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text(L10n.text("home.week", fallback: "Last 7 days")).font(
            .system(size: 11, weight: .semibold))
          Spacer()
          Text(AppModel.compactTokens(model.weekRawTokens.reduce(0, +)))
            .font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(
              .secondary)
        }
        UsageWeekChart(values: model.weekRawTokens)
        if let rank = DayRank.rank(today: model.todayTokens, history: model.dailyRawTokens) {
          Text(
            L10n.format(
              "home.dayRank", fallback: "Today ranks #%lld of your last %lld days",
              Int64(rank.rank), Int64(rank.total))
          )
          .font(.system(size: 10)).foregroundStyle(.secondary)
        }
      }
    }
  }

  private func smallMetric(_ title: String, value: String, icon: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(.system(size: 10)).foregroundStyle(.secondary)
      Label(value, systemImage: icon).font(.system(size: 12, weight: .semibold)).monospacedDigit()
    }
  }
  private var usageTone: Color? {
    switch UsageBand.band(for: model.todayTokens, thresholds: model.usageBandThresholds) {
    case .light, .steady: nil
    case .heavy: .orange
    case .extreme: .red
    }
  }
  /// Both scales in words, for the tooltip and for VoiceOver: how the companion
  /// feels today, and how far the two of you have come.
  private var bondHelp: String {
    let mood = L10n.text("mood.\(model.affectionMood.rawValue)", fallback: "Companion")
    let bond = L10n.text(model.bondLevel.titleKey, fallback: "")
    guard let remaining = model.careToNextBondLevel else { return "\(mood), \(bond)" }
    return "\(mood), \(bond), "
      + L10n.format("bond.toNext", fallback: "%lld more acts of care to the next", Int64(remaining))
  }

  private var filledHearts: Int {
    switch model.affectionMood {
    case .sulking: 1
    case .distant: 2
    case .content: 3
    case .happy: 4
    case .adoring: 5
    }
  }
  private var stateTitle: String {
    switch model.companionVisualState {
    case .working: L10n.text("ui.working", fallback: "Working with you")
    case .idle: L10n.text("ui.idle", fallback: "By your side")
    case .sleeping: L10n.text("ui.sleeping", fallback: "Resting")
    case .evolutionReady: L10n.text("ui.evolutionReady", fallback: "Ready to evolve")
    }
  }
  private var stateIcon: String {
    switch model.companionVisualState {
    case .working: "bolt.fill"
    case .idle: "leaf"
    case .sleeping: "moon.fill"
    case .evolutionReady: "sparkles"
    }
  }
  /// `from` is where the companion was clicked, in the card's space; nil when
  /// the button was used, so the burst leaves from the button.
  private func pet(from location: CGPoint?) {
    guard model.petsRemainingToday > 0 else { return }
    withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.65)) {
      petResponse = true
    }
    model.petCompanion()
    burst(.pet, from: location, xp: 0)
    say(.pet)
    Task { @MainActor in
      try? await Task.sleep(for: .seconds(0.8))
      withAnimation(.easeOut(duration: 0.2)) { petResponse = false }
    }
  }

  /// The model has already recorded the care or the growth; this only shows it
  /// landing. The token flies from the control, the click or the growth bar to
  /// the companion's face, the hearts row beats as it lands, and hearts or
  /// stars rise from the face.
  private func burst(
    _ kind: CareBurst.Kind, from start: CGPoint?, xp: Int64, tier: GrowthBonusTier? = nil
  ) {
    guard !reduceMotion, let scene = anchors["scene"] else { return }
    let target = CGPoint(x: scene.midX + 17, y: scene.maxY - 62)
    let control = anchors[kind.anchor]
    let origin = start ?? control.map {
      kind == .growth ? CGPoint(x: $0.maxX - 6, y: $0.midY) : CGPoint(x: $0.midX, y: $0.minY + 6)
    } ?? CGPoint(x: scene.midX, y: scene.maxY)
    let burst = CareBurst(kind: kind, start: origin, target: target, xp: xp, tier: tier, begun: Date())
    bursts.append(burst)
    Task { @MainActor in
      try? await Task.sleep(for: .seconds(CareBurst.flight))
      withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) { heartsBeat = true }
      try? await Task.sleep(for: .seconds(0.45))
      withAnimation(.easeOut(duration: 0.25)) { heartsBeat = false }
      try? await Task.sleep(for: .seconds(CareBurst.duration - CareBurst.flight - 0.45))
      bursts.removeAll { $0.id == burst.id }
    }
  }
}

/// Where the care controls and the scene sit inside the companion card, so a
/// burst can fly from the control pressed to the companion's face.
private struct CareAnchorKey: PreferenceKey {
  static let defaultValue: [String: CGRect] = [:]
  static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
    value.merge(nextValue()) { $1 }
  }
}

private extension View {
  func careAnchor(_ name: String) -> some View {
    background(
      GeometryReader { proxy in
        Color.clear.preference(
          key: CareAnchorKey.self, value: [name: proxy.frame(in: .named("companionCard"))])
      })
  }
}

/// One press of Pet or Treat, or one arrival of XP, drawn over the companion
/// card: a heart or a spark flies to the companion, a ring marks where it
/// lands, and hearts or stars (and the XP that arrived) rise from the face.
/// Purely visual.
struct CareBurst: Identifiable {
  enum Kind {
    case pet, treat, growth
    var anchor: String {
      switch self {
      case .pet: "pet"
      case .treat: "treat"
      case .growth: "growth"
      }
    }
  }
  let id = UUID()
  let kind: Kind
  let start: CGPoint
  let target: CGPoint
  let xp: Int64
  let tier: GrowthBonusTier?
  let begun: Date

  /// Seconds the token takes to reach the companion.
  static let flight: TimeInterval = 0.42
  /// Seconds until the last heart has faded.
  static let duration: TimeInterval = 1.75
}

struct CareBurstLayer: View {
  let bursts: [CareBurst]
  static let gold = Color(red: 1.0, green: 0.78, blue: 0.35)

  var body: some View {
    TimelineView(.animation(minimumInterval: 1 / 30, paused: bursts.isEmpty)) { context in
      Canvas { canvas, _ in
        for burst in bursts {
          draw(burst, elapsed: context.date.timeIntervalSince(burst.begun), in: &canvas)
        }
      }
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private func draw(_ burst: CareBurst, elapsed: TimeInterval, in canvas: inout GraphicsContext) {
    let pink = Color(red: 0.98, green: 0.45, blue: 0.62)
    let spark = burst.tier == nil ? EvoStyle.accent : Self.gold

    // The token arcs up from the control and drops onto the face, growing on the way.
    if elapsed < CareBurst.flight {
      let p = elapsed / CareBurst.flight
      let eased = p * p * (3 - 2 * p)
      let apex = CGPoint(
        x: (burst.start.x + burst.target.x) / 2,
        y: min(burst.start.y, burst.target.y) - 44)
      let position = bezier(burst.start, apex, burst.target, at: eased)
      let scale = 0.7 + 0.6 * sin(p * .pi)
      var layer = canvas
      layer.opacity = 0.35 + 0.65 * min(1, p * 4)
      switch burst.kind {
      case .pet: layer.fill(heart(at: position, size: 13 * scale), with: .color(pink))
      case .treat: layer.fill(heart(at: position, size: 16 * scale), with: .color(pink))
      case .growth: layer.fill(star(at: position, size: 8 * scale), with: .color(spark))
      }
      return
    }

    // A ring spreads from where it landed.
    let since = elapsed - CareBurst.flight
    if since < 0.35 {
      let u = since / 0.35
      var layer = canvas
      layer.opacity = 0.7 * (1 - u)
      layer.stroke(
        Path(ellipseIn: CGRect(x: burst.target.x - 6 - 20 * u, y: burst.target.y - 6 - 20 * u, width: 12 + 40 * u, height: 12 + 40 * u)),
        with: .color(.white), lineWidth: 1.5)
    }

    // Hearts, or stars for growth, drift up from the face one after another,
    // swaying and fading.
    for index in 0..<3 {
      let t = since - Double(index) * 0.14
      guard t >= 0, t < 0.95 else { continue }
      let u = t / 0.95
      let sway = sin(u * .pi * 2 + Double(index) * 2.1) * 6
      let x = burst.target.x + [-9, 7, -1][index] + sway
      let y = burst.target.y - 12 - 52 * u * (1 + 0.12 * Double(index))
      var layer = canvas
      layer.opacity = min(1, u * 6) * pow(1 - u, 0.8)
      if burst.kind == .growth {
        layer.fill(star(at: CGPoint(x: x, y: y), size: index == 1 ? 6 : 4.5), with: .color(spark))
      } else {
        layer.fill(heart(at: CGPoint(x: x, y: y), size: index == 1 ? 12 : 9), with: .color(pink))
      }
    }

    // Growth also shows what arrived.
    if burst.kind == .growth, burst.xp > 0, since < 1.1 {
      let u = since / 1.1
      var layer = canvas
      layer.opacity = min(1, u * 5) * pow(1 - u, 0.7)
      let label = layer.resolve(
        Text(verbatim: "+\(burst.xp) XP")
          .font(.system(size: 11, weight: .bold, design: .rounded))
          .foregroundStyle(spark))
      layer.draw(label, at: CGPoint(x: burst.target.x + 22, y: burst.target.y - 20 - 34 * u))
    }
  }

  private func bezier(_ a: CGPoint, _ control: CGPoint, _ b: CGPoint, at t: Double) -> CGPoint {
    let s = 1 - t
    return CGPoint(
      x: s * s * a.x + 2 * s * t * control.x + t * t * b.x,
      y: s * s * a.y + 2 * s * t * control.y + t * t * b.y)
  }

  private func heart(at center: CGPoint, size: CGFloat) -> Path {
    var path = Path()
    let bottom = CGPoint(x: center.x, y: center.y + size * 0.5)
    let top = CGPoint(x: center.x, y: center.y - size * 0.2)
    path.move(to: bottom)
    path.addCurve(
      to: top,
      control1: CGPoint(x: center.x - size * 1.05, y: center.y - size * 0.15),
      control2: CGPoint(x: center.x - size * 0.5, y: center.y - size * 0.85))
    path.addCurve(
      to: bottom,
      control1: CGPoint(x: center.x + size * 0.5, y: center.y - size * 0.85),
      control2: CGPoint(x: center.x + size * 1.05, y: center.y - size * 0.15))
    path.closeSubpath()
    return path
  }

  /// A four-pointed spark.
  private func star(at center: CGPoint, size: CGFloat) -> Path {
    var path = Path()
    for index in 0..<8 {
      let angle = CGFloat(index) * .pi / 4 - .pi / 2
      let radius = index.isMultiple(of: 2) ? size : size * 0.42
      let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
      if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
    }
    path.closeSubpath()
    return path
  }
}

/// Today's tokens on the scale that heats the tile: four bands with the user's
/// thresholds as ticks, so the number reads as light, steady, heavy or extreme
/// without a band being named. The last band runs to four times the top
/// threshold, where the bar is full.
struct UsageBandGauge: View {
  let tokens: Int64
  let thresholds: [Int64]
  let tone: Color
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private var bounds: [Int64] { AppSettings.validatedUsageBandThresholds(thresholds) }

  /// 0 through 4: which band, and how far into it.
  private var position: Double {
    let edges = [0] + bounds + [bounds[2] * 4]
    for index in 0..<4 where tokens < edges[index + 1] {
      let span = Double(edges[index + 1] - edges[index])
      return Double(index) + Double(tokens - edges[index]) / max(1, span)
    }
    return 4
  }

  var body: some View {
    VStack(spacing: 2) {
      GeometryReader { geometry in
        let width = geometry.size.width
        ZStack(alignment: .leading) {
          Capsule().fill(Color.white.opacity(0.10))
          Capsule().fill(tone).frame(width: tokens > 0 ? max(4, width * position / 4) : 0)
          ForEach(1..<4, id: \.self) { tick in
            Rectangle().fill(Color.white.opacity(0.35)).frame(width: 1, height: 6)
              .position(x: width * Double(tick) / 4, y: 3)
          }
        }
      }
      .frame(height: 6)
      .animation(reduceMotion ? nil : .smooth(duration: 0.6), value: position)
      GeometryReader { geometry in
        ForEach(0..<3, id: \.self) { index in
          Text(Self.label(bounds[index]))
            .font(.system(size: 9, design: .rounded)).foregroundStyle(.secondary).monospacedDigit()
            .position(x: geometry.size.width * Double(index + 1) / 4, y: 6)
        }
      }
      .frame(height: 12)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(L10n.text("ui.todayTokens", fallback: "Today's tokens"))
    .accessibilityValue(AppModel.compactTokens(tokens))
  }

  private static func label(_ value: Int64) -> String {
    value % 1_000_000 == 0 ? "\(value / 1_000_000)M" : AppModel.compactTokens(value)
  }
}

struct UsageWeekChart: View {
  let values: [Int64]
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    let days = Array((Array(repeating: Int64(0), count: 7) + values).suffix(7))
    let peak = max(1, days.max() ?? 1)
    HStack(alignment: .bottom, spacing: 10) {
      ForEach(0..<7, id: \.self) { index in
        let day = Calendar.current.date(byAdding: .day, value: index - 6, to: Date()) ?? Date()
        VStack(spacing: 7) {
          VStack {
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 4)
              .fill(index == 6 ? EvoStyle.accent : EvoStyle.accent.opacity(0.20))
              .frame(height: max(3, 36 * CGFloat(days[index]) / CGFloat(peak)))
              .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: days[index])
          }
          .frame(height: 36)
          Text(day.formatted(.dateTime.weekday(.narrow)))
            .font(.system(size: 9, weight: index == 6 ? .semibold : .regular))
            .foregroundStyle(index == 6 ? Color.primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .help("\(day.formatted(date: .abbreviated, time: .omitted)): \(days[index].formatted())")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
          "\(day.formatted(.dateTime.weekday(.wide))), \(days[index].formatted()) \(L10n.text("tokens"))"
        )
      }
    }
  }
}

struct SpeechBubble: Equatable {
  let id = UUID()
  let text: String
}

/// A line the companion says, sitting over its head in the scene.
struct SpeechBubbleView: View {
  let text: String

  var body: some View {
    Text(text)
      .font(.system(size: 11, weight: .medium))
      .foregroundStyle(.white)
      .lineLimit(2)
      .multilineTextAlignment(.center)
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).strokeBorder(Color.white.opacity(0.18)))
      .frame(maxWidth: 220)
      .accessibilityLabel(text)
  }
}

/// The week that just ended, shown once at the top of Home on the first open of
/// the new one. It is a look back, not a score: nothing here is a target, and
/// the card goes away for good when it is closed.
struct WeeklyRecapCard: View {
  let recap: WeeklyRecap
  let stages: [String]
  let dismiss: () -> Void

  var body: some View {
    EvoCard(tint: EvoStyle.accent) {
      VStack(alignment: .leading, spacing: 9) {
        HStack {
          Label(L10n.text("recap.title", fallback: "Last week"), systemImage: "calendar")
            .font(.system(size: 11, weight: .semibold)).foregroundStyle(EvoStyle.accent)
          Spacer()
          Button(action: dismiss) {
            Image(systemName: "xmark").font(.system(size: 10, weight: .semibold))
          }
          .buttonStyle(.plain)
          .accessibilityLabel(L10n.text("recap.dismiss", fallback: "Close the recap"))
        }
        Text(
          "\(recap.start.formatted(date: .abbreviated, time: .omitted)), \(recap.end.formatted(date: .abbreviated, time: .omitted))"
        )
        .font(.system(size: 10)).foregroundStyle(.secondary)
        HStack(alignment: .firstTextBaseline, spacing: 14) {
          figure(AppModel.compactTokens(recap.tokens), L10n.text("tokens"))
          figure("\(recap.xp)", L10n.text("Growth"))
          figure(
            L10n.format("recap.days", fallback: "%lld days", Int64(recap.daysWorked)),
            L10n.text("recap.worked", fallback: "Worked"))
        }
        if let busiest = recap.busiestDay {
          line(
            "flame",
            L10n.format(
              "recap.busiest", fallback: "Busiest: %@, %@",
              busiest.date.formatted(.dateTime.weekday(.wide)),
              AppModel.compactTokens(busiest.tokens)))
        }
        if !stages.isEmpty {
          line("arrow.up.circle", stages.joined(separator: ", "))
        }
      }
    }
  }

  private func figure(_ value: String, _ label: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(value).font(.system(size: 17, weight: .semibold, design: .rounded)).monospacedDigit()
      Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
    }
  }

  private func line(_ symbol: String, _ text: String) -> some View {
    HStack(spacing: 7) {
      Image(systemName: symbol).font(.system(size: 10)).foregroundStyle(.secondary).frame(width: 13)
      Text(text).font(.system(size: 11)).lineLimit(2)
      Spacer(minLength: 0)
    }
  }
}
