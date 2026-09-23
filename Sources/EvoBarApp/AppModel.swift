import Combine
import AppKit
import ClaudeCodeProvider
import CodexProvider
import EvoBarCore
import EvoBarEvolution
import EvoBarInfrastructure
import EvoBarPersistence
import EvoBarPurchases
import EvoBarUsage
import Foundation
import UniformTypeIdentifiers

@MainActor
final class AppModel: ObservableObject {
    enum LoadState: Equatable {
        case loading
        case ready
        case failed(String)
    }

    @Published private(set) var loadState: LoadState = .loading
    @Published private(set) var catalog: AnimalCatalogManifest?
    @Published private(set) var lore: LoreManifest?
    private var illustratedAnimalIDs: Set<AnimalDefinitionID> = []
    @Published private(set) var storefront: StorefrontManifest?
    @Published private(set) var economy: GameEconomyManifest?
    /// While the product is being built, every line is owned and items are free.
    /// Every line is owned without a purchase, while the storefront is not live.
    @Published private(set) var unlockAllAnimals = false
    /// Shop items cost nothing. Off, so the wallet means something.
    @Published private(set) var freeItems = false
    @Published private(set) var onboardingCompleted = false
    @Published private(set) var isCompletingOnboarding = false
    @Published private(set) var onboardingError: String?
    @Published private(set) var providerDetections: [ProviderDetection] = []
    @Published private(set) var isDetectingProviders = false
    @Published private(set) var animalInstances: [AnimalInstance] = []
    @Published private(set) var starterGrantID: AnimalDefinitionID?
    @Published private(set) var activeProductIDs: Set<ProductID> = []
    @Published private(set) var usageDashboard: UsageDashboardSnapshot?
    @Published private(set) var pricing: ModelPricingManifest?
    @Published private(set) var quotaDashboard: QuotaDashboardSnapshot?
    @Published private(set) var quotaIsDemo = false
    @Published private(set) var providerStatusDashboard: ProviderStatusDashboardSnapshot?
    @Published private(set) var appUpdateState = AppUpdateState.idle
    @Published private(set) var isRefreshing = false
    @Published private(set) var trackingReports: [ProviderTrackingReport] = []
    @Published private(set) var lastTrackingCheck: Date?
    @Published var selectedSection: AppSection = .home
    @Published var selectedSettingsPage: SettingsPage = .general
    @Published var companionName = "Mochi"
    @Published var currentAnimalID: AnimalDefinitionID = "cat"
    @Published var currentXP: Int64 = 0
    @Published var acknowledgedStageIndex = 1
    @Published var todayTokens: Int64 = 0
    @Published var todayXP: Int64 = 0
    @Published var dailyRawTokens: [Int64] = []
    @Published var weekRawTokens: [Int64] = []
    @Published private(set) var pendingXP: Int64 = 0
    /// Non-nil while the evolution ceremony is playing.
    @Published private(set) var evolutionCeremony: EvolutionCeremony?
    /// Non-nil while a new companion is hatching on the Home tab.
    @Published private(set) var hatchCeremony: HatchCeremony?
    /// Kept until acknowledged; the individual itself is already saved on disk.
    @Published private(set) var hatchDiscovery: AnimalInstance?
    @Published private(set) var hatchIsNewDiscovery = false
    /// The last arrival of XP, for the Home tab to show landing.
    @Published private(set) var lastAbsorption: GrowthAbsorption?
    /// Counts arrivals, so two identical ones each still show.
    @Published private(set) var absorptionCount = 0
    @Published private(set) var isAbsorbing = false
    /// Whether the popover or the dashboard window is on screen. XP is taken
    /// in only while the Home tab can be seen, so its sweep is never missed.
    @Published var isPanelVisible = false
    @Published private(set) var affectionPoints: Int64 = AffectionEngine.starting
    /// Every act of care the active companion has received.
    @Published private(set) var careCount = 0
    @Published private(set) var petsRemainingToday = AffectionEngine.maxPetsPerDay
    @Published private(set) var treatsRemainingToday = AffectionEngine.maxTreatsPerDay
    /// Each individual's busiest recorded day, for its journal.
    @Published private(set) var busiestDays: [UUID: UsageRecordDay] = [:]
    /// Eggs warming, oldest first.
    @Published private(set) var incubator: [IncubatingEgg] = []
    @Published private(set) var isHatchingEgg = false
    @Published private(set) var isPlacingEgg = false
    @Published private(set) var isPetting = false
    @Published private(set) var isSwitchingCompanion = false
    @Published var switchMessage: String?
    @Published var incubatorMessage: String?
    @Published var careMessage: String?
    /// Result of the last card export, shown under the button that started it.
    @Published var cardExportMessage: String?
    @Published private(set) var usageBandThresholds: [Int64] = AppSettings.defaultUsageBandThresholds
    /// The scene backdrop in use, or nil to follow the companion's artwork.
    @Published private(set) var sceneThemeID: String?
    @Published var tokenCoins: Int64 = 0
    @Published private(set) var itemInventory: [String: Int] = [:]
    @Published var animationQuality: AnimationQuality = .balanced
    @Published var showTokenInMenuBar = true
    @Published private(set) var showTokenBreakdown = true
    @Published private(set) var claudeTrackingEnabled = true
    @Published private(set) var codexTrackingEnabled = true
    @Published private(set) var refreshIntervalMinutes = 1
    @Published private(set) var quotaNotificationsEnabled = false
    @Published private(set) var companionNotificationsEnabled = false
    @Published private(set) var providerStatusChecksEnabled = true
    @Published private(set) var automaticUpdateChecksEnabled = true
    @Published private(set) var launchAtLoginEnabled = false
    @Published private(set) var claudeAdditionalLogPatterns: [String] = []
    @Published private(set) var codexAdditionalLogPatterns: [String] = []
    @Published private(set) var desktopPetEnabled = false
    @Published private(set) var desktopPetSize: Double = 96
    @Published private(set) var pinnedAnimalDefinitionID: AnimalDefinitionID?
    @Published private(set) var desktopPetPosition: CGPoint?
    @Published private(set) var trackingStatus = L10n.text("status.starting", fallback: "Starting…")
    @Published private(set) var isEvolving = false
    @Published private(set) var isResettingData = false
    @Published private(set) var isGraduating = false
    @Published private(set) var graduationError: String?
    @Published private(set) var purchasingProductID: ProductID?
    @Published private(set) var purchaseMessage: String?
    @Published private(set) var settingsMessage: String?
    @Published private(set) var purchasingItemID: String?
    @Published private(set) var itemPurchaseMessage: String?
    @Published var storefrontTestScenario = StorefrontTestScenario.success

    private var store: EvoBarStore?
    private var purchaseService: (any PurchaseService)?
    private var signedLicensePurchaseService: SignedLicensePurchaseService?
#if DEBUG
    private var mockPurchaseService: MockPurchaseService?
#endif
    private var trackingTask: Task<Void, Never>?
    private var trackingGeneration = UUID()
    private var serviceRefreshTask: Task<Void, Never>?
    private lazy var refreshWorker = RefreshWorker { [weak self] force in
        await self?.performTrackingRefresh(force: force)
    }
    private var logWatcher: LogChangeWatcher?
    private var quotaMonitor: QuotaMonitor?
    private var providerStatusMonitor: ProviderStatusMonitor?
    private let appUpdateService: any AppUpdateChecking = GitHubReleaseUpdateService(
        owner: "kitesik",
        repository: "EvoBar"
    )
    private let notificationService: any LocalNotificationService = UserNotificationService()
    private var quotaAlertEvaluator = QuotaAlertEvaluator()
    private let launchAtLoginController = LaunchAtLoginController()
    private let animalAssetProvider: any AnimalAssetProviding = ManifestAnimalAssetProvider()
    private let runtime: AppRuntimeEnvironment

    init(runtime: AppRuntimeEnvironment = .current) {
        self.runtime = runtime
    }

    var isIsolatedRun: Bool { runtime.isSmokeTesting }

#if DEBUG
    /// Deterministic, in-memory presentation data. Only the isolated review harness
    /// may call this; it never reads user logs or writes a user's companion state.
    func prepareVisualReview(
        empty: Bool = false, pinnedID: AnimalDefinitionID? = nil, shopFeedback: Bool = false,
        settingsFeedback: Bool = false, shiny: Bool = false, sceneThemeID: String? = nil,
        incubating: Bool = false, discovery: Bool = false, duplicateDiscovery: Bool = false,
        collectionDuplicate: Bool = false, previewLockedAnimals: Bool = false,
        finalCompanion: Bool = false
    ) {
        guard runtime.isSmokeTesting else { return }
        loadState = .ready
        unlockAllAnimals = !previewLockedAnimals
        hatchDiscovery = nil
        itemInventory["random-egg"] = nil
        selectedSettingsPage = .general
        pinnedAnimalDefinitionID = pinnedID
        self.sceneThemeID = sceneThemeID
        purchaseMessage = shopFeedback ? L10n.text("purchase.cancelled", fallback: "Purchase cancelled.") : nil
        itemPurchaseMessage = shopFeedback ? L10n.text("item.insufficientCoins", fallback: "Not enough Token Coins.") : nil
        settingsMessage = settingsFeedback ? L10n.text("export.failed", fallback: "Data export failed.") : nil
        onboardingCompleted = true
        companionName = "Mochi"
        currentAnimalID = "cat"
        let finalStageIndex = catalog?.animals.first(where: { $0.id == "cat" })?.stages.count ?? 7
        acknowledgedStageIndex = empty ? 1 : finalCompanion ? finalStageIndex : 2
        currentXP = empty ? 0 : finalCompanion ? 2_200 : 218
        pendingXP = empty ? 0 : 28
        todayTokens = empty ? 0 : 15_400_000
        todayXP = empty ? 0 : 28
        tokenCoins = 246
        affectionPoints = 7_500
        careCount = 96
        starterGrantID = "cat"
        activeProductIDs = ["evobar.animal.dog", "evobar.animal.fox"]
        animationQuality = .powerSaver
        trackingStatus = L10n.text("ui.reviewStatus", fallback: "Up to date, just now")
        lastTrackingCheck = Date()
        trackingReports = [ProviderID.claudeCode, .codex].map {
            ProviderTrackingReport(providerID: $0, sourceCount: empty ? 0 : 4, checkedSourceCount: empty ? 0 : 4)
        }
        claudeTrackingEnabled = true
        codexTrackingEnabled = true
        refreshIntervalMinutes = 1
        updateTrackingStatus()
        let now = Date()
        let mochi = AnimalInstance(
            definitionID: "cat", name: companionName, createdAt: empty ? now : now.addingTimeInterval(-7 * 86400),
            currentXP: currentXP, acknowledgedStageIndex: acknowledgedStageIndex, isCurrent: true, isShiny: shiny,
            natureID: "curious", rarity: .common, cumulativeTokens: empty ? 0 : 38_600_000,
            providerTokens: empty ? [:] : [.claudeCode: 25_000_000, .codex: 13_600_000],
            finalEvolutionAt: finalCompanion ? now : nil,
            lastActivityAt: empty ? nil : now,
            firstGrowthAt: now.addingTimeInterval(-7 * 86400 + 3600),
            evolutionDates: finalCompanion
                ? Dictionary(uniqueKeysWithValues: (2...finalStageIndex).map {
                    ($0, now.addingTimeInterval(Double($0 - finalStageIndex) * 86400))
                  })
                : [2: now.addingTimeInterval(-5 * 86400)],
            adoringAt: now.addingTimeInterval(-2 * 86400), careCount: 96)
        animalInstances = [
            mochi,
            // Raised for a while and set aside: neither growing nor graduated.
            AnimalInstance(definitionID: "dog", name: "Biscuit", createdAt: now.addingTimeInterval(-22 * 86400),
                           currentXP: 900, acknowledgedStageIndex: 4, isShiny: shiny, natureID: "steady", rarity: .common,
                           careCount: 41),
        ]
        if collectionDuplicate {
            animalInstances.append(AnimalInstance(
                definitionID: "cat", name: "Bean", createdAt: now.addingTimeInterval(-3 * 86400),
                natureID: "bright", rarity: .common))
        }
        if incubating {
            // One warming, one ready, and one already hatched and waiting.
            incubator = [
                IncubatingEgg(placedAt: now.addingTimeInterval(-2 * 86400), activeDays: 1),
                IncubatingEgg(
                    placedAt: now.addingTimeInterval(-6 * 86400),
                    activeDays: IncubatingEgg.activeDaysToHatch),
            ]
            animalInstances.append(
                AnimalInstance(
                    definitionID: "fox", name: "Fox", createdAt: now.addingTimeInterval(-86400),
                    isCurrent: false, isShiny: true, natureID: "bright", rarity: .uncommon))
            itemInventory["random-egg"] = 1
        } else {
            incubator = []
        }
        if discovery || duplicateDiscovery {
            let definitionID: AnimalDefinitionID = duplicateDiscovery ? "cat" : "capybara"
            let arrival = AnimalInstance(definitionID: definitionID, name: duplicateDiscovery ? "Another Cat" : "Capybara", isShiny: true,
                                         natureID: "bright", rarity: .common)
            animalInstances.append(arrival)
            hatchDiscovery = arrival
            hatchIsNewDiscovery = !duplicateDiscovery
        }
        busiestDays = [mochi.id: UsageRecordDay(date: now.addingTimeInterval(-3 * 86400), tokens: 38_600_000)]
        weekRawTokens = empty ? [] : [4_800_000, 7_200_000, 3_400_000, 12_100_000, 8_600_000, 6_200_000, todayTokens]
        dailyRawTokens = Array(weekRawTokens.dropLast())
        let windows = UsageWindowKind.allCases.enumerated().map { index, kind in
            let multiplier = Int64(index + 1)
            let claude = TokenUsage(inputTokens: 1_920_000 * multiplier, outputTokens: 480_000 * multiplier,
                                    cacheReadTokens: 7_440_000 * multiplier, totalTokens: 9_840_000 * multiplier)
            let codex = TokenUsage(inputTokens: 1_760_000 * multiplier, outputTokens: 800_000 * multiplier,
                                   cacheReadTokens: 3_000_000 * multiplier, totalTokens: 5_560_000 * multiplier)
            return UsageWindowSnapshot(
                kind: kind, interval: DateInterval(start: Calendar.current.startOfDay(for: now), end: now),
                usage: TokenUsage(inputTokens: empty ? 0 : 3_680_000 * multiplier,
                                  outputTokens: empty ? 0 : 1_280_000 * multiplier,
                                  cacheReadTokens: empty ? 0 : 10_440_000 * multiplier, totalTokens: todayTokens * multiplier),
                sessionCount: empty ? 0 : 12,
                providers: empty ? [] : [
                    ProviderUsageBreakdown(providerID: .claudeCode, usage: claude, sessionCount: 7, estimatedAPICostUSD: 12, costCoverage: 1),
                    ProviderUsageBreakdown(providerID: .codex, usage: codex, sessionCount: 5, estimatedAPICostUSD: 4.87, costCoverage: 1),
                ],
                models: empty ? [] : [
                    ModelUsageBreakdown(providerID: .claudeCode, modelID: "Claude, example", usage: claude,
                                        estimatedAPICostUSD: 12, costCoverage: 1),
                    ModelUsageBreakdown(providerID: .codex, modelID: "Codex, example", usage: codex,
                                        estimatedAPICostUSD: 4.87, costCoverage: 1),
                ],
                estimatedAPICostUSD: empty ? nil : 16.87, costCoverage: 1,
                story: empty ? .empty : UsageStory(
                    activeSeconds: 3 * 3600 + 12 * 60, peakHour: 15, longestSessionSeconds: 108 * 60)
            )
        }
        usageDashboard = UsageDashboardSnapshot(
            generatedAt: now, windows: windows, streakDays: empty ? 0 : 5,
            bestDay: empty ? nil : UsageRecordDay(date: now.addingTimeInterval(-3 * 86_400), tokens: 38_600_000),
            yesterdayTokens: empty ? 0 : 6_200_000)
    }

#if DEBUG
    /// Real transactions in the disposable smoke store, never presentation-only IDs.
    func prepareLifecycleReview(readyEgg: Bool = false) async throws {
        precondition(runtime.isSmokeTesting)
        guard let store, let animal = catalog?.animals.first(where: { $0.id == "cat" }) else {
            throw CocoaError(.fileReadUnknown)
        }
        let start = Date().addingTimeInterval(-14 * 86_400)
        _ = try await store.completeOnboarding(starterID: "cat", companionName: "Mochi", startedAt: start)
        let event = UsageEvent(
            stableID: UsageEventID(rawValue: "lifecycle-review"), provider: .claudeCode,
            sessionID: "synthetic-lifecycle", timestamp: start, modelID: "fixture-model",
            usage: TokenUsage(inputTokens: 700_000_000, outputTokens: 0, totalTokens: 700_000_000),
            sourceFingerprint: "synthetic-lifecycle")
        _ = try await store.ingest(
            batch: ScanBatch(events: [event], checkpoint: SourceCheckpoint(byteOffset: 1, fileSize: 1), malformedLineCount: 0),
            sourceKey: "synthetic-lifecycle", providerID: .claudeCode, effectiveTokensPerCoin: 100_000)
        _ = try await store.absorbPendingXP(now: start, bonusRoll: 0.5, giftCoinRoll: 0, giftItemRoll: 0.5)
        for stage in 2..<animal.stages.count {
            try await store.acknowledgeEvolution(to: stage, finalStageIndex: animal.stages.count, evolvedAt: start)
        }
        if readyEgg {
            guard let item = try ManifestLoader.bundledEconomy().items.first(where: { $0.kind == .randomEgg }) else {
                throw CocoaError(.fileReadUnknown)
            }
            try await store.purchaseGameItem(item, chargeCoins: false)
            _ = try await store.placeEggInIncubator(at: start)
            for day in 1...IncubatingEgg.activeDaysToHatch {
                let event = UsageEvent(
                    stableID: UsageEventID(rawValue: "interactive-hatch-\(day)"), provider: .claudeCode,
                    sessionID: "synthetic-hatch", timestamp: start.addingTimeInterval(Double(day) * 86_400), modelID: "fixture-model",
                    usage: TokenUsage(inputTokens: 100_000, outputTokens: 0, totalTokens: 100_000),
                    sourceFingerprint: "synthetic-hatch")
                _ = try await store.ingest(
                    batch: ScanBatch(events: [event], checkpoint: SourceCheckpoint(byteOffset: UInt64(day), fileSize: UInt64(day)), malformedLineCount: 0),
                    sourceKey: "synthetic-hatch", providerID: .claudeCode, effectiveTokensPerCoin: 100_000)
            }
            _ = try await store.absorbPendingXP(now: Date(), bonusRoll: 0.5, giftCoinRoll: 0, giftItemRoll: 0.5)
        }
        apply(await store.snapshot())
        precondition(isEvolutionReady && pendingXP == 0 && currentAnimalInstance != nil)
        precondition(!readyEgg || incubator.first?.isReady == true)
        animationQuality = .balanced
        isPanelVisible = true
        selectedSection = .home
    }
#endif

    /// Selects an authored Shiny stage only inside the in-memory artwork review.
    func prepareArtworkReview(animalID: AnimalDefinitionID, stageIndex: Int) {
        guard runtime.isSmokeTesting,
              let animal = catalog?.animals.first(where: { $0.id == animalID && $0.hasShinyArtwork == true }),
              let stage = animal.stages.first(where: { $0.index == stageIndex }) else { return }
        prepareVisualReview(shiny: true)
        // Artwork-only fixture instances are not the isolated store's active
        // animal. Animation previews must not start an unrelated growth save.
        pendingXP = 0
        careMessage = nil
        currentAnimalID = animalID
        companionName = "Peach"
        currentXP = stage.xpThreshold
        acknowledgedStageIndex = stageIndex
        activeProductIDs.insert(animal.purchaseProductID)
        let now = Date()
        animalInstances = [AnimalInstance(
            definitionID: animalID, name: companionName, createdAt: now.addingTimeInterval(-12 * 86400),
            currentXP: currentXP, acknowledgedStageIndex: stageIndex, isCurrent: true, isShiny: true,
            natureID: "steady", rarity: .common, cumulativeTokens: 38_600_000,
            providerTokens: [.claudeCode: 25_000_000, .codex: 13_600_000], lastActivityAt: now)]
    }

    func prepareStartupFailureReview() {
        guard runtime.isSmokeTesting else { return }
        loadState = .failed("Isolated startup recovery fixture")
    }

    func prepareIncubatorPromptReview(activeDays: Int?, held: Bool) {
        guard runtime.isSmokeTesting else { return }
        prepareVisualReview()
        incubator = activeDays.map { [IncubatingEgg(activeDays: $0)] } ?? []
        itemInventory["random-egg"] = held ? 1 : nil
        selectedSection = .home
    }

    func prepareTrackingReview(issues: Set<TrackingIssue> = [], connected: Bool = false, paused: Bool = false, manual: Bool = false) {
        guard runtime.isSmokeTesting else { return }
        prepareVisualReview(empty: true)
        selectedSection = .home
        claudeTrackingEnabled = !paused
        codexTrackingEnabled = !paused
        refreshIntervalMinutes = manual ? 0 : 1
        trackingReports = paused ? [] : [
            ProviderTrackingReport(providerID: .claudeCode, sourceCount: connected ? 2 : 0,
                                   checkedSourceCount: connected ? 2 : 0, issues: issues),
            ProviderTrackingReport(providerID: .codex)
        ]
        updateTrackingStatus()
    }
#endif

    var currentAnimal: AnimalDefinition? {
        catalog?.animals.first { $0.id == currentAnimalID }
    }

    var currentAnimalInstance: AnimalInstance? {
        animalInstances.first(where: \.isCurrent)
    }

    var displayedCompanion: CompanionDisplaySelection {
        CompanionDisplaySelection.resolve(
            currentDefinitionID: currentAnimalID,
            pinnedDefinitionID: pinnedAnimalDefinitionID,
            ownedDefinitionIDs: ownedAnimalIDs,
            availableDefinitionIDs: illustratedAnimalIDs,
            instances: animalInstances
        )
    }

    var desktopPetInstance: AnimalInstance? { displayedCompanion.instance }

    var desktopPetAnimal: AnimalDefinition? {
        let definitionID = displayedCompanion.definitionID
        return catalog?.animals.first { $0.id == definitionID } ?? currentAnimal
    }

    var displayedCompanionName: String {
        desktopPetInstance?.name ?? desktopPetAnimal.map(L10n.animal) ?? companionName
    }

    var displayedCompanionStageName: String {
        desktopPetAnimal?.stages.first { $0.index == displayedCompanion.stageIndex }.map(L10n.stage)
            ?? L10n.text("Growing companion")
    }

    var desktopPetAsset: AnimalAssetReference? {
        guard let animal = desktopPetAnimal else { return nil }
        let instance = desktopPetInstance
        return animalAssetProvider.asset(
            for: animal,
            stageIndex: instance?.acknowledgedStageIndex ?? 1,
            isShiny: instance?.isShiny ?? false,
            visualState: companionVisualState
        )
    }

    var menuBarAsset: AnimalAssetReference? { desktopPetAsset }

    var quotaWarningWindow: QuotaWindow? {
        quotaDashboard?.providers
            .flatMap(\.windows)
            .filter { $0.freshness == .fresh && $0.utilization >= 0.8 }
            .max { $0.utilization < $1.utilization }
    }

    var providerStatusAlerts: [ProviderOperationalStatus] {
        providerStatusDashboard?.providers.filter {
            $0.condition == .degraded || $0.condition == .outage
        } ?? []
    }

    var installedVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    }

    var availableUpdateURL: URL? {
        guard case .available(_, let release) = appUpdateState else { return nil }
        return release.releasePageURL
    }

    var availableUpdateVersion: String? {
        guard case .available(_, let release) = appUpdateState else { return nil }
        return release.version.description
    }

    var isCheckingForUpdates: Bool {
        if case .checking = appUpdateState { return true }
        return false
    }

    var updateStatusText: String {
        switch appUpdateState {
        case .idle: L10n.text("status.update.idle", fallback: "Not checked yet.")
        case .checking: L10n.text("status.update.checking", fallback: "Checking GitHub Releases…")
        case .available(_, let release):
            L10n.format("status.update.available", fallback: "EvoBar %@ is available.", release.version.description)
        case .upToDate(let current, _):
            L10n.format("status.update.current", fallback: "EvoBar %@ is up to date.", current.description)
        case .unavailable(let message): message
        }
    }

    var companionVisualState: CompanionVisualState {
        if isEvolutionReady { return .evolutionReady }
        guard let lastActivity = currentAnimalInstance?.lastActivityAt else { return .idle }
        let inactive = Date().timeIntervalSince(lastActivity)
        if inactive < 2 * 60 { return .working }
        if inactive >= 8 * 60 * 60 { return .sleeping }
        return .idle
    }

    var ownedAnimalIDs: Set<AnimalDefinitionID> {
        if unlockAllAnimals, let catalog { return Set(catalog.animals.map(\.id)) }
        let starterGrant = validStarterGrantID
        guard let storefront else { return starterGrant.map { [$0] } ?? [] }
        return EntitlementResolver.resolve(
            starterGrant: starterGrant,
            snapshot: EntitlementSnapshot(activeProductIDs: activeProductIDs),
            storefront: storefront
        ).ownedAnimalIDs
    }

    private var validStarterGrantID: AnimalDefinitionID? {
        guard let starterGrantID,
              catalog?.animals.contains(where: { $0.id == starterGrantID && $0.isStarter }) == true else {
            return nil
        }
        return starterGrantID
    }

    var purchasesAvailable: Bool {
#if DEBUG
        true
#else
        signedLicensePurchaseService != nil
#endif
    }

    var licenseImportAvailable: Bool { signedLicensePurchaseService != nil }

    var hasShinyCharm: Bool { (itemInventory["shiny-charm"] ?? 0) > 0 }
    var collectionProgress: CollectionProgress {
        CollectionProgress(animals: catalog?.animals ?? [], instances: animalInstances)
    }
    var randomEggCount: Int { itemInventory["random-egg"] ?? 0 }

    /// Companions that hatched and are waiting to be raised, newest first.
    var waitingCompanions: [AnimalInstance] {
        animalInstances.filter(\.isWaitingToBeRaised).sorted { $0.createdAt > $1.createdAt }
    }

    /// Raised for a while and set aside, the furthest along first.
    var restingCompanions: [AnimalInstance] {
        animalInstances.filter(\.isResting).sorted {
            $0.acknowledgedStageIndex != $1.acknowledgedStageIndex
                ? $0.acknowledgedStageIndex > $1.acknowledgedStageIndex
                : $0.createdAt > $1.createdAt
        }
    }

    /// Anything that could grow next: what waits and what rests.
    var companionsToRaiseNext: [AnimalInstance] { waitingCompanions + restingCompanions }

    /// Makes another companion the one that grows. The one stepping aside keeps
    /// everything, including growth it has not taken in yet.
    func raiseCompanion(
        instanceID: UUID, name: String? = nil,
        onSuccess: (@MainActor () -> Void)? = nil
    ) {
        guard let store, onboardingCompleted, !isSwitchingCompanion,
              !isEvolving, !isGraduating else { return }
        isSwitchingCompanion = true
        switchMessage = nil
        Task { [weak self] in
            defer { self?.isSwitchingCompanion = false }
            do {
                _ = try await store.switchCurrentCompanion(to: instanceID, name: name)
                guard let self else { return }
                apply(await store.snapshot())
                // Keep the detail and its retry context until the switch is durable.
                onSuccess?()
                selectedSection = .home
            } catch CompanionSwitchError.emptyName {
                self?.switchMessage = L10n.text("switch.needName", fallback: "Give them a name first.")
            } catch {
                self?.switchMessage = L10n.text(
                    "switch.failed", fallback: "That companion could not be raised.")
            }
        }
    }

    var canPlaceEgg: Bool {
        randomEggCount > 0 && incubator.count < IncubatingEgg.capacity && !isPlacingEgg && !isResettingData
    }

    var incubatorNeedsAttention: Bool {
        incubatorMessage != nil || incubator.contains(where: \.isReady)
    }

    var canOpenEgg: Bool {
        onboardingCompleted && !isResettingData && !isHatchingEgg && !isAbsorbing
            && !isEvolving && !isGraduating && !isSwitchingCompanion
            && hatchDiscovery == nil && hatchCeremony == nil && evolutionCeremony == nil
    }

    func placeEggInIncubator() {
        guard let store, canPlaceEgg else { return }
        isPlacingEgg = true
        incubatorMessage = nil
        Task { [weak self] in
            defer { self?.isPlacingEgg = false }
            do {
                try await store.placeEggInIncubator()
                guard let self else { return }
                apply(await store.snapshot())
            } catch IncubatorStoreError.full {
                self?.incubatorMessage = L10n.text(
                    "incubator.full", fallback: "The incubator is full.")
            } catch {
                self?.incubatorMessage = L10n.text(
                    "incubator.failed", fallback: "The egg could not be placed.")
            }
        }
    }

    /// Opens exactly the egg the user chose. Merely visiting Home never spends an egg.
    /// The draw is made here, where the catalog and the charm are, and the
    /// store only records what it produced.
    func openEgg(id: UUID) {
        guard let store, let catalog, let economy, canOpenEgg, isPanelVisible,
              let ready = incubator.first(where: { $0.id == id && $0.isReady }) else { return }
        isHatchingEgg = true
        incubatorMessage = nil
        selectedSection = .home
        Task { [weak self] in
            defer { self?.isHatchingEgg = false }
            guard let self else { return }
            var generator = SystemRandomNumberGenerator()
            do {
                let result = try HatchEngine.hatch(
                    ownedAnimalIDs: ownedAnimalIDs, catalog: catalog, economy: economy,
                    hasShinyCharm: hasShinyCharm, using: &generator
                )
                let isNew = !animalInstances.contains { $0.definitionID == result.animal.id }
                let hatched = try await store.hatchEgg(
                    id: ready.id,
                    definitionID: result.animal.id,
                    name: L10n.animal(result.animal),
                    natureID: result.nature.id,
                    rarity: result.animal.hatchProfile.rarity,
                    isShiny: result.isShiny
                )
                apply(await store.snapshot())
                hatchIsNewDiscovery = isNew
                hatchDiscovery = hatched
                hatchCeremony = HatchCeremony(
                    to: animalAssetProvider.asset(
                        for: result.animal, stageIndex: 1, isShiny: hatched.isShiny,
                        visualState: .idle),
                    companionName: hatched.name,
                    animalName: L10n.animal(result.animal),
                    rarity: hatched.rarity,
                    isShiny: hatched.isShiny,
                    themeColorHex: result.animal.themeColorHex
                )
                try? await Task.sleep(for: .seconds(HatchCeremonyView.total))
                hatchCeremony = nil
            } catch {
                incubatorMessage = L10n.text("incubator.openFailed", fallback: "Could not open the egg. Your egg is safe; try again.")
            }
        }
    }

    func acknowledgeHatch(viewCollection: Bool = false) {
        guard hatchCeremony == nil else { return }
        hatchDiscovery = nil
        if viewCollection { selectedSection = .collection }
        absorbGrowthIfNeeded()
    }

    /// Raises one that was waiting, and graduates the one that finished.
    func graduateAndAdopt(instanceID: UUID, name: String) {
        guard let store, let currentAnimal, isGraduationReady, !isGraduating else { return }
        let finalStageIndex = currentAnimal.stages.count
        isGraduating = true
        graduationError = nil
        Task { [weak self] in
            do {
                _ = try await store.graduateCurrentAndAdopt(
                    instanceID: instanceID,
                    name: String(name.prefix(24)),
                    finalStageIndex: finalStageIndex
                )
                guard let self else { return }
                apply(await store.snapshot())
                isGraduating = false
            } catch {
                self?.isGraduating = false
                self?.graduationError = L10n.text(
                    "error.companion.next", fallback: "Could not start the next companion.")
            }
        }
    }

    var isStorefrontTestMode: Bool {
#if DEBUG
        true
#else
        false
#endif
    }

    var currentStage: EvolutionStageDefinition? {
        currentAnimal?.stages.first { $0.index == acknowledgedStageIndex }
    }

    var nextStage: EvolutionStageDefinition? {
        guard let currentAnimal else { return nil }
        return EvolutionEngine.nextStage(
            after: acknowledgedStageIndex,
            stages: currentAnimal.stages
        )
    }

    var progress: Double {
        guard let currentAnimal else { return 0 }
        return EvolutionEngine.progress(
            xp: currentXP,
            acknowledgedStageIndex: acknowledgedStageIndex,
            stages: currentAnimal.stages
        )
    }

    /// Where the bar will stand once the waiting XP has arrived.
    var previewProgress: Double {
        guard let currentAnimal else { return 0 }
        return EvolutionEngine.progress(
            xp: saturating(currentXP, plus: pendingXP),
            acknowledgedStageIndex: acknowledgedStageIndex,
            stages: currentAnimal.stages
        )
    }

    private func saturating(_ lhs: Int64, plus rhs: Int64) -> Int64 {
        let (sum, overflow) = lhs.addingReportingOverflow(rhs)
        return overflow ? Int64.max : sum
    }

    var treatItem: GameItemDefinition? { economy?.items.first { $0.kind == .treat } }

    // Lead with discovering a companion and caring for it, not growth shortcuts.
    var shopEssentials: [GameItemDefinition] {
        [GameItemKind.randomEgg, .treat].flatMap { kind in
            (economy?.items ?? []).filter { $0.kind == kind }
        }
    }

    var shopExtras: [GameItemDefinition] {
        (economy?.items ?? []).filter { $0.kind != .randomEgg && $0.kind != .treat && $0.kind != .sceneTheme }
    }

    var shopScenery: [GameItemDefinition] {
        (economy?.items ?? []).filter { $0.kind == .sceneTheme }
    }

    var shinyCount: Int { animalInstances.filter(\.isShiny).count }

    var sceneTheme: SceneTheme? { sceneThemeID.flatMap(SceneTheme.init(itemID:)) }

    func ownsItem(_ id: String) -> Bool { (itemInventory[id] ?? 0) > 0 }

    /// Writes one companion's card to a file the user picks. Nothing leaves the
    /// machine: the panel is the only place it goes.
    func exportCompanionCard(_ instance: AnimalInstance) {
        guard let animal = catalog?.animals.first(where: { $0.id == instance.definitionID })
        else { return }
        let card = CompanionCardView(
            animal: animal,
            instance: instance,
            stage: animal.stages.first { $0.index == instance.acknowledgedStageIndex }
        )
        do {
            let data = try CompanionCardExporter.png(for: card)
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.png]
            panel.nameFieldStringValue = CompanionCardExporter.fileName(for: instance)
            panel.message = L10n.text("card.save", fallback: "Save this companion's card")
            guard panel.runModal() == .OK, let url = panel.url else { return }
            try data.write(to: url, options: .atomic)
            cardExportMessage = L10n.text("card.saved", fallback: "Card saved.")
        } catch {
            cardExportMessage = L10n.text("card.failed", fallback: "The card could not be saved.")
        }
    }

    /// Wearing a backdrop, or pressing it again to take it off and let the
    /// scene follow the artwork. It touches nothing but how the scene looks.
    func setSceneTheme(_ id: String?) {
        if let id, !ownsItem(id), !freeItems { return }
        sceneThemeID = sceneThemeID == id ? nil : id
        persistAppSettings()
    }

    var canTreatNow: Bool {
        guard let treatItem, treatsRemainingToday > 0, purchasingItemID == nil, !isResettingData else { return false }
        return freeItems || tokenCoins >= treatItem.tokenCoinPrice
    }

    var eligibleStageIndex: Int {
        guard let currentAnimal else { return 1 }
        return EvolutionEngine.eligibleStageIndex(xp: currentXP, stages: currentAnimal.stages)
    }

    var isEvolutionReady: Bool {
        eligibleStageIndex > acknowledgedStageIndex
    }

    var isGraduationReady: Bool {
        guard let currentAnimal else { return false }
        return acknowledgedStageIndex == currentAnimal.stages.count
    }

    var menuBarTitle: String {
        let emoji = currentAnimal?.menuBarEmoji ?? "🐾"
        let companion = isEvolutionReady ? "\(emoji)✨" : emoji
        let metrics = menuBarMetricsTitle
        return metrics.isEmpty ? companion : "\(companion) \(metrics)"
    }

    var menuBarMetricsTitle: String {
        guard showTokenInMenuBar else { return "" }
        var metrics = [Self.compactTokens(todayTokens)]
        if let cost = usageDashboard?.window(.today)?.estimatedAPICostUSD {
            metrics.append(Self.compactUSD(cost))
        }
        if let utilization = quotaDashboard?.providers
            .flatMap(\.windows)
            .filter({ $0.freshness == .fresh })
            .map(\.utilization)
            .max() {
            metrics.append("\(Int((utilization * 100).rounded()))%")
        }
        return metrics.joined(separator: "  ")
    }

    func openSettings(page: SettingsPage? = nil) {
        if let page { selectedSettingsPage = page }
        selectedSection = .settings
    }

    func dismissPurchaseFeedback() { purchaseMessage = nil }
    func dismissItemFeedback() { itemPurchaseMessage = nil }
    func dismissSettingsFeedback() { settingsMessage = nil }

    func retryLoading() {
        guard case .failed = loadState else { return }
        loadState = .loading
        load()
    }

    func load() {
        do {
            let catalog = try ManifestLoader.bundledCatalog()
            let storefront = try ManifestLoader.bundledStorefront()
            let economy = try ManifestLoader.bundledEconomy()
            let pricing = try ManifestLoader.bundledPricing()
            try ManifestLoader.validate(catalog: catalog, storefront: storefront, economy: economy)
            try ManifestLoader.validate(pricing: pricing)
            let lore = try ManifestLoader.bundledLore()
            try ManifestLoader.validate(lore: lore, catalog: catalog)
            self.catalog = catalog
            self.lore = lore
            let configuration = try? AppConfiguration.bundled()
            unlockAllAnimals = configuration?.grantsEveryAnimal ?? false
            freeItems = configuration?.itemsAreFree ?? false
            illustratedAnimalIDs = Set(catalog.animals.filter { BundledAnimalSpriteStore.hasArtwork(for: $0) }.map(\.id))
            self.storefront = storefront
            self.economy = economy
            self.pricing = pricing
            let store = try EvoBarStore(fileURL: runtime.storeURL ?? EvoBarStore.defaultStoreURL())
            self.store = store
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await store.reconcileCatalogRetirement(
                        availableAnimalIDs: Set(catalog.animals.map(\.id)),
                        starterIDs: Set(catalog.animals.filter(\.isStarter).map(\.id))
                    )
                } catch {
                    loadState = .failed(String(describing: error))
                    return
                }
                let snapshot = await store.snapshot()
                apply(snapshot)
                launchAtLoginEnabled = launchAtLoginController.isEnabled
                try? await store.updateAppSettings(currentAppSettings())
                usageDashboard = await store.usageDashboard(pricing: pricing)
                configurePurchaseService(storefront: storefront, snapshot: snapshot)
                await reconcileReleaseEntitlements()
                configureQuotaMonitor()
                configureProviderStatusMonitor()
                loadState = .ready
                guard !runtime.isSmokeTesting else { return }
                if onboardingCompleted {
                    startTracking()
                } else {
                    detectProviders()
                }
                if automaticUpdateChecksEnabled {
                    await performUpdateCheck()
                }
            }
        } catch {
            loadState = .failed(String(describing: error))
        }
    }

    func detectProviders() {
        guard !runtime.isSmokeTesting else { return }
        guard !isDetectingProviders else { return }
        isDetectingProviders = true
        providerDetections = [
            ProviderDetection(providerID: .claudeCode, displayName: "Claude Code", state: .checking),
            ProviderDetection(providerID: .codex, displayName: "Codex", state: .checking),
        ]
        let claudePatterns = claudeAdditionalLogPatterns
        let codexPatterns = codexAdditionalLogPatterns
        Task { [weak self] in
            async let claudeStatus = ClaudeCodeUsageProvider(additionalPatterns: claudePatterns).detectionStatus()
            async let codexStatus = CodexUsageProvider(additionalPatterns: codexPatterns).detectionStatus()
            let detections = [
                ProviderDetection(
                    providerID: .claudeCode,
                    displayName: "Claude Code",
                    state: ProviderDetectionState(await claudeStatus)
                ),
                ProviderDetection(
                    providerID: .codex,
                    displayName: "Codex",
                    state: ProviderDetectionState(await codexStatus)
                ),
            ]
            guard let self else { return }
            providerDetections = detections
            isDetectingProviders = false
        }
    }

    func completeOnboarding(starterID: AnimalDefinitionID, name: String) {
        guard let store,
              catalog?.animals.contains(where: { $0.id == starterID && $0.isStarter }) == true,
              !isCompletingOnboarding else { return }
        isCompletingOnboarding = true
        onboardingError = nil
        Task { [weak self] in
            do {
                try await store.completeOnboarding(
                    starterID: starterID,
                    companionName: String(name.prefix(24))
                )
                let snapshot = await store.snapshot()
                guard let self else { return }
                apply(snapshot)
                isCompletingOnboarding = false
                startTracking()
            } catch {
                self?.isCompletingOnboarding = false
                self?.onboardingError = L10n.text("error.companion.create", fallback: "Could not create your companion. Please try again.")
            }
        }
    }

    func evolve() {
        guard let store, let currentAnimal, isEvolutionReady, !isEvolving,
              !isHatchingEgg, hatchDiscovery == nil else { return }
        let targetStageIndex = acknowledgedStageIndex + 1
        let finalStageIndex = currentAnimal.stages.count
        let isShiny = currentAnimalInstance?.isShiny ?? false
        // Both forms are captured before the write so the ceremony can cross-fade them.
        let ceremony = currentAnimal.stages
            .first { $0.index == targetStageIndex }
            .map { target in
                EvolutionCeremony(
                    from: animalAssetProvider.asset(
                        for: currentAnimal,
                        stageIndex: acknowledgedStageIndex,
                        isShiny: isShiny,
                        visualState: .evolutionReady
                    ),
                    to: animalAssetProvider.asset(
                        for: currentAnimal,
                        stageIndex: targetStageIndex,
                        isShiny: isShiny,
                        visualState: .idle
                    ),
                    stageName: L10n.stage(target),
                    companionName: companionName,
                    themeColorHex: currentAnimal.themeColorHex,
                    isFinal: targetStageIndex == finalStageIndex
                )
            }
        isEvolving = true
        Task { [weak self] in
            do {
                try await store.acknowledgeEvolution(
                    to: targetStageIndex,
                    finalStageIndex: finalStageIndex
                )
                let snapshot = await store.snapshot()
                guard let self else { return }
                let events = pendingCompanionEvents(in: snapshot)
                apply(snapshot)
                evolutionCeremony = ceremony
                careMessage = nil
                await deliverCompanionEvents(events)
                if ceremony != nil {
                    try? await Task.sleep(for: .seconds(EvolutionCeremonyView.total))
                }
                evolutionCeremony = nil
                isEvolving = false
            } catch {
                self?.evolutionCeremony = nil
                self?.isEvolving = false
                self?.careMessage = L10n.text("evolution.saveFailed", fallback: "Evolution could not be saved. Your progress is safe; please try again.")
            }
        }
    }

    func resetLocalData() {
        guard let store, !isResettingData, !isHatchingEgg, !isPlacingEgg,
              !isPetting, purchasingItemID == nil, !isAbsorbing else { return }
        isResettingData = true
        stopTracking()
        Task { [weak self] in
            do {
                await self?.refreshWorker.waitUntilIdle()
                try await store.resetAllData()
                let snapshot = await store.snapshot()
                guard let self else { return }
                apply(snapshot)
                hatchDiscovery = nil
                incubatorMessage = nil
                usageDashboard = await store.usageDashboard(pricing: pricing)
                trackingStatus = L10n.text("status.notConnected", fallback: "Not connected")
                trackingReports = []
                lastTrackingCheck = nil
                isResettingData = false
                detectProviders()
            } catch {
                self?.isResettingData = false
                self?.trackingStatus = L10n.text("status.resetFailed", fallback: "Reset failed")
            }
        }
    }

    func graduateAndStart(definitionID: AnimalDefinitionID, name: String) {
        guard let animal = catalog?.animals.first(where: { $0.id == definitionID }),
              ownedAnimalIDs.contains(definitionID),
              let nature = catalog?.natures.randomElement() else {
            graduationError = L10n.text("error.animal.unavailable", fallback: "That animal line is not available.")
            return
        }
        startNextCompanion(
            animal: animal,
            name: name,
            nature: nature,
            isShiny: false
        )
    }

    func graduateAndHatch(name: String) {
        guard let catalog, let economy, randomEggCount > 0 else {
            graduationError = L10n.text("error.egg.required", fallback: "Buy a Random Egg from the Shop first.")
            return
        }
        do {
            var generator = SystemRandomNumberGenerator()
            let result = try HatchEngine.hatch(
                ownedAnimalIDs: ownedAnimalIDs,
                catalog: catalog,
                economy: economy,
                hasShinyCharm: hasShinyCharm,
                using: &generator
            )
            startNextCompanion(
                animal: result.animal,
                name: name,
                nature: result.nature,
                isShiny: result.isShiny,
                consumingItemID: "random-egg"
            )
        } catch {
            graduationError = L10n.text("error.hatch.unavailable", fallback: "No owned animal line is available to hatch.")
        }
    }

    /// A line whose artwork has not shipped would arrive as a bare emoji, so it
    /// is listed as coming soon rather than sold.
    func productAwaitsArtwork(_ product: StorefrontProductDefinition) -> Bool {
        guard product.kind == .animal, let catalog else { return false }
        return product.grantsAnimalIDs.contains { id in
            guard let animal = catalog.animals.first(where: { $0.id == id }) else { return false }
            return !BundledAnimalSpriteStore.hasArtwork(for: animal)
        }
    }

    func purchase(_ productID: ProductID) {
        guard let purchaseService, purchasesAvailable, purchasingProductID == nil else { return }
        if let product = storefront?.products.first(where: { $0.id == productID }),
           productAwaitsArtwork(product) { return }
        purchasingProductID = productID
        purchaseMessage = nil
        Task { [weak self] in
            let result = await purchaseService.purchase(productID)
            guard let self else { return }
            switch result {
            case .purchased:
                do {
                    let entitlements = try await purchaseService.currentEntitlements()
                    try await persist(entitlements)
                    purchaseMessage = L10n.text("purchase.completed", fallback: "Purchase completed in Storefront test mode.")
                } catch {
                    purchaseMessage = L10n.text("purchase.refreshFailed", fallback: "Purchased, but entitlement refresh failed.")
                }
            case .pending:
                purchaseMessage = L10n.text("purchase.pending", fallback: "Purchase is pending.")
            case .userCancelled:
                purchaseMessage = L10n.text("purchase.cancelled", fallback: "Purchase cancelled.")
            case .failed(let code):
                purchaseMessage = L10n.format("purchase.failed", fallback: "Purchase failed: %@", code)
            }
            purchasingProductID = nil
        }
    }

    func purchaseGameItem(_ item: GameItemDefinition, onSuccess: (@MainActor () -> Void)? = nil) {
        guard let store, purchasingItemID == nil, !isResettingData else { return }
        let replacementNatureID: String?
        if item.kind == .mint {
            replacementNatureID = catalog?.natures
                .filter { $0.id != currentAnimalInstance?.natureID }
                .randomElement()?.id
        } else {
            replacementNatureID = nil
        }
        purchasingItemID = item.id
        itemPurchaseMessage = nil
        let chargeCoins = !freeItems
        let waitingBefore = pendingXP
        Task { [weak self] in
            do {
                try await store.purchaseGameItem(
                    item, replacementNatureID: replacementNatureID, chargeCoins: chargeCoins)
                guard let self else { return }
                apply(await store.snapshot())
                switch item.kind {
                case .rareCandy:
                    itemPurchaseMessage = L10n.format(
                        "item.candy.applied", fallback: "+%lld XP is waiting on Home.",
                        max(0, pendingXP - waitingBefore))
                case .treat:
                    itemPurchaseMessage = L10n.text("item.treat.applied", fallback: "Treat shared. Affection is up.")
                    careMessage = itemPurchaseMessage
                case .mint: itemPurchaseMessage = L10n.text("item.mint.applied", fallback: "Nature rerolled.")
                case .shinyCharm: itemPurchaseMessage = L10n.text("item.charm.applied", fallback: "Shiny Charm will affect future hatches.")
                case .randomEgg: itemPurchaseMessage = L10n.text("item.egg.applied", fallback: "Egg added. Place it in the incubator on Home or in Collection.")
                case .sceneTheme:
                    itemPurchaseMessage = L10n.text("item.scene.applied", fallback: "Backdrop bought and worn.")
                }
                onSuccess?()
            } catch GameShopStoreError.insufficientCoins {
                self?.itemPurchaseMessage = L10n.text("item.insufficientCoins", fallback: "Not enough Token Coins.")
            } catch GameShopStoreError.alreadyOwned {
                self?.itemPurchaseMessage = L10n.text("item.alreadyOwned", fallback: "You already own this item.")
            } catch {
                self?.itemPurchaseMessage = L10n.text("item.applyFailed", fallback: "Item could not be applied.")
            }
            if item.kind == .treat { self?.careMessage = self?.itemPurchaseMessage }
            self?.purchasingItemID = nil
        }
    }

    func restorePurchases() {
        guard let purchaseService, purchasesAvailable, purchasingProductID == nil else { return }
        purchaseMessage = nil
        Task { [weak self] in
            do {
                let entitlements = try await purchaseService.restorePurchases()
                guard let self else { return }
                try await persist(entitlements)
                purchaseMessage = L10n.text("purchase.restored", fallback: "Purchases restored.")
            } catch {
                self?.purchaseMessage = L10n.text("purchase.restoreFailed", fallback: "Restore failed. Existing offline entitlements were kept.")
            }
        }
    }

    func importLicense() {
        guard let signedLicensePurchaseService else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = L10n.text(
            "license.import.prompt",
            fallback: "Choose a signed EvoBar license file."
        )
        guard panel.runModal() == .OK, let url = panel.url else { return }

        Task { [weak self] in
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let size = attributes[.size] as? NSNumber,
                   size.intValue > SignedLicenseVerifier.maximumEnvelopeBytes {
                    throw SignedLicenseError.oversizedLicense
                }
                let data = try Data(contentsOf: url)
                let entitlements = try await signedLicensePurchaseService.importLicense(data)
                guard let self else { return }
                try await persist(entitlements)
                purchaseMessage = L10n.text(
                    "license.import.success",
                    fallback: "License imported and purchases restored."
                )
            } catch {
                self?.purchaseMessage = L10n.text(
                    "license.import.failure",
                    fallback: "The license is invalid or could not be imported."
                )
            }
        }
    }

    func updateStorefrontTestScenario(_ scenario: StorefrontTestScenario) {
        storefrontTestScenario = scenario
#if DEBUG
        guard let mockPurchaseService else { return }
        Task { await mockPurchaseService.setScenario(scenario.mockScenario) }
#endif
    }

    func setShowTokenInMenuBar(_ enabled: Bool) {
        showTokenInMenuBar = enabled
        persistAppSettings()
    }

    func setShowTokenBreakdown(_ enabled: Bool) {
        showTokenBreakdown = enabled
        persistAppSettings()
    }

    func setAnimationQuality(_ quality: AnimationQuality) {
        animationQuality = quality
        persistAppSettings()
    }

    func setTrackingEnabled(_ enabled: Bool, providerID: ProviderID) {
        switch providerID {
        case .claudeCode: claudeTrackingEnabled = enabled
        case .codex: codexTrackingEnabled = enabled
        default: return
        }
        persistAppSettings(restartTracking: true)
    }

    var affectionMood: AffectionMood { AffectionEngine.mood(for: affectionPoints) }

    /// Takes in the XP that has gathered, once the Home tab is on screen. A
    /// short pause first lets the waiting amount register on the bar; then the
    /// bar sweeps, the roll shows, and any XP that landed meanwhile follows.
    func absorbGrowthIfNeeded() {
        guard let store, onboardingCompleted, !isResettingData, isPanelVisible, selectedSection == .home,
              pendingXP > 0, !isAbsorbing, !isEvolving, !isGraduating, !isHatchingEgg,
              hatchCeremony == nil, hatchDiscovery == nil else { return }
        isAbsorbing = true
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(650))
            guard let self else { return }
            let candyXP = economy?.items.first { $0.kind == .rareCandy }?.xpGrant ?? 60
            var didAbsorb = false
            if isPanelVisible, selectedSection == .home {
              do {
                let absorbed = try await store.absorbPendingXP(giftCandyXP: candyXP)
                let snapshot = await store.snapshot()
                let events = pendingCompanionEvents(in: snapshot)
                apply(snapshot)
                careMessage = nil
                didAbsorb = true
                lastAbsorption = absorbed
                absorptionCount += 1
                await deliverCompanionEvents(events)
                // Let the sweep finish before the next arrival starts one.
                try? await Task.sleep(for: .milliseconds(1_100))
              } catch {
                careMessage = L10n.text("growth.saveFailed", fallback: "Growth is still waiting. Reopen Home to try saving it again.")
              }
            }
            isAbsorbing = false
            if didAbsorb { absorbGrowthIfNeeded() }
        }
    }

    func petCompanion(onSuccess: (@MainActor () -> Void)? = nil) {
        guard let store, onboardingCompleted, !isPetting, !isResettingData else { return }
        isPetting = true
        Task { [weak self] in
            defer { self?.isPetting = false }
            do {
                try await store.petCurrentAnimal()
                guard let self else { return }
                let snapshot = await store.snapshot()
                let events = pendingCompanionEvents(in: snapshot)
                apply(snapshot)
                careMessage = nil
                onSuccess?()
                await deliverCompanionEvents(events)
            } catch GameShopStoreError.dailyLimitReached {
                self?.careMessage = L10n.text(
                    "care.pet.limit",
                    fallback: "That is enough affection for today. Try again tomorrow."
                )
            } catch {
                self?.careMessage = L10n.text("care.failed", fallback: "Could not reach your companion.")
            }
        }
    }

    func setRefreshIntervalMinutes(_ minutes: Int) {
        refreshIntervalMinutes = AppSettings.validatedRefreshInterval(minutes)
        persistAppSettings(restartTracking: true)
    }

    /// Moves one band boundary, keeping the three strictly ascending.
    func setUsageBandThreshold(index: Int, millions: Double) {
        var values = usageBandThresholds
        guard values.indices.contains(index) else { return }
        let value = Int64(millions * 1_000_000)
        let lower = index == 0 ? 0 : values[index - 1]
        let upper = index == values.count - 1 ? Int64.max : values[index + 1]
        guard value > lower, value < upper else { return }
        values[index] = value
        usageBandThresholds = AppSettings.validatedUsageBandThresholds(values)
        persistAppSettings()
    }

    func addLogPattern(_ pattern: String, providerID: ProviderID) {
        let trimmed = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try LogPathResolver.validate(pattern: trimmed)
            switch providerID {
            case .claudeCode:
                guard !claudeAdditionalLogPatterns.contains(trimmed) else { return }
                claudeAdditionalLogPatterns.append(trimmed)
            case .codex:
                guard !codexAdditionalLogPatterns.contains(trimmed) else { return }
                codexAdditionalLogPatterns.append(trimmed)
            default: return
            }
            settingsMessage = nil
            persistAppSettings(restartTracking: true)
        } catch {
            settingsMessage = L10n.text("error.path.invalid", fallback: "Use an absolute path or ~/ path. Wildcards cannot start at the filesystem root.")
        }
    }

    func chooseLogFolder(providerID: ProviderID) {
        guard !runtime.isSmokeTesting else { return }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = true
        panel.message = L10n.text("ui.tracking.folderHint", fallback: "Choose this provider's usage-log folder. EvoBar only keeps usage metadata.")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        addLogPattern(url.path, providerID: providerID)
        detectProviders()
    }

    var hasRecordedUsage: Bool {
        todayTokens > 0 || dailyRawTokens.contains { $0 > 0 }
            || animalInstances.contains { $0.cumulativeTokens > 0 }
    }

    var trackingNeedsAttention: Bool {
        trackingReports.contains(where: \.needsAttention)
    }

    func isTrackingEnabled(_ providerID: ProviderID) -> Bool {
        providerID == .claudeCode ? claudeTrackingEnabled : codexTrackingEnabled
    }

    func removeLogPattern(_ pattern: String, providerID: ProviderID) {
        switch providerID {
        case .claudeCode: claudeAdditionalLogPatterns.removeAll { $0 == pattern }
        case .codex: codexAdditionalLogPatterns.removeAll { $0 == pattern }
        default: return
        }
        persistAppSettings(restartTracking: true)
    }

    func setQuotaNotificationsEnabled(_ enabled: Bool) {
        guard !runtime.isSmokeTesting else { return }
        if !enabled {
            quotaNotificationsEnabled = false
            persistAppSettings()
            return
        }
        Task { [weak self] in
            guard let self else { return }
            let granted = await notificationService.requestAuthorization()
            quotaNotificationsEnabled = granted
            persistAppSettings()
            if !granted { settingsMessage = L10n.text("error.notification.denied", fallback: "Notification permission was not granted.") }
        }
    }

    func setCompanionNotificationsEnabled(_ enabled: Bool) {
        guard !runtime.isSmokeTesting else { return }
        if !enabled {
            companionNotificationsEnabled = false
            persistAppSettings()
            return
        }
        Task { [weak self] in
            guard let self else { return }
            let granted = await notificationService.requestAuthorization()
            companionNotificationsEnabled = granted
            persistAppSettings()
            if !granted { settingsMessage = L10n.text("error.notification.denied", fallback: "Notification permission was not granted.") }
        }
    }

    func setProviderStatusChecksEnabled(_ enabled: Bool) {
        providerStatusChecksEnabled = enabled
        if !enabled {
            providerStatusDashboard = nil
        }
        persistAppSettings()
        if enabled {
            Task { [weak self] in await self?.refreshProviderStatus(force: true) }
        }
    }

    func setAutomaticUpdateChecksEnabled(_ enabled: Bool) {
        automaticUpdateChecksEnabled = enabled
        persistAppSettings()
        if enabled, case .idle = appUpdateState {
            checkForUpdates()
        }
    }

    func checkForUpdates() {
        guard !runtime.isSmokeTesting else { return }
        guard !isCheckingForUpdates else { return }
        Task { [weak self] in await self?.performUpdateCheck() }
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        guard !runtime.isSmokeTesting else { return }
        do {
            try launchAtLoginController.setEnabled(enabled)
            launchAtLoginEnabled = launchAtLoginController.isEnabled
            settingsMessage = nil
            persistAppSettings()
        } catch {
            launchAtLoginEnabled = launchAtLoginController.isEnabled
            settingsMessage = L10n.text("error.loginItem", fallback: "Could not update Login Items. Install and open EvoBar.app, then try again.")
        }
    }

    func setDesktopPetEnabled(_ enabled: Bool) {
        desktopPetEnabled = enabled
        persistAppSettings()
    }

    func setDesktopPetSize(_ size: Double) {
        desktopPetSize = min(192, max(48, size))
        persistAppSettings()
    }

    func setPinnedAnimalDefinitionID(_ definitionID: AnimalDefinitionID?) {
        if let definitionID, !ownedAnimalIDs.contains(definitionID) || !illustratedAnimalIDs.contains(definitionID) { return }
        pinnedAnimalDefinitionID = definitionID
        persistAppSettings()
    }

    func setDesktopPetPosition(_ point: CGPoint) {
        desktopPetPosition = point
        persistAppSettings()
    }

    func exportLocalData() {
        guard let store else { return }
        Task { [weak self] in
            do {
                let data = try await store.exportData()
                guard let self else { return }
                let panel = NSSavePanel()
                panel.nameFieldStringValue = "EvoBar-Export-\(Date().formatted(.iso8601.year().month().day())) .json"
                    .replacingOccurrences(of: " ", with: "")
                panel.allowedContentTypes = [.json]
                panel.canCreateDirectories = true
                guard panel.runModal() == .OK, let url = panel.url else { return }
                try data.write(to: url, options: .atomic)
                settingsMessage = L10n.text("export.completed", fallback: "Exported aggregate data. Raw logs and session identifiers were excluded.")
            } catch {
                self?.settingsMessage = L10n.text("export.failed", fallback: "Data export failed.")
            }
        }
    }

    func refreshNow() {
        guard !runtime.isSmokeTesting else { return }
        guard onboardingCompleted, !isResettingData else { return }
        refreshWorker.request(force: true)
    }

    private func performTrackingRefresh(force: Bool) async {
        guard let store, let economy, onboardingCompleted, !isResettingData else { return }
        let generation = trackingGeneration
        isRefreshing = true
        defer { isRefreshing = false }
        let providers = enabledUsageProviders()
        let coordinator = UsageTrackingCoordinator(
            store: store,
            providers: providers,
            effectiveTokensPerCoin: economy.effectiveTokensPerCoin
        )
        do {
            let result = try await coordinator.scanOnce()
            try Task.checkCancellation()
            guard generation == trackingGeneration else { return }
            let events = pendingCompanionEvents(in: result.snapshot)
            apply(result.snapshot)
            let dashboard = await store.usageDashboard(pricing: pricing)
            try Task.checkCancellation()
            guard generation == trackingGeneration else { return }
            usageDashboard = dashboard
            trackingReports = result.reports
            lastTrackingCheck = Date()
            updateTrackingStatus()
            await deliverCompanionEvents(events)
            try Task.checkCancellation()
            // Internet services must not hold up reading local usage files.
            if serviceRefreshTask == nil {
                serviceRefreshTask = Task { [weak self] in
                    guard let self else { return }
                    await refreshQuota()
                    if !Task.isCancelled { await refreshProviderStatus(force: force) }
                    serviceRefreshTask = nil
                }
            }
        } catch is CancellationError {
            // A settings change or reset superseded this scan.
        } catch {
            guard generation == trackingGeneration else { return }
            trackingStatus = L10n.text("status.trackingUnavailable", fallback: "Tracking unavailable")
        }
    }

    private func updateTrackingStatus() {
        if trackingReports.isEmpty {
            trackingStatus = L10n.text("status.trackingPaused", fallback: "Tracking paused")
        } else if trackingReports.contains(where: \.needsAttention) {
            trackingStatus = L10n.text("ui.tracking.attention", fallback: "Tracking needs attention")
        } else if trackingReports.contains(where: \.isConnected) {
            trackingStatus = L10n.text("ui.tracking.connected", fallback: "Logs connected")
        } else {
            trackingStatus = L10n.text("ui.tracking.waiting", fallback: "Waiting for your first session")
        }
    }

    func stopTracking() {
        trackingTask?.cancel()
        trackingTask = nil
        trackingGeneration = UUID()
        refreshWorker.cancel()
        serviceRefreshTask?.cancel()
        logWatcher = nil
    }

    private func startTracking() {
        guard !runtime.isSmokeTesting else { return }
        guard trackingTask == nil, store != nil, economy != nil, onboardingCompleted, !isResettingData else { return }
        let generation = trackingGeneration
        logWatcher = refreshIntervalMinutes > 0
            ? LogChangeWatcher(roots: LogChangeWatcher.defaultRoots) { [weak self] in
                guard self?.trackingGeneration == generation else { return }
                self?.refreshWorker.request()
            }
            : nil
        trackingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, generation == trackingGeneration else { return }
                refreshWorker.request()
                guard refreshIntervalMinutes > 0 else { break }
                do { try await Task.sleep(for: .seconds(refreshIntervalMinutes * 60)) }
                catch { break }
            }
            if self?.trackingGeneration == generation { self?.trackingTask = nil }
        }
    }

    private func apply(_ snapshot: PersistedAppSnapshot) {
        onboardingCompleted = snapshot.onboardingCompleted
        companionName = snapshot.companionName
        currentAnimalID = snapshot.currentAnimalID
        currentXP = snapshot.currentXP
        // Retired companions remain in persistence/export, not in active collection targets.
        let availableIDs = Set(catalog?.animals.map(\.id) ?? [])
        animalInstances = snapshot.animalInstances.filter { availableIDs.contains($0.definitionID) }
        starterGrantID = snapshot.starterGrantID
        activeProductIDs = snapshot.activeProductIDs
        acknowledgedStageIndex = snapshot.currentAnimalInstanceID.flatMap { currentID in
            snapshot.animalInstances.first { $0.id == currentID }?.acknowledgedStageIndex
        } ?? 1
        tokenCoins = snapshot.tokenCoins
        itemInventory = snapshot.itemInventory
        todayTokens = snapshot.todayTokens
        todayXP = snapshot.todayXP
        dailyRawTokens = snapshot.dailyRawTokens
        weekRawTokens = snapshot.weekRawTokens
        pendingXP = snapshot.pendingXP
        affectionPoints = snapshot.affectionPoints
        careCount = snapshot.careCount
        petsRemainingToday = snapshot.petsRemainingToday
        treatsRemainingToday = snapshot.treatsRemainingToday
        busiestDays = snapshot.busiestDays
        incubator = snapshot.incubator
        usageBandThresholds = snapshot.appSettings.usageBandThresholds
        sceneThemeID = snapshot.appSettings.sceneThemeID
        claudeTrackingEnabled = snapshot.appSettings.claudeTrackingEnabled
        codexTrackingEnabled = snapshot.appSettings.codexTrackingEnabled
        refreshIntervalMinutes = snapshot.appSettings.refreshIntervalMinutes
        animationQuality = AnimationQuality(rawValue: snapshot.appSettings.animationQuality) ?? .balanced
        showTokenInMenuBar = snapshot.appSettings.showTokenInMenuBar
        showTokenBreakdown = snapshot.appSettings.showTokenBreakdown
        quotaNotificationsEnabled = snapshot.appSettings.quotaNotificationsEnabled
        companionNotificationsEnabled = snapshot.appSettings.companionNotificationsEnabled
        providerStatusChecksEnabled = snapshot.appSettings.providerStatusChecksEnabled
        automaticUpdateChecksEnabled = snapshot.appSettings.automaticUpdateChecksEnabled
        launchAtLoginEnabled = snapshot.appSettings.launchAtLoginEnabled
        claudeAdditionalLogPatterns = snapshot.appSettings.claudeAdditionalLogPatterns
        codexAdditionalLogPatterns = snapshot.appSettings.codexAdditionalLogPatterns
        desktopPetEnabled = snapshot.appSettings.desktopPetEnabled
        desktopPetSize = snapshot.appSettings.desktopPetSize
        pinnedAnimalDefinitionID = snapshot.appSettings.pinnedAnimalDefinitionID.map(AnimalDefinitionID.init(rawValue:))
        if let x = snapshot.appSettings.desktopPetX, let y = snapshot.appSettings.desktopPetY {
            desktopPetPosition = CGPoint(x: x, y: y)
        } else {
            desktopPetPosition = nil
        }
    }

    private func startNextCompanion(
        animal: AnimalDefinition,
        name: String,
        nature: NatureDefinition,
        isShiny: Bool,
        consumingItemID: String? = nil
    ) {
        guard let store, let currentAnimal, isGraduationReady, !isGraduating else { return }
        let finalStageIndex = currentAnimal.stages.count
        isGraduating = true
        graduationError = nil
        Task { [weak self] in
            do {
                try await store.graduateCurrentAndStart(
                    definitionID: animal.id,
                    name: String(name.prefix(24)),
                    natureID: nature.id,
                    rarity: animal.hatchProfile.rarity,
                    isShiny: isShiny,
                    finalStageIndex: finalStageIndex,
                    consumingItemID: consumingItemID
                )
                let snapshot = await store.snapshot()
                guard let self else { return }
                apply(snapshot)
                isGraduating = false
                // The graduation sheet closes itself when the individual changes,
                // and the hatch plays over the Home tab behind it.
                if let arrival = snapshot.animalInstances.first(where: \.isCurrent),
                   let definition = catalog?.animals.first(where: { $0.id == arrival.definitionID }) {
                    hatchCeremony = HatchCeremony(
                        to: animalAssetProvider.asset(
                            for: definition, stageIndex: 1, isShiny: arrival.isShiny, visualState: .idle),
                        companionName: arrival.name,
                        animalName: L10n.animal(definition),
                        rarity: arrival.rarity,
                        isShiny: arrival.isShiny,
                        themeColorHex: definition.themeColorHex
                    )
                    try? await Task.sleep(for: .seconds(HatchCeremonyView.total))
                    hatchCeremony = nil
                    absorbGrowthIfNeeded()
                }
            } catch {
                self?.isGraduating = false
                self?.graduationError = L10n.text("error.companion.next", fallback: "Could not start the next companion.")
            }
        }
    }

    private func configurePurchaseService(
        storefront: StorefrontManifest,
        snapshot: PersistedAppSnapshot
    ) {
#if DEBUG
        let service = MockPurchaseService(
            storefront: storefront,
            activeProductIDs: snapshot.activeProductIDs
        )
        mockPurchaseService = service
        purchaseService = service
#else
        guard let configuration = try? AppConfiguration.bundled(),
              configuration.distribution == "direct",
              configuration.storefront == "signed-license",
              let licenseConfiguration = configuration.signedLicense,
              let publicKeyData = licenseConfiguration.publicKeyData else {
            signedLicensePurchaseService = nil
            purchaseService = DisabledPurchaseService()
            return
        }
        let licenseURL = runtime.licenseURL ?? EvoBarStore.defaultStoreURL()
            .deletingLastPathComponent()
            .appendingPathComponent("license.v1.json")
        let service = SignedLicensePurchaseService(
            storefront: storefront,
            publicKeyData: publicKeyData,
            appBundleID: "com.evobar.app",
            licenseStore: FileLicenseStore(fileURL: licenseURL),
            checkoutBaseURL: licenseConfiguration.checkoutURL
        )
        signedLicensePurchaseService = service
        purchaseService = service
#endif
    }

    private func reconcileReleaseEntitlements() async {
#if DEBUG
        return
#else
        let verified: EntitlementSnapshot
        if let signedLicensePurchaseService {
            verified = (try? await signedLicensePurchaseService.currentEntitlements())
                ?? EntitlementSnapshot(activeProductIDs: [])
        } else {
            verified = EntitlementSnapshot(activeProductIDs: [])
        }
        do {
            try await persist(verified)
        } catch {
            activeProductIDs = []
        }
#endif
    }

    private func configureQuotaMonitor() {
#if DEBUG
        quotaMonitor = QuotaMonitor(services: [
            MockQuotaService(providerID: .claudeCode, fiveHourUtilization: 0.34, weeklyUtilization: 0.57),
            MockQuotaService(providerID: .codex, fiveHourUtilization: 0.46, weeklyUtilization: 0.68),
        ])
        quotaIsDemo = true
#else
        quotaMonitor = QuotaMonitor(services: [
            UnavailableQuotaService(providerID: .claudeCode),
            UnavailableQuotaService(providerID: .codex),
        ])
        quotaIsDemo = false
#endif
    }

    private func configureProviderStatusMonitor() {
        providerStatusMonitor = ProviderStatusMonitor(services: [
            StatuspageProviderStatusService(
                providerID: .claudeCode,
                endpoint: URL(string: "https://status.claude.com/api/v2/status.json")!,
                statusPageURL: URL(string: "https://status.claude.com/")!
            ),
            StatuspageProviderStatusService(
                providerID: .codex,
                endpoint: URL(string: "https://status.openai.com/api/v2/status.json")!,
                statusPageURL: URL(string: "https://status.openai.com/")!
            ),
        ])
    }

    private func refreshQuota() async {
        guard !runtime.isSmokeTesting else { return }
        guard let quotaMonitor else { return }
        let dashboard = await quotaMonitor.refresh()
        quotaDashboard = dashboard
        guard quotaNotificationsEnabled else { return }
        let alerts = quotaAlertEvaluator.newAlerts(for: dashboard)
        for alert in alerts {
            let provider = alert.providerID == .claudeCode ? "Claude" : "Codex"
            let percent = Int((alert.utilization * 100).rounded())
            await notificationService.deliver(
                identifier: alert.id,
                title: alert.level == .critical
                    ? L10n.format("notification.quota.critical", fallback: "%@ quota critical", provider)
                    : L10n.format("notification.quota.warning", fallback: "%@ quota warning", provider),
                body: L10n.format(
                    "notification.quota.body",
                    fallback: "%@ usage is at %d%%.",
                    alert.windowName,
                    percent
                )
            )
        }
    }

    private func refreshProviderStatus(force: Bool = false) async {
        guard !runtime.isSmokeTesting else { return }
        guard providerStatusChecksEnabled else {
            providerStatusDashboard = nil
            return
        }
        guard let providerStatusMonitor else { return }
        providerStatusDashboard = await providerStatusMonitor.refresh(force: force)
    }

    private func pendingCompanionEvents(in snapshot: PersistedAppSnapshot) -> [CompanionEvent] {
        guard companionNotificationsEnabled,
              let currentID = snapshot.currentAnimalInstanceID,
              let current = snapshot.animalInstances.first(where: { $0.id == currentID }),
              let definition = catalog?.animals.first(where: { $0.id == current.definitionID }) else {
            return []
        }
        return CompanionEventEngine.events(
            previous: currentAnimalInstance,
            current: current,
            definition: definition,
            previousCoins: tokenCoins,
            currentCoins: snapshot.tokenCoins
        )
    }

    private func deliverCompanionEvents(_ events: [CompanionEvent]) async {
        guard !runtime.isSmokeTesting else { return }
        for event in events {
            let message = Self.notificationMessage(for: event)
            await notificationService.deliver(
                identifier: event.id,
                title: message.title,
                body: message.body
            )
        }
    }

    static func notificationMessage(for event: CompanionEvent) -> (title: String, body: String) {
        switch event.kind {
        case .evolutionReady:
            return (
                L10n.text("notification.evolution.title", fallback: "Evolution ready!"),
                L10n.format(
                    "notification.evolution.body",
                    fallback: "%@ can evolve into %@.",
                    event.companionName,
                    event.targetStageName
                )
            )
        case .evolved:
            return (
                L10n.text("notification.evolved.title", fallback: "Evolved!"),
                L10n.format(
                    "notification.evolved.body",
                    fallback: "%@ is now %@.",
                    event.companionName,
                    event.targetStageName
                )
            )
        case .graduationReady:
            return (
                L10n.text("notification.graduation.title", fallback: "Final form reached"),
                L10n.format(
                    "notification.graduation.body",
                    fallback: "%@ reached its final form. Its story is in Collection.",
                    event.companionName
                )
            )
        case .hatched:
            return (
                L10n.text("notification.hatched.title", fallback: "A new companion"),
                L10n.format(
                    "notification.hatched.body",
                    fallback: "%@ the %@ joined you.",
                    event.companionName,
                    event.targetStageName
                )
            )
        case .shiny:
            return (
                L10n.text("notification.shiny.title", fallback: "Shiny!"),
                L10n.format(
                    "notification.shiny.body",
                    fallback: "%@ hatched as a shiny variant.",
                    event.companionName
                )
            )
        case .coinMilestone:
            return (
                L10n.text("notification.coins.title", fallback: "Token Coins"),
                L10n.format(
                    "notification.coins.body",
                    fallback: "You now hold %lld Token Coins.",
                    event.value
                )
            )
        case .moodChanged:
            switch AffectionMood(rawValue: event.targetStageName) {
            case .adoring:
                return (
                    L10n.text("notification.mood.adoring.title", fallback: "Completely attached"),
                    L10n.format(
                        "notification.mood.adoring.body",
                        fallback: "%@ adores you.",
                        event.companionName
                    )
                )
            case .sulking:
                return (
                    L10n.text("notification.mood.sulking.title", fallback: "Feeling forgotten"),
                    L10n.format(
                        "notification.mood.sulking.body",
                        fallback: "%@ has not been petted in a while.",
                        event.companionName
                    )
                )
            default:
                return (
                    L10n.text("notification.mood.distant.title", fallback: "A little distant"),
                    L10n.format(
                        "notification.mood.distant.body",
                        fallback: "%@ would like some attention.",
                        event.companionName
                    )
                )
            }
        }
    }

    private func performUpdateCheck() async {
        guard !runtime.isSmokeTesting else { return }
        guard !isCheckingForUpdates else { return }
        appUpdateState = .checking
        appUpdateState = await appUpdateService.check(currentVersion: installedVersion)
    }

    private func enabledUsageProviders() -> [any UsageProvider] {
        guard !runtime.isSmokeTesting else { return [] }
        var providers: [any UsageProvider] = []
        if claudeTrackingEnabled {
            providers.append(ClaudeCodeUsageProvider(additionalPatterns: claudeAdditionalLogPatterns))
        }
        if codexTrackingEnabled {
            providers.append(CodexUsageProvider(additionalPatterns: codexAdditionalLogPatterns))
        }
        return providers
    }

    private func persistAppSettings(restartTracking: Bool = false) {
        guard let store else { return }
        let settings = currentAppSettings()
        if restartTracking { stopTracking() }
        let generation = trackingGeneration
        Task { [weak self] in
            try? await store.updateAppSettings(settings)
            guard restartTracking, let self, generation == trackingGeneration else { return }
            startTracking()
        }
    }

    private func currentAppSettings() -> AppSettings {
        AppSettings(
            claudeTrackingEnabled: claudeTrackingEnabled,
            codexTrackingEnabled: codexTrackingEnabled,
            refreshIntervalMinutes: refreshIntervalMinutes,
            animationQuality: animationQuality.rawValue,
            showTokenInMenuBar: showTokenInMenuBar,
            showTokenBreakdown: showTokenBreakdown,
            quotaNotificationsEnabled: quotaNotificationsEnabled,
            companionNotificationsEnabled: companionNotificationsEnabled,
            providerStatusChecksEnabled: providerStatusChecksEnabled,
            automaticUpdateChecksEnabled: automaticUpdateChecksEnabled,
            launchAtLoginEnabled: launchAtLoginEnabled,
            claudeAdditionalLogPatterns: claudeAdditionalLogPatterns,
            codexAdditionalLogPatterns: codexAdditionalLogPatterns,
            desktopPetEnabled: desktopPetEnabled,
            desktopPetSize: desktopPetSize,
            pinnedAnimalDefinitionID: pinnedAnimalDefinitionID?.rawValue,
            desktopPetX: desktopPetPosition.map { Double($0.x) },
            desktopPetY: desktopPetPosition.map { Double($0.y) },
            usageBandThresholds: usageBandThresholds,
            sceneThemeID: sceneThemeID
        )
    }

    private func persist(_ entitlements: EntitlementSnapshot) async throws {
        guard let store else { return }
        let resolved = storefront.map {
            EntitlementResolver.resolve(
                starterGrant: validStarterGrantID,
                snapshot: entitlements,
                storefront: $0
            )
        }
        try await store.reconcileVerifiedOwnership(
            activeProductIDs: entitlements.activeProductIDs,
            ownedAnimalIDs: resolved?.ownedAnimalIDs ?? [],
            validStarterGrantID: validStarterGrantID
        )
        apply(await store.snapshot())
    }

    /// One compact token format for the whole app. Locale-aware compact
    /// notation prints 억 in a Korean popover and M in the menu bar for the
    /// same number, which reads as two different measurements.
    static func compactTokens(_ value: Int64) -> String {
        switch value {
        case 1_000_000_000...: String(format: "%.1fB", Double(value) / 1_000_000_000)
        case 1_000_000...: String(format: "%.1fM", Double(value) / 1_000_000)
        case 1_000...: String(format: "%.1fK", Double(value) / 1_000)
        default: String(value)
        }
    }

    private static func compactUSD(_ value: Decimal) -> String {
        let amount = NSDecimalNumber(decimal: value).doubleValue
        return amount < 0.01 ? String(format: "$%.3f", amount) : String(format: "$%.2f", amount)
    }
}

struct ProviderDetection: Identifiable, Equatable, Sendable {
    var id: ProviderID { providerID }
    let providerID: ProviderID
    let displayName: String
    let state: ProviderDetectionState
}

enum ProviderDetectionState: Equatable, Sendable {
    case checking
    case found(sourceCount: Int)
    case notFound
    case permissionRequired
    case failed

    init(_ status: DetectionStatus) {
        switch status {
        case .found(let sourceCount): self = .found(sourceCount: sourceCount)
        case .notFound: self = .notFound
        case .permissionRequired: self = .permissionRequired
        case .failed: self = .failed
        }
    }
}

enum AppSection: String, CaseIterable, Identifiable {
    case home = "Home"
    case usage = "Usage"
    case collection = "Collection"
    case shop = "Shop"
    case settings = "Settings"

    var id: String { rawValue }
    var displayName: String { L10n.text(rawValue) }
}

enum AnimationQuality: String, CaseIterable, Identifiable {
    case powerSaver
    case balanced
    case smooth

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .powerSaver: L10n.text("Power Saver")
        case .balanced: L10n.text("Balanced")
        case .smooth: L10n.text("Smooth")
        }
    }
}

enum StorefrontTestScenario: String, CaseIterable, Identifiable {
    case success = "Success"
    case cancelled = "Cancel"
    case failed = "Failure"
    case pending = "Pending"
    case offline = "Offline"

    var id: String { rawValue }
    var displayName: String { L10n.text(rawValue) }

#if DEBUG
    var mockScenario: MockPurchaseScenario {
        switch self {
        case .success: .success
        case .cancelled: .userCancelled
        case .failed: .failed(code: "test_failure")
        case .pending: .pending
        case .offline: .offline
        }
    }
#endif
}
