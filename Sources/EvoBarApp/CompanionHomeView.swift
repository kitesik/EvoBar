import EvoBarCore
import EvoBarEvolution
import SwiftUI

struct CompanionHomeView: View {
  @ObservedObject var model: AppModel
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isShowingGraduation = false
  @State private var ceremonyStartedAt: Date?
  @State private var petResponse = false

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
      VStack(alignment: .leading, spacing: 12) {
        HStack(alignment: .center, spacing: 14) {
          Button(action: pet) {
            ZStack(alignment: .topTrailing) {
              RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: model.currentAnimal?.themeColorHex ?? "#DFA95D").opacity(0.09))
              if let animal = model.currentAnimal {
                AnimalSpriteView(
                  animal: animal,
                  stageIndex: model.acknowledgedStageIndex,
                  isShiny: model.currentAnimalInstance?.isShiny ?? false,
                  visualState: model.companionVisualState,
                  size: 76
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(petResponse && !reduceMotion ? 1.06 : 1)
              }
              if petResponse {
                Image(systemName: "heart.fill")
                  .foregroundStyle(.pink)
                  .font(.system(size: 14))
                  .padding(5)
                  .transition(.opacity)
              }
            }
            .frame(width: 88, height: 88)
          }
          .buttonStyle(.plain)
          .disabled(model.petsRemainingToday == 0)
          .help(L10n.text("care.pet.hint", fallback: "Click your companion to pet it"))
          .accessibilityLabel(L10n.text("care.pet.action", fallback: "Pet"))

          VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
              Text(model.companionName)
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .lineLimit(1).truncationMode(.tail)
                .help(model.companionName)
              if model.currentAnimalInstance?.isShiny == true {
                Image(systemName: "sparkles").foregroundStyle(.orange)
              }
            }
            Text(model.currentStage.map(L10n.stage) ?? L10n.text("Growing companion"))
              .font(.system(size: 12)).foregroundStyle(.secondary)
              .lineLimit(1)
            HStack(spacing: 6) {
              EvoBadge(title: stateTitle, icon: stateIcon)
              Text(
                L10n.format(
                  "ui.stage", fallback: "Stage %lld / 5", Int64(model.acknowledgedStageIndex))
              )
              .font(.system(size: 10)).foregroundStyle(.secondary)
            }
            HStack(spacing: 3) {
              ForEach(0..<5, id: \.self) { index in
                Image(systemName: index < filledHearts ? "heart.fill" : "heart")
                  .font(.system(size: 9))
                  .foregroundStyle(
                    index < filledHearts ? Color.pink.opacity(0.8) : Color.secondary.opacity(0.35))
              }
              Text(L10n.text("mood.\(model.affectionMood.rawValue)", fallback: "Companion"))
                .font(.system(size: 10)).foregroundStyle(.secondary)
                .padding(.leading, 3)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
              L10n.text("mood.\(model.affectionMood.rawValue)", fallback: "Companion"))
          }
          Spacer(minLength: 0)
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
            Button(action: pet) {
              Label(L10n.text("care.pet.action", fallback: "Pet"), systemImage: "hand.draw")
            }
            .buttonStyle(EvoActionStyle())
            .disabled(model.petsRemainingToday == 0)
            Button {
              model.feedCompanion()
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
            .font(.system(size: 34, weight: .semibold, design: .rounded))
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
  private func pet() {
    guard model.petsRemainingToday > 0 else { return }
    withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.65)) {
      petResponse = true
    }
    model.petCompanion()
    Task { @MainActor in
      try? await Task.sleep(for: .seconds(0.8))
      withAnimation(.easeOut(duration: 0.2)) { petResponse = false }
    }
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
              .frame(height: max(3, 42 * CGFloat(days[index]) / CGFloat(peak)))
              .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: days[index])
          }
          .frame(height: 42)
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
