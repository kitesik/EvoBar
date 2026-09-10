import EvoBarCore
import EvoBarEvolution
import SwiftUI

struct CompanionHomeView: View {
  @ObservedObject var model: AppModel
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isShowingGraduation = false
  @State private var ceremonyStartedAt: Date?
  @State private var petResponse = false
  @State private var bursts: [CareBurst] = []
  @State private var anchors: [String: CGRect] = [:]
  @State private var heartsBeat = false

  var body: some View {
    ScrollView {
      VStack(spacing: 12) {
        companionCard
        todayCard
        weekCard
      }
      .padding(.horizontal, EvoStyle.inset)
      .padding(.bottom, 16)
    }
    .scrollIndicators(.hidden)
    .overlay {
      if let ceremony = model.evolutionCeremony {
        TimelineView(.animation(minimumInterval: reduceMotion ? 0.25 : 1 / 30)) { context in
          EvolutionCeremonyView(
            ceremony: ceremony,
            elapsed: context.date.timeIntervalSince(ceremonyStartedAt ?? context.date)
          )
        }
        .transition(.opacity)
      }
    }
    .onChange(of: model.evolutionCeremony) { _, ceremony in
      ceremonyStartedAt = ceremony == nil ? nil : Date()
    }
    .sheet(isPresented: $isShowingGraduation) { GraduationView(model: model) }
  }

  private var companionCard: some View {
    EvoCard(tint: model.isEvolutionReady ? EvoStyle.accent : nil) {
      companionCardContent
        .coordinateSpace(name: "companionCard")
        .onPreferenceChange(CareAnchorKey.self) { anchors = $0 }
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
              width: geometry.size.width, height: 116, spriteSize: 72
            )
          }
          .frame(height: 116)
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
            Image(systemName: "sparkles").foregroundStyle(.orange).font(.system(size: 12))
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
          Spacer(minLength: 6)
          HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
              Image(systemName: index < filledHearts ? "heart.fill" : "heart")
                .font(.system(size: 9))
                .foregroundStyle(
                  index < filledHearts ? Color.pink.opacity(0.8) : Color.secondary.opacity(0.35))
            }
            Text(L10n.text("mood.\(model.affectionMood.rawValue)", fallback: "Companion"))
              .font(.system(size: 10)).foregroundStyle(.secondary).padding(.leading, 3)
              .lineLimit(1).fixedSize()
          }
          .scaleEffect(heartsBeat ? 1.18 : 1, anchor: .trailing)
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(
            L10n.text("mood.\(model.affectionMood.rawValue)", fallback: "Companion"))
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
            Text(
              model.nextStage.map {
                L10n.format(
                  "ui.xpRemaining", fallback: "%lld XP to go",
                  max(0, $0.xpThreshold - model.currentXP))
              } ?? L10n.text("ui.journeyComplete", fallback: "Journey complete")
            )
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary).monospacedDigit()
          }
          EvoProgressBar(value: model.progress)
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
            }
            .buttonStyle(EvoActionStyle())
            .disabled(model.petsRemainingToday == 0)
            .careAnchor("pet")
            Button {
              let xp = model.pendingFoodXP
              model.feedCompanion()
              burst(.feed, from: nil, xp: xp)
            } label: {
              Label(
                model.pendingFoodXP > 0
                  ? L10n.format("ui.feedXP", fallback: "Feed, +%lld XP", model.pendingFoodXP)
                  : L10n.text("care.feed.none", fallback: "Bowl empty"),
                systemImage: "leaf.fill"
              ).frame(maxWidth: .infinity)
            }
            .buttonStyle(EvoActionStyle(prominent: model.pendingFoodXP > 0))
            .disabled(model.pendingFoodXP == 0 || model.isFeeding)
            .careAnchor("feed")
          }
        }
        if let message = model.careMessage {
          Text(message).font(.caption2).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        } else if model.pendingFoodXP == 0, !model.isEvolutionReady, !model.isGraduationReady {
          Text(
            L10n.text(
              "ui.bowlHint", fallback: "Keep working with AI. Your next meal will be waiting.")
          )
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
    Task { @MainActor in
      try? await Task.sleep(for: .seconds(0.8))
      withAnimation(.easeOut(duration: 0.2)) { petResponse = false }
    }
  }

  /// The model has already recorded the care; this only shows it landing. The
  /// token flies from the control (or the click) to the companion's face, the
  /// hearts row beats as it lands, and hearts rise from the face.
  private func burst(_ kind: CareBurst.Kind, from start: CGPoint?, xp: Int64) {
    guard !reduceMotion, let scene = anchors["scene"] else { return }
    let target = CGPoint(x: scene.midX + 17, y: scene.maxY - 62)
    let control = anchors[kind == .pet ? "pet" : "feed"]
    let origin = start ?? control.map { CGPoint(x: $0.midX, y: $0.minY + 6) } ?? CGPoint(x: scene.midX, y: scene.maxY)
    let burst = CareBurst(kind: kind, start: origin, target: target, xp: xp, begun: Date())
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

/// One press of Pet or Feed, drawn over the companion card: a heart or a leaf
/// flies from the control to the companion, a ring marks where it lands, and
/// hearts (and the meal's XP) rise from the face. Purely visual.
struct CareBurst: Identifiable {
  enum Kind { case pet, feed }
  let id = UUID()
  let kind: Kind
  let start: CGPoint
  let target: CGPoint
  let xp: Int64
  let begun: Date

  /// Seconds the token takes to reach the companion.
  static let flight: TimeInterval = 0.42
  /// Seconds until the last heart has faded.
  static let duration: TimeInterval = 1.75
}

struct CareBurstLayer: View {
  let bursts: [CareBurst]

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
    let leaf = Color(red: 0.55, green: 0.85, blue: 0.55)

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
      case .feed: layer.fill(leafShape(at: position, size: 14 * scale), with: .color(leaf))
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

    // Hearts drift up from the face, one after another, swaying and fading.
    for index in 0..<3 {
      let t = since - Double(index) * 0.14
      guard t >= 0, t < 0.95 else { continue }
      let u = t / 0.95
      let sway = sin(u * .pi * 2 + Double(index) * 2.1) * 6
      let x = burst.target.x + [-9, 7, -1][index] + sway
      let y = burst.target.y - 12 - 52 * u * (1 + 0.12 * Double(index))
      var layer = canvas
      layer.opacity = min(1, u * 6) * pow(1 - u, 0.8)
      layer.fill(heart(at: CGPoint(x: x, y: y), size: index == 1 ? 12 : 9), with: .color(pink))
    }

    // A meal also shows what it was worth.
    if burst.kind == .feed, burst.xp > 0, since < 1.1 {
      let u = since / 1.1
      var layer = canvas
      layer.opacity = min(1, u * 5) * pow(1 - u, 0.7)
      let label = layer.resolve(
        Text(verbatim: "+\(burst.xp) XP")
          .font(.system(size: 11, weight: .bold, design: .rounded))
          .foregroundStyle(EvoStyle.accent))
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

  private func leafShape(at center: CGPoint, size: CGFloat) -> Path {
    var path = Path()
    let tip = CGPoint(x: center.x + size * 0.55, y: center.y - size * 0.55)
    let stem = CGPoint(x: center.x - size * 0.55, y: center.y + size * 0.55)
    path.move(to: stem)
    path.addQuadCurve(to: tip, control: CGPoint(x: center.x - size * 0.45, y: center.y - size * 0.6))
    path.addQuadCurve(to: stem, control: CGPoint(x: center.x + size * 0.45, y: center.y + size * 0.6))
    path.closeSubpath()
    return path
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
