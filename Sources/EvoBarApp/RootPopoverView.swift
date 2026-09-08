import EvoBarCore
import EvoBarEvolution
import EvoBarUsage
import SwiftUI

struct RootPopoverView: View {
    @ObservedObject var model: AppModel
    var panelHeight: CGFloat = EvoStyle.height

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
        .frame(width: EvoStyle.width, height: panelHeight)
        .background(EvoStyle.background)
        .tint(EvoStyle.accent)
    }
}

private struct DashboardView: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let tabs: [AppSection] = [.home, .usage, .collection, .shop]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(EvoStyle.accent)
                    .font(.system(size: 16, weight: .semibold))
                Text(verbatim: "EvoBar").font(.system(size: 15, weight: .bold, design: .rounded))
                Spacer()
                EvoBadge(
                    title: L10n.text("ui.local", fallback: "On this Mac"),
                    icon: "lock.shield",
                    tint: .secondary
                )
                EvoIconButton(symbol: "gearshape", label: L10n.text("Settings"), isSelected: model.selectedSection == .settings) {
                    model.selectedSection = .settings
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 10)

            HStack(spacing: 4) {
                ForEach(Array(tabs.enumerated()), id: \.element.id) { index, section in
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.16)) {
                            model.selectedSection = section
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: section.symbol)
                                .font(.system(size: 11, weight: .semibold))
                            Text(section.displayName)
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(model.selectedSection == section ? EvoStyle.surface : .clear, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(model.selectedSection == section ? Color.primary : .secondary)
                        .shadow(color: .black.opacity(model.selectedSection == section ? 0.06 : 0), radius: 2, y: 1)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(KeyEquivalent(Character(String(index + 1))), modifiers: .command)
                    .accessibilityAddTraits(model.selectedSection == section ? [.isSelected] : [])
                    .accessibilityIdentifier("navigation.\(section.rawValue.lowercased())")
                }
            }
            .padding(4)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 11))
            .padding(.horizontal, EvoStyle.inset)
            .padding(.bottom, 10)

            if let updateURL = model.availableUpdateURL, let version = model.availableUpdateVersion {
                HStack {
                    Image(systemName: "arrow.down.circle").foregroundStyle(EvoStyle.accent)
                    Text("EvoBar \(version) is available").font(.caption)
                    Spacer()
                    Link("View release", destination: updateURL).font(.caption.weight(.semibold))
                }
                .padding(10)
                .background(EvoStyle.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, EvoStyle.inset)
                .padding(.bottom, 8)
            }
            if !model.providerStatusAlerts.isEmpty {
                VStack(spacing: 6) {
                    ForEach(model.providerStatusAlerts) { ProviderStatusBanner(status: $0) }
                }
                .padding(.horizontal, EvoStyle.inset)
                .padding(.bottom, 8)
            }

            Group {
                switch model.selectedSection {
                case .home: CompanionHomeView(model: model)
                case .usage: UsageDashboardView(model: model)
                case .collection: CompanionCollectionView(model: model)
                case .shop: ShopView(model: model)
                case .settings: SettingsView(model: model)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider().overlay(EvoStyle.border)
            HStack(spacing: 4) {
                EvoIconButton(symbol: "arrow.clockwise", label: L10n.text("Refresh now")) { model.refreshNow() }
                    .disabled(model.isRefreshing)
                    .keyboardShortcut("r", modifiers: .command)
                if model.isRefreshing {
                    ProgressView().controlSize(.mini)
                }
                Text(model.isRefreshing ? L10n.text("Refreshing…") : model.trackingStatus)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .help(model.trackingStatus)
                Spacer(minLength: 8)
                EvoIconButton(symbol: "macwindow", label: L10n.text("ui.openWindow", fallback: "Open dashboard window")) {
                    NotificationCenter.default.post(name: .evoBarOpenWindow, object: nil)
                }
                EvoIconButton(symbol: "power", label: L10n.text("ui.quit", fallback: "Quit EvoBar")) {
                    NSApp.terminate(nil)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
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
        status.freshness == .stale ? ", last known status" : ""
    }
}

private struct UsageDashboardView: View {
    @ObservedObject var model: AppModel
    @State private var selectedWindow = UsageWindowKind.today
    @State private var selectedProvider: ProviderID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.text("Usage")).font(.system(size: 21, weight: .bold, design: .rounded))
                    Text(L10n.text("ui.usageSubtitle", fallback: "A clear picture of your work with AI."))
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Picker("Usage window", selection: $selectedWindow) {
                    ForEach(UsageWindowKind.allCases) { kind in
                        Text(L10n.text(kind.fallbackTitle)).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                if let window {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(format(window.usage.totalTokens))
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            Text("tokens in \(window.sessionCount) sessions")
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
                        .labelsHidden()

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
                            .background(EvoStyle.surface, in: RoundedRectangle(cornerRadius: 12))
                        }

                        if model.showTokenBreakdown, !filteredModels.isEmpty {
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

                    DisclosureGroup(L10n.text("Official quota")) {
                        quotaSection.padding(.top, 10)
                    }
                    .font(.system(size: 12, weight: .medium))
                    .padding(12)
                    .background(EvoStyle.surface, in: RoundedRectangle(cornerRadius: 12))

                    Text("Updated \(window.interval.end.formatted(date: .omitted, time: .shortened)), API-equivalent estimate, pricing \(model.pricing?.effectiveAt ?? "unavailable")")
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
                        .background(EvoStyle.surface, in: RoundedRectangle(cornerRadius: 12))
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
                Text("\(providerName(quota.providerID)) \(quota.name)")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(Int((quota.utilization * 100).rounded()))%")
                    .font(.subheadline.monospacedDigit().bold())
            }
            ProgressView(value: quota.utilization)
                .tint(quota.utilization >= 0.95 ? .red : quota.utilization >= 0.8 ? .orange : .accentColor)
            HStack {
                Text(quota.resetsAt.map { L10n.format("quota.resets", fallback: "Resets %@", $0.formatted(.relative(presentation: .named))) } ?? L10n.text("Reset time unavailable"))
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
        .background(EvoStyle.surface, in: RoundedRectangle(cornerRadius: 12))
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
            Text(L10n.text(title)).font(.caption).foregroundStyle(.secondary)
            Text(format(value)).font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity)
        .padding(9)
        .background(EvoStyle.surface, in: RoundedRectangle(cornerRadius: 12))
    }

    private func format(_ value: Int64) -> String {
        AppModel.compactTokens(value)
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
        coverage >= 0.999 ? L10n.text("ui.apiEstimate", fallback: "API estimate") : L10n.format("ui.priced", fallback: "%lld%% priced", Int64((coverage * 100).rounded()))
    }
}

struct OnboardingView: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var selectedStarterID: AnimalDefinitionID = "cat"
    @State private var companionName = ""

    init(model: AppModel, initialPage: Int = 0) {
        self.model = model
        _page = State(initialValue: initialPage)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                EvoIconButton(symbol: "chevron.left", label: L10n.text("ui.back", fallback: "Back")) {
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) { page = max(0, page - 1) }
                }
                .disabled(page == 0 || model.isCompletingOnboarding)
                .opacity(page == 0 ? 0 : 1)
                Spacer()
                Text(L10n.format("ui.setupStep", fallback: "Step %lld of 3", Int64(page + 1)))
                    .font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index <= page ? EvoStyle.accent : Color.secondary.opacity(0.2))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 8)

            GeometryReader { geometry in
                ScrollView {
                    Group {
                        switch page {
                        case 0: welcome
                        case 1: providerDiscovery
                        default: starterSelection
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: max(0, geometry.size.height - 48))
                    .padding(24)
                }
            }
        }
    }

    private var welcome: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "pawprint.fill")
                .font(.system(size: 54, weight: .light))
                .foregroundStyle(EvoStyle.accent)
                .frame(width: 110, height: 110)
                .background(EvoStyle.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 28))
                .accessibilityHidden(true)
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
            Button { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) { page = 1 } } label: {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .buttonStyle(EvoActionStyle(prominent: true))
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
                Button("Continue") { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) { page = 2 } }
                    .buttonStyle(EvoActionStyle(prominent: true))
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
                                    .foregroundStyle(selectedStarterID == animal.id ? EvoStyle.accent : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            selectedStarterID == animal.id ? EvoStyle.accent.opacity(0.12) : Color.secondary.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedStarterID == animal.id ? EvoStyle.accent : .clear, lineWidth: 2)
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
                    Text("Start growing together").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(EvoActionStyle(prominent: true))
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

struct GraduationView: View {
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


extension Color {
    /// Shared by the popover and the evolution ceremony.
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
