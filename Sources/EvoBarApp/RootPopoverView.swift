import EvoBarCore
import EvoBarUsage
import SwiftUI

struct RootPopoverView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Group {
            switch model.loadState {
            case .loading:
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Preparing EvoBar…").foregroundStyle(.secondary)
                }
            case .failed(let message):
                ContentUnavailableView(
                    "EvoBar could not start",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            case .ready where !model.onboardingCompleted:
                OnboardingView(model: model)
            case .ready:
                DashboardView(model: model)
            }
        }
        .frame(width: 380, height: 540)
    }
}

private struct DashboardView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $model.selectedSection) {
                ForEach(AppSection.allCases) { section in
                    Text(section.displayName).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            if let updateURL = model.availableUpdateURL,
               let version = model.availableUpdateVersion {
                HStack(spacing: 9) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.blue)
                    Text("EvoBar \(version) is available")
                        .font(.caption.bold())
                    Spacer()
                    Link("View release", destination: updateURL)
                        .font(.caption)
                }
                .padding(9)
                .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .padding(.top, 10)
            }

            if !model.providerStatusAlerts.isEmpty {
                VStack(spacing: 6) {
                    ForEach(model.providerStatusAlerts) { status in
                        ProviderStatusBanner(status: status)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }

            Group {
                switch model.selectedSection {
                case .home: HomeView(model: model)
                case .usage: UsageDashboardView(model: model)
                case .collection: CollectionView(model: model)
                case .shop: ShopView(model: model)
                case .settings: SettingsView(model: model)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 380, height: 540)
    }
}

private struct ProviderStatusBanner: View {
    let status: ProviderOperationalStatus

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: status.condition == .outage ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(providerName) service notice")
                    .font(.caption.bold())
                Text(status.summary + staleSuffix)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 4)
            Link(destination: status.statusPageURL) {
                Image(systemName: "arrow.up.right.square")
            }
            .buttonStyle(.borderless)
            .help("Open official status page")
        }
        .padding(9)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
    }

    private var tint: Color {
        status.condition == .outage ? .red : .orange
    }

    private var providerName: String {
        switch status.providerID {
        case .claudeCode: "Claude"
        case .codex: "OpenAI"
        default: status.providerID.rawValue
        }
    }

    private var staleSuffix: String {
        status.freshness == .stale ? " · last known status" : ""
    }
}

private struct UsageDashboardView: View {
    @ObservedObject var model: AppModel
    @State private var selectedWindow = UsageWindowKind.today
    @State private var selectedProvider: ProviderID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Usage window", selection: $selectedWindow) {
                    ForEach(UsageWindowKind.allCases) { kind in
                        Text(L10n.text(kind.fallbackTitle)).tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                quotaSection

                if let window {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(format(window.usage.totalTokens))
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            Text("tokens · \(window.sessionCount) sessions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            if let cost = window.estimatedAPICostUSD {
                                Text(costText(cost)).font(.headline.monospacedDigit())
                                Text(costCoverageText(window.costCoverage))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Text(model.trackingStatus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if model.showTokenBreakdown {
                        HStack(spacing: 8) {
                            usageMetric("Input", window.usage.inputTokens)
                            usageMetric("Output", window.usage.outputTokens)
                            usageMetric(
                                "Cache",
                                window.usage.cacheReadTokens + window.usage.cacheWriteTokens
                            )
                        }
                    }

                    if !window.providers.isEmpty {
                        Picker("Provider", selection: $selectedProvider) {
                            Text("All").tag(nil as ProviderID?)
                            ForEach(window.providers) { provider in
                                Text(providerName(provider.providerID))
                                    .tag(provider.providerID as ProviderID?)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text("Providers").font(.headline)
                        ForEach(filteredProviders) { provider in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(providerName(provider.providerID)).font(.subheadline.bold())
                                    Text("\(provider.sessionCount) sessions")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(format(provider.usage.totalTokens))
                                    .monospacedDigit()
                                Text(providerShare(provider.usage.totalTokens, total: window.usage.totalTokens))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 42, alignment: .trailing)
                            }
                            .padding(10)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                        }

                        if model.showTokenBreakdown {
                            Text("Models").font(.headline).padding(.top, 2)
                            ForEach(filteredModels) { modelUsage in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(modelUsage.modelID).font(.subheadline).lineLimit(1)
                                        Text(providerName(modelUsage.providerID))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 1) {
                                        Text(format(modelUsage.usage.totalTokens))
                                            .font(.subheadline.monospacedDigit())
                                        if let cost = modelUsage.estimatedAPICostUSD {
                                            Text(costText(cost))
                                                .font(.caption2.monospacedDigit())
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        ContentUnavailableView(
                            "No usage in this window",
                            systemImage: "chart.bar.xaxis",
                            description: Text("New Claude Code or Codex token events will appear here.")
                        )
                        .frame(minHeight: 220)
                    }

                    Text("Updated \(window.interval.end.formatted(date: .omitted, time: .shortened)) · API-equivalent estimate · pricing \(model.pricing?.effectiveAt ?? "unavailable")")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 300)
                }
            }
            .padding()
        }
        .onChange(of: selectedWindow) { _, _ in selectedProvider = nil }
    }

    @ViewBuilder private var quotaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Official quota").font(.headline)
                if model.quotaIsDemo {
                    Text("DEMO")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                }
                Spacer()
                Button {
                    model.refreshNow()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(model.isRefreshing)
                .help("Refresh usage and quota")
            }

            if let providers = model.quotaDashboard?.providers {
                ForEach(providers) { provider in
                    if provider.windows.isEmpty {
                        HStack {
                            Image(systemName: "questionmark.circle")
                            VStack(alignment: .leading, spacing: 2) {
                                Text(providerName(provider.providerID)).font(.subheadline.bold())
                                Text(provider.message ?? "Quota unavailable")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(9)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                    } else {
                        ForEach(provider.windows, id: \.name) { quota in
                            quotaCard(quota)
                        }
                    }
                }
            } else {
                ProgressView().controlSize(.small)
            }

            if model.quotaIsDemo {
                Text("Demo meters validate UI, reset countdowns, forecasts, and alerts. EvoBar does not reuse Claude/Codex session credentials or call undocumented APIs.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func quotaCard(_ quota: QuotaWindow) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("\(providerName(quota.providerID)) · \(quota.name)")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(Int((quota.utilization * 100).rounded()))%")
                    .font(.subheadline.monospacedDigit().bold())
            }
            ProgressView(value: quota.utilization)
                .tint(quota.utilization >= 0.95 ? .red : quota.utilization >= 0.8 ? .orange : .accentColor)
            HStack {
                Text(quota.resetsAt.map { "Resets \($0.formatted(.relative(presentation: .named)))" } ?? "Reset time unavailable")
                Spacer()
                if let projected = quota.projectedExhaustionAt {
                    Text("Limit \(projected.formatted(date: .omitted, time: .shortened))")
                } else if quota.freshness == .stale {
                    Text("Stale")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(9)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    private var window: UsageWindowSnapshot? {
        model.usageDashboard?.window(selectedWindow)
    }

    private var filteredProviders: [ProviderUsageBreakdown] {
        guard let window else { return [] }
        guard let selectedProvider else { return window.providers }
        return window.providers.filter { $0.providerID == selectedProvider }
    }

    private var filteredModels: [ModelUsageBreakdown] {
        guard let window else { return [] }
        guard let selectedProvider else { return window.models }
        return window.models.filter { $0.providerID == selectedProvider }
    }

    private func usageMetric(_ title: String, _ value: Int64) -> some View {
        VStack(spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(format(value)).font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity)
        .padding(9)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    private func format(_ value: Int64) -> String {
        value.formatted(.number.notation(.compactName))
    }

    private func providerName(_ providerID: ProviderID) -> String {
        switch providerID {
        case .claudeCode: "Claude"
        case .codex: "Codex"
        default: providerID.rawValue
        }
    }

    private func providerShare(_ value: Int64, total: Int64) -> String {
        guard total > 0 else { return "0%" }
        return "\(Int((Double(value) / Double(total) * 100).rounded()))%"
    }

    private func costText(_ cost: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = cost < 0.01 ? 4 : 2
        formatter.maximumFractionDigits = cost < 0.01 ? 4 : 2
        return formatter.string(from: NSDecimalNumber(decimal: cost)) ?? "$—"
    }

    private func costCoverageText(_ coverage: Double) -> String {
        coverage >= 0.999 ? "estimated cost" : "\(Int((coverage * 100).rounded()))% priced"
    }
}

private struct OnboardingView: View {
    @ObservedObject var model: AppModel
    @State private var page = 0
    @State private var selectedStarterID: AnimalDefinitionID = "cat"
    @State private var companionName = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index <= page ? Color.accentColor : Color.secondary.opacity(0.2))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)

            Group {
                switch page {
                case 0: welcome
                case 1: providerDiscovery
                default: starterSelection
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
        }
    }

    private var welcome: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("🐾").font(.system(size: 76)).accessibilityHidden(true)
            Text("Meet EvoBar").font(.largeTitle.bold())
            Text("Your time working with AI becomes the story and growth of an animal companion.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 10) {
                Label("Lives quietly in your menu bar", systemImage: "menubar.rectangle")
                Label("Grows from Claude Code and Codex usage", systemImage: "sparkles")
                Label("Local only — no account or analytics", systemImage: "lock.shield")
            }
            .font(.callout)
            Spacer()
            Button("Continue") { withAnimation { page = 1 } }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }

    private var providerDiscovery: some View {
        VStack(spacing: 18) {
            Text("Connect your work").font(.title.bold())
            Text("EvoBar checks for local usage logs. It never reads or stores prompts, responses, or code.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(model.providerDetections) { provider in
                    HStack(spacing: 12) {
                        Image(systemName: providerIcon(provider.state))
                            .foregroundStyle(providerColor(provider.state))
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(provider.displayName).font(.headline)
                            Text(providerDescription(provider.state))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if provider.state == .checking { ProgressView().controlSize(.small) }
                    }
                    .padding(12)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                }
            }

            if model.providerDetections.allSatisfy({ $0.state == .notFound }) {
                Text("You can continue and install a provider later. EvoBar will show an empty state until logs appear.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            HStack {
                Button("Check again") { model.detectProviders() }
                    .disabled(model.isDetectingProviders)
                Spacer()
                Button("Continue") { withAnimation { page = 2 } }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private var starterSelection: some View {
        VStack(spacing: 16) {
            Text("Choose your companion").font(.title.bold())
            Text("Your first animal line is free. The other remains available in the Shop.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(starterAnimals) { animal in
                    Button {
                        selectedStarterID = animal.id
                    } label: {
                        VStack(spacing: 8) {
                            AnimalSpriteView(animal: animal, size: 56)
                            Text(animal.stages.first.map(L10n.stage) ?? L10n.animal(animal))
                                .font(.headline)
                            Image(systemName: selectedStarterID == animal.id ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedStarterID == animal.id ? Color.accentColor : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            selectedStarterID == animal.id ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedStarterID == animal.id ? Color.accentColor : .clear, lineWidth: 2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField("Companion name", text: nameBinding)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
            Text("\(companionName.count)/24 characters")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if let error = model.onboardingError {
                Text(error).font(.caption).foregroundStyle(.red)
            }
            Spacer()
            Button {
                model.completeOnboarding(starterID: selectedStarterID, name: companionName)
            } label: {
                if model.isCompletingOnboarding {
                    ProgressView().controlSize(.small)
                } else {
                    Text("Start growing together")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(trimmedName.isEmpty || model.isCompletingOnboarding)
        }
    }

    private var starterAnimals: [AnimalDefinition] {
        model.catalog?.animals.filter(\.isStarter).sorted { $0.sortOrder < $1.sortOrder } ?? []
    }

    private var trimmedName: String {
        companionName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { companionName },
            set: { companionName = String($0.prefix(24)) }
        )
    }

    private func providerIcon(_ state: ProviderDetectionState) -> String {
        switch state {
        case .checking: "magnifyingglass"
        case .found: "checkmark.circle.fill"
        case .notFound: "minus.circle"
        case .permissionRequired: "lock.trianglebadge.exclamationmark"
        case .failed: "exclamationmark.triangle.fill"
        }
    }

    private func providerColor(_ state: ProviderDetectionState) -> Color {
        switch state {
        case .found: .green
        case .permissionRequired, .failed: .orange
        default: .secondary
        }
    }

    private func providerDescription(_ state: ProviderDetectionState) -> String {
        switch state {
        case .checking: L10n.text("provider.checking", fallback: "Looking for local logs…")
        case .found(let count):
            L10n.format("provider.found", fallback: "Found %lld log files", Int64(count))
        case .notFound: L10n.text("provider.notFound", fallback: "Not found — you can connect later")
        case .permissionRequired: L10n.text("provider.permission", fallback: "Folder permission is required")
        case .failed: L10n.text("provider.failed", fallback: "Detection failed — try again")
        }
    }
}

private struct HomeView: View {
    @ObservedObject var model: AppModel
    @State private var isShowingGraduation = false

    var body: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 4)
            if let asset = model.menuBarAsset {
                CompanionSceneView(
                    reference: asset,
                    visualState: model.companionVisualState,
                    locomotion: model.currentAnimal?.locomotion ?? .walk,
                    themeColor: color(from: model.currentAnimal?.themeColorHex),
                    quality: model.animationQuality
                )
                    .scaleEffect(model.isEvolving ? 1.05 : 1)
                    .animation(.spring(response: 0.35, dampingFraction: 0.5), value: model.isEvolving)
                    .accessibilityHidden(true)
            }
            Text(model.companionName)
                .font(.title2.bold())
                .padding(.top, 4)
            Text(model.currentStage.map(L10n.stage) ?? "Loading companion…")
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Text(model.trackingStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    model.refreshNow()
                } label: {
                    if model.isRefreshing {
                        ProgressView().controlSize(.mini)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .disabled(model.isRefreshing)
                .accessibilityLabel(L10n.text("action.refreshNow", fallback: "Refresh now"))
            }
            if let rank = DayRank.rank(today: model.todayTokens, history: model.dailyRawTokens) {
                Text(L10n.format(
                    "home.dayRank",
                    fallback: "Today ranks #%lld of your last %lld days",
                    Int64(rank.rank),
                    Int64(rank.total)
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(model.nextStage.map { "To \(L10n.stage($0))" } ?? L10n.text("Final evolution"))
                    Spacer()
                    Text("\(Int(model.progress * 100))%")
                        .monospacedDigit()
                }
                EvolutionProgressBar(
                    progress: model.progress,
                    tint: color(from: model.currentAnimal?.themeColorHex),
                    isReady: model.isEvolutionReady
                )
            }
            .padding(.horizontal, 24)

            if model.isEvolutionReady, let nextStage = model.nextStage {
                Button {
                    model.evolve()
                } label: {
                    Label("Evolve to \(L10n.stage(nextStage))", systemImage: "sparkles")
                        .symbolEffect(.pulse, options: .repeating)
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isEvolving)
            } else if model.isGraduationReady {
                Button {
                    isShowingGraduation = true
                } label: {
                    Label("Graduate and choose what’s next", systemImage: "graduationcap.fill")
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 12) {
                metric(title: "Today", value: format(model.todayTokens), suffix: "tokens", icon: heatIcon, tint: heatTint, heat: heat)
                metric(title: "Growth", value: "+\(model.todayXP)", suffix: "XP", icon: "arrow.up.heart.fill", tint: .pink)
                metric(title: "Wallet", value: "\(model.tokenCoins)", suffix: "coins", icon: "star.circle.fill", tint: .yellow)
            }
            .padding(.horizontal)
            Spacer(minLength: 4)
        }
        .sheet(isPresented: $isShowingGraduation) {
            GraduationView(model: model)
        }
    }

    private var heat: UsageBand {
        UsageBand.band(for: model.todayTokens, thresholds: model.usageBandThresholds)
    }

    private var heatIcon: String {
        switch heat {
        case .light: "bolt"
        case .steady: "bolt.fill"
        case .heavy, .extreme: "flame.fill"
        }
    }

    private var heatTint: Color {
        switch heat {
        case .light: .gray
        case .steady, .heavy: .orange
        case .extreme: .red
        }
    }

    private func metric(
        title: String,
        value: String,
        suffix: String,
        icon: String,
        tint: Color,
        heat: UsageBand = .light
    ) -> some View {
        let hot = heat == .heavy || heat == .extreme
        return VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(tint)
                    .symbolEffect(.pulse, options: .repeating, isActive: heat == .extreme)
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            Text(value).font(.headline).monospacedDigit()
                .foregroundStyle(heat == .extreme ? AnyShapeStyle(tint) : AnyShapeStyle(.primary))
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.4), value: value)
            Text(suffix).font(.caption2).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            if hot {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(
                        colors: [tint.opacity(heat == .extreme ? 0.3 : 0.14), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    ))
                    .allowsHitTesting(false)
            }
        }
        .overlay {
            if heat == .extreme {
                RoundedRectangle(cornerRadius: 10).strokeBorder(tint.opacity(0.5))
            }
        }
    }

    private func format(_ value: Int64) -> String {
        value.formatted(.number.notation(.compactName))
    }

    private func color(from hex: String?) -> Color {
        guard let hex else { return .accentColor }
        return Color(hex: hex)
    }
}

/// Progress toward the next stage; sweeps a highlight across the bar once evolution is ready.
private struct EvolutionProgressBar: View {
    let progress: Double
    let tint: Color
    let isReady: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule().fill(tint).frame(width: max(8, width * min(1, max(0, progress))))
                if isReady, !reduceMotion {
                    TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                        let phase = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.8) / 1.8
                        Capsule()
                            .fill(LinearGradient(
                                colors: [.clear, .white.opacity(0.8), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: 70)
                            .offset(x: -70 + (width + 70) * phase)
                    }
                    .blendMode(.plusLighter)
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: 8)
        .shadow(color: isReady ? tint.opacity(0.45) : .clear, radius: isReady ? 6 : 0)
        .animation(.easeInOut(duration: 0.4), value: isReady)
    }
}

private struct GraduationView: View {
    private enum NextMode: String, CaseIterable, Identifiable {
        case choose = "Choose"
        case hatch = "Random Hatch"
        var id: String { rawValue }
        var displayName: String { L10n.text(rawValue) }
    }

    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var mode = NextMode.choose
    @State private var selectedAnimalID: AnimalDefinitionID?
    @State private var companionName = ""
    @State private var initialInstanceID: UUID?

    var body: some View {
        VStack(spacing: 16) {
            Text("A new chapter").font(.title.bold())
            Text("\(model.companionName) will remain in Collection with every earned record.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Picker("Next companion", selection: $mode) {
                ForEach(NextMode.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)

            if mode == .choose {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
                    ForEach(ownedAnimals) { animal in
                        Button {
                            selectedAnimalID = animal.id
                        } label: {
                            VStack(spacing: 6) {
                                AnimalSpriteView(animal: animal, size: 42)
                                Text(L10n.animal(animal)).font(.caption.bold())
                                Image(systemName: selectedAnimalID == animal.id ? "checkmark.circle.fill" : "circle")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(
                                selectedAnimalID == animal.id ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                VStack(spacing: 10) {
                    Text("🥚").font(.system(size: 58))
                    Text("Uses one Random Egg. The species and nature are drawn from animal lines you own. A shiny individual may appear.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                Text("Eggs available: \(model.randomEggCount)")
                    .font(.caption.bold())
                    .foregroundStyle(model.randomEggCount > 0 ? Color.secondary : Color.red)
            }

            TextField("New companion name", text: nameBinding)
                .textFieldStyle(.roundedBorder)

            if let error = model.graduationError {
                Text(error).font(.caption).foregroundStyle(.red)
            }

            Spacer()
            HStack {
                Button("Not yet") { dismiss() }
                Spacer()
                Button(mode == .choose ? "Graduate and start" : "Graduate and hatch") {
                    if mode == .choose, let selectedAnimalID {
                        model.graduateAndStart(definitionID: selectedAnimalID, name: companionName)
                    } else {
                        model.graduateAndHatch(name: companionName)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    trimmedName.isEmpty || model.isGraduating ||
                    (mode == .choose && selectedAnimalID == nil) ||
                    (mode == .hatch && model.randomEggCount == 0)
                )
            }
        }
        .padding(24)
        .frame(width: 430, height: 500)
        .onAppear {
            initialInstanceID = model.currentAnimalInstance?.id
            selectedAnimalID = ownedAnimals.first?.id
        }
        .onChange(of: model.currentAnimalInstance?.id) { _, newValue in
            if let initialInstanceID, newValue != initialInstanceID { dismiss() }
        }
    }

    private var ownedAnimals: [AnimalDefinition] {
        model.catalog?.animals
            .filter { model.ownedAnimalIDs.contains($0.id) }
            .sorted { $0.sortOrder < $1.sortOrder } ?? []
    }

    private var trimmedName: String {
        companionName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var nameBinding: Binding<String> {
        Binding(get: { companionName }, set: { companionName = String($0.prefix(24)) })
    }
}

private struct CollectionView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your companions").font(.title3.bold())
                ForEach(model.animalInstances) { instance in
                    if let animal = model.catalog?.animals.first(where: { $0.id == instance.definitionID }) {
                        companionCard(instance: instance, animal: animal)
                    }
                }

                if !availableAnimals.isEmpty {
                    Text("Available lines").font(.title3.bold()).padding(.top, 4)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                        ForEach(availableAnimals) { animal in
                            VStack(spacing: 7) {
                                AnimalSpriteView(animal: animal, size: 38)
                                Text(L10n.animal(animal)).font(.headline)
                                Text("Owned · Ready")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                Text("Undiscovered lines").font(.title3.bold()).padding(.top, 4)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                    ForEach(lockedAnimals) { animal in
                        VStack(spacing: 7) {
                            Text("❓").font(.system(size: 32)).grayscale(1)
                            Text(L10n.animal(animal)).font(.headline)
                            Text("Locked · 1/5 preview")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
    }

    private var lockedAnimals: [AnimalDefinition] {
        return model.catalog?.animals
            .filter { !model.ownedAnimalIDs.contains($0.id) }
            .sorted { $0.sortOrder < $1.sortOrder } ?? []
    }

    private var availableAnimals: [AnimalDefinition] {
        let raisedIDs = Set(model.animalInstances.map(\.definitionID))
        return model.catalog?.animals
            .filter { model.ownedAnimalIDs.contains($0.id) && !raisedIDs.contains($0.id) }
            .sorted { $0.sortOrder < $1.sortOrder } ?? []
    }

    private func companionCard(instance: AnimalInstance, animal: AnimalDefinition) -> some View {
        let stage = animal.stages.first { $0.index == instance.acknowledgedStageIndex }
        let togetherDays = max(1, Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: instance.createdAt),
            to: Calendar.current.startOfDay(for: Date())
        ).day.map { $0 + 1 } ?? 1)
        let claude = instance.providerTokens[.claudeCode] ?? 0
        let codex = instance.providerTokens[.codex] ?? 0
        let providerTotal = claude + codex
        let providerMix = if providerTotal > 0 {
            "Claude \(Int((Double(claude) / Double(providerTotal) * 100).rounded()))% · Codex \(Int((Double(codex) / Double(providerTotal) * 100).rounded()))%"
        } else {
            "No provider usage yet"
        }

        return HStack(spacing: 14) {
            AnimalSpriteView(
                animal: animal,
                stageIndex: instance.acknowledgedStageIndex,
                isShiny: instance.isShiny,
                size: 52
            )
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(instance.name).font(.headline)
                    if instance.isCurrent {
                        Text("CURRENT")
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                    } else if instance.graduatedAt != nil {
                        Text("GRADUATED")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                Text(stage.map(L10n.stage) ?? L10n.animal(animal))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Together \(togetherDays)d · \(instance.cumulativeTokens.formatted(.number.notation(.compactName))) tokens")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(providerMix)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if let graduatedAt = instance.graduatedAt {
                    Text("Graduated \(graduatedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Text("Lv. \(instance.acknowledgedStageIndex)")
                .font(.caption.monospacedDigit())
        }
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct ShopView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if model.isStorefrontTestMode {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Storefront test mode", systemImage: "hammer.fill")
                            .font(.headline)
                        Picker("Outcome", selection: testScenarioBinding) {
                            ForEach(StorefrontTestScenario.allCases) { scenario in
                                Text(scenario.displayName).tag(scenario)
                            }
                        }
                        .pickerStyle(.segmented)
                        Text("No real charge is made. Entitlements are stored locally for development testing.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                } else if !model.purchasesAvailable {
                    Label("Purchases are unavailable in this build", systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Secure external checkout", systemImage: "checkmark.shield.fill")
                            .font(.headline)
                        Text("Purchases open in your browser. Only a valid signed EvoBar license can unlock animals.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("Animals").font(.title3.bold())
                ForEach(model.storefront?.products.sorted(by: { $0.sortOrder < $1.sortOrder }) ?? []) { product in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                        VStack(alignment: .leading) {
                            Text(L10n.product(product)).font(.headline)
                            Text(productDescription(product))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                            if productIsOwned(product) {
                                Text("Owned")
                                    .font(.caption.bold())
                                    .foregroundStyle(.green)
                            } else if model.purchasingProductID == product.id {
                                ProgressView().controlSize(.small)
                            } else {
                                Button("$\(product.fallbackPriceUSD)") {
                                    model.purchase(product.id)
                                }
                                .disabled(!model.purchasesAvailable || model.purchasingProductID != nil)
                            }
                        }
                        if product.kind == .animal,
                           let animalID = product.grantsAnimalIDs.first,
                           let animal = model.catalog?.animals.first(where: { $0.id == animalID }) {
                            Text(journeyPreview(animal))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                    .padding(10)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                }

                if let message = model.purchaseMessage {
                    Text(message).font(.caption).foregroundStyle(.secondary)
                }
                Button("Restore purchases") { model.restorePurchases() }
                    .disabled(!model.purchasesAvailable || model.purchasingProductID != nil)
                if model.licenseImportAvailable {
                    Button("Import license…") { model.importLicense() }
                        .disabled(model.purchasingProductID != nil)
                }

                Text("Items · \(model.tokenCoins) coins").font(.title3.bold()).padding(.top, 8)
                ForEach(model.economy?.items ?? []) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.item(item))
                            Text(itemDescription(item))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if item.kind == .shinyCharm, model.hasShinyCharm {
                            Text("Owned").font(.caption.bold()).foregroundStyle(.green)
                        } else if model.purchasingItemID == item.id {
                            ProgressView().controlSize(.small)
                        } else {
                            Button("\(item.tokenCoinPrice) 🪙") {
                                model.purchaseGameItem(item)
                            }
                            .disabled(model.tokenCoins < item.tokenCoinPrice || model.purchasingItemID != nil)
                        }
                    }
                    .padding(.vertical, 3)
                }
                if let message = model.itemPurchaseMessage {
                    Text(message).font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }

    private var testScenarioBinding: Binding<StorefrontTestScenario> {
        Binding(
            get: { model.storefrontTestScenario },
            set: { model.updateStorefrontTestScenario($0) }
        )
    }

    private func productIsOwned(_ product: StorefrontProductDefinition) -> Bool {
        product.grantsAnimalIDs.allSatisfy { model.ownedAnimalIDs.contains($0) }
    }

    private func productDescription(_ product: StorefrontProductDefinition) -> String {
        switch product.kind {
        case .animal: "Original five-stage evolution line"
        case .bundle: "Bundle · \(product.grantsAnimalIDs.count) animal lines"
        case .allAnimals: "Unlock every animal line"
        }
    }

    private func journeyPreview(_ animal: AnimalDefinition) -> String {
        let visible = animal.stages.dropLast().map(\.fallbackName)
        return (visible + ["Final silhouette"]).joined(separator: " → ")
    }

    private func itemDescription(_ item: GameItemDefinition) -> String {
        switch item.kind {
        case .rareCandy: "+\(item.xpGrant ?? 0) XP for the growing companion"
        case .mint: "Reroll the growing companion's nature"
        case .shinyCharm: "Permanent higher shiny chance for future hatches"
        case .randomEgg: "One random owned-line hatch after graduation (\(model.randomEggCount) held)"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var isShowingResetConfirmation = false
    @State private var isShowingPrivacyDetails = false
    @State private var claudeLogPattern = ""
    @State private var codexLogPattern = ""

    var body: some View {
        Form {
            Toggle("Show token, cost, and quota in menu bar", isOn: Binding(
                get: { model.showTokenInMenuBar },
                set: { model.setShowTokenInMenuBar($0) }
            ))
            Toggle("Show token and model breakdown", isOn: Binding(
                get: { model.showTokenBreakdown },
                set: { model.setShowTokenBreakdown($0) }
            ))
            Picker("Animation quality", selection: Binding(
                get: { model.animationQuality },
                set: { model.setAnimationQuality($0) }
            )) {
                ForEach(AnimationQuality.allCases) { quality in
                    Text(quality.displayName).tag(quality)
                }
            }
            Section("Tracking") {
                Toggle("Claude Code", isOn: Binding(
                    get: { model.claudeTrackingEnabled },
                    set: { model.setTrackingEnabled($0, providerID: .claudeCode) }
                ))
                Toggle("Codex", isOn: Binding(
                    get: { model.codexTrackingEnabled },
                    set: { model.setTrackingEnabled($0, providerID: .codex) }
                ))
                Picker("Refresh", selection: Binding(
                    get: { model.refreshIntervalMinutes },
                    set: { model.setRefreshIntervalMinutes($0) }
                )) {
                    Text("Manual").tag(0)
                    ForEach(1...15, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                Button(model.isRefreshing ? "Refreshing…" : "Refresh now") {
                    model.refreshNow()
                }
                .disabled(model.isRefreshing)
            }
            Section("Usage bands") {
                bandStepper("Steady from", index: 0, step: 0.5)
                bandStepper("Heavy from", index: 1, step: 1)
                bandStepper("Extreme from", index: 2, step: 5)
                Text("Values are millions of tokens per day. Higher bands heat up the Today tile.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Notifications") {
                Toggle("Companion evolution events", isOn: Binding(
                    get: { model.companionNotificationsEnabled },
                    set: { model.setCompanionNotificationsEnabled($0) }
                ))
                Toggle("Warning and critical notifications", isOn: Binding(
                    get: { model.quotaNotificationsEnabled },
                    set: { model.setQuotaNotificationsEnabled($0) }
                ))
                Text("Permission is requested only when enabled. Evolution readiness is announced once when a new threshold is crossed; quota warnings are sent at 80% and 95% once per reset window.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Provider status") {
                Toggle("Check official Claude and OpenAI status", isOn: Binding(
                    get: { model.providerStatusChecksEnabled },
                    set: { model.setProviderStatusChecksEnabled($0) }
                ))
                Text("When enabled, EvoBar checks the providers' public status JSON at most once every five minutes. No local usage data is attached.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Additional log locations") {
                logPatternEditor(
                    title: "Claude Code",
                    placeholder: "~/archive/*/.claude/projects",
                    value: $claudeLogPattern,
                    patterns: model.claudeAdditionalLogPatterns,
                    providerID: .claudeCode
                )
                logPatternEditor(
                    title: "Codex",
                    placeholder: "/Volumes/Work/**/.codex/sessions",
                    value: $codexLogPattern,
                    patterns: model.codexAdditionalLogPatterns,
                    providerID: .codex
                )
                Text("Supports * and **. EvoBar scans matching folders for JSONL files; wildcard traversal from / is blocked.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("System") {
                Toggle("Launch EvoBar at login", isOn: Binding(
                    get: { model.launchAtLoginEnabled },
                    set: { model.setLaunchAtLoginEnabled($0) }
                ))
            }
            Section("Updates") {
                Toggle("Automatically check GitHub Releases", isOn: Binding(
                    get: { model.automaticUpdateChecksEnabled },
                    set: { model.setAutomaticUpdateChecksEnabled($0) }
                ))
                HStack {
                    Text("Installed \(model.installedVersion)")
                    Spacer()
                    Button(model.isCheckingForUpdates ? "Checking…" : "Check now") {
                        model.checkForUpdates()
                    }
                    .disabled(model.isCheckingForUpdates)
                }
                Text(model.updateStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let updateURL = model.availableUpdateURL {
                    Link("Open latest release", destination: updateURL)
                }
                Text("Uses the public GitHub Releases API. EvoBar opens the release page and never installs an update silently.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Desktop companion") {
                Toggle("Show floating desktop pet", isOn: Binding(
                    get: { model.desktopPetEnabled },
                    set: { model.setDesktopPetEnabled($0) }
                ))
                Picker("Pinned animal", selection: Binding(
                    get: { model.pinnedAnimalDefinitionID },
                    set: { model.setPinnedAnimalDefinitionID($0) }
                )) {
                    Text("Growing companion").tag(nil as AnimalDefinitionID?)
                    ForEach(ownedAnimals) { animal in
                        Text("\(animal.menuBarEmoji) \(L10n.animal(animal))")
                            .tag(animal.id as AnimalDefinitionID?)
                    }
                }
                HStack {
                    Text("Size")
                    Slider(value: Binding(
                        get: { model.desktopPetSize },
                        set: { model.setDesktopPetSize($0) }
                    ), in: 48...192, step: 8)
                    Text("\(Int(model.desktopPetSize)) px")
                        .font(.caption.monospacedDigit())
                        .frame(width: 48, alignment: .trailing)
                }
                Text("Drag the pet anywhere. Hover for today's usage and right-click for actions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("About") {
                Text("EvoBar \(model.installedVersion) · Local-first AI companion")
                Text("No account. No analytics backend.").foregroundStyle(.secondary)
                Button("Privacy details…") {
                    isShowingPrivacyDetails = true
                }
            }
            Section("Local data") {
                Button("Export aggregate data…") {
                    model.exportLocalData()
                }
                Button("Reset all local data…", role: .destructive) {
                    isShowingResetConfirmation = true
                }
                .disabled(model.isResettingData)
                Text("Deletes companions, growth, usage aggregates, and scan history from this Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let message = model.settingsMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 8)
        .alert("Reset all EvoBar data?", isPresented: $isShowingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset permanently", role: .destructive) {
                model.resetLocalData()
            }
        } message: {
            Text("This cannot be undone. EvoBar will return to Welcome and rescan only usage created after the new companion is born.")
        }
        .sheet(isPresented: $isShowingPrivacyDetails) {
            PrivacyDetailsView()
        }
    }

    private func bandStepper(_ title: LocalizedStringKey, index: Int, step: Double) -> some View {
        let millions = Double(model.usageBandThresholds[index]) / 1_000_000
        return Stepper(
            value: Binding(
                get: { millions },
                set: { model.setUsageBandThreshold(index: index, millions: $0) }
            ),
            in: 0.5...5_000,
            step: step
        ) {
            HStack {
                Text(title)
                Spacer()
                Text("\(millions.formatted()) M")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func logPatternEditor(
        title: String,
        placeholder: String,
        value: Binding<String>,
        patterns: [String],
        providerID: ProviderID
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.bold())
            HStack {
                TextField(placeholder, text: value)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    model.addLogPattern(value.wrappedValue, providerID: providerID)
                    value.wrappedValue = ""
                }
                .disabled(value.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            ForEach(patterns, id: \.self) { pattern in
                HStack {
                    Text(pattern).font(.caption.monospaced()).lineLimit(1)
                    Spacer()
                    Button {
                        model.removeLogPattern(pattern, providerID: providerID)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }

    private var ownedAnimals: [AnimalDefinition] {
        (model.catalog?.animals ?? [])
            .filter { model.ownedAnimalIDs.contains($0.id) }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
}

private struct PrivacyDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Privacy", systemImage: "lock.shield.fill")
                    .font(.title2.bold())
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    privacySection(
                        title: "Local-first by design",
                        body: "Animal history, settings, usage aggregates, and scan checkpoints stay on this Mac. EvoBar has no account or analytics backend."
                    )
                    privacySection(
                        title: "Usage metadata only",
                        body: "EvoBar uses token counts, timestamps, provider, model, and a session identifier needed for accurate deduplication."
                    )
                    privacySection(
                        title: "Content is never collected",
                        body: "Prompts, responses, code, project contents, and raw JSONL lines are never stored, exported, logged, or transmitted."
                    )
                    privacySection(
                        title: "Limited network access",
                        body: "Optional network requests check official provider status and public GitHub Releases. Local usage data is never attached."
                    )
                    privacySection(
                        title: "You control your data",
                        body: "Settings can export privacy-filtered aggregates or permanently reset all local EvoBar data at any time."
                    )
                }
                .padding(20)
            }
        }
        .frame(width: 480, height: 500)
    }

    private func privacySection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(L10n.text(title)).font(.headline)
            Text(L10n.text(body))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let value = UInt64(cleaned, radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
