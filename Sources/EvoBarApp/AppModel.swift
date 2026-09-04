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
    @Published private(set) var storefront: StorefrontManifest?
    @Published private(set) var economy: GameEconomyManifest?
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
    @Published var selectedSection: AppSection = .home
    @Published var companionName = "Mochi"
    @Published var currentAnimalID: AnimalDefinitionID = "cat"
    @Published var currentXP: Int64 = 0
    @Published var acknowledgedStageIndex = 1
    @Published var todayTokens: Int64 = 0
    @Published var todayXP: Int64 = 0
    @Published var tokenCoins: Int64 = 0
    @Published private(set) var itemInventory: [String: Int] = [:]
    @Published var animationQuality: AnimationQuality = .powerSaver
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

    var currentAnimal: AnimalDefinition? {
        catalog?.animals.first { $0.id == currentAnimalID }
    }

    var currentAnimalInstance: AnimalInstance? {
        animalInstances.first(where: \.isCurrent)
    }

    var desktopPetInstance: AnimalInstance? {
        guard let pinnedAnimalDefinitionID else { return currentAnimalInstance }
        return animalInstances
            .filter { $0.definitionID == pinnedAnimalDefinitionID }
            .sorted {
                if $0.acknowledgedStageIndex != $1.acknowledgedStageIndex {
                    return $0.acknowledgedStageIndex > $1.acknowledgedStageIndex
                }
                return $0.createdAt > $1.createdAt
            }
            .first
    }

    var desktopPetAnimal: AnimalDefinition? {
        guard let definitionID = desktopPetInstance?.definitionID else { return currentAnimal }
        return catalog?.animals.first { $0.id == definitionID }
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
        guard let storefront else { return starterGrantID.map { [$0] } ?? [] }
        return EntitlementResolver.resolve(
            starterGrant: starterGrantID,
            snapshot: EntitlementSnapshot(activeProductIDs: activeProductIDs),
            storefront: storefront
        ).ownedAnimalIDs
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
    var randomEggCount: Int { itemInventory["random-egg"] ?? 0 }

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
        guard showTokenInMenuBar else { return companion }
        var metrics = [Self.compact(todayTokens)]
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
        return "\(companion) \(metrics.joined(separator: " · "))"
    }

    func load() {
        do {
            let catalog = try ManifestLoader.bundledCatalog()
            let storefront = try ManifestLoader.bundledStorefront()
            let economy = try ManifestLoader.bundledEconomy()
            let pricing = try ManifestLoader.bundledPricing()
            try ManifestLoader.validate(catalog: catalog, storefront: storefront, economy: economy)
            try ManifestLoader.validate(pricing: pricing)
            self.catalog = catalog
            self.storefront = storefront
            self.economy = economy
            self.pricing = pricing
            let store = try EvoBarStore()
            self.store = store
            Task { [weak self] in
                let snapshot = await store.snapshot()
                guard let self else { return }
                apply(snapshot)
                launchAtLoginEnabled = launchAtLoginController.isEnabled
                try? await store.updateAppSettings(currentAppSettings())
                usageDashboard = await store.usageDashboard(pricing: pricing)
                configurePurchaseService(storefront: storefront, snapshot: snapshot)
                await reconcileReleaseEntitlements()
                configureQuotaMonitor()
                configureProviderStatusMonitor()
                loadState = .ready
                if snapshot.onboardingCompleted {
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
        guard !isDetectingProviders else { return }
        isDetectingProviders = true
        providerDetections = [
            ProviderDetection(providerID: .claudeCode, displayName: "Claude Code", state: .checking),
            ProviderDetection(providerID: .codex, displayName: "Codex", state: .checking),
        ]
        Task { [weak self] in
            async let claudeStatus = ClaudeCodeUsageProvider().detectionStatus()
            async let codexStatus = CodexUsageProvider().detectionStatus()
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
        guard let store, let currentAnimal, isEvolutionReady, !isEvolving else { return }
        let targetStageIndex = acknowledgedStageIndex + 1
        let finalStageIndex = currentAnimal.stages.count
        isEvolving = true
        Task { [weak self] in
            do {
                try await store.acknowledgeEvolution(
                    to: targetStageIndex,
                    finalStageIndex: finalStageIndex
                )
                let snapshot = await store.snapshot()
                guard let self else { return }
                apply(snapshot)
                isEvolving = false
            } catch {
                self?.isEvolving = false
            }
        }
    }

    func resetLocalData() {
        guard let store, !isResettingData else { return }
        isResettingData = true
        stopTracking()
        Task { [weak self] in
            do {
                try await store.resetAllData()
                let snapshot = await store.snapshot()
                guard let self else { return }
                apply(snapshot)
                usageDashboard = await store.usageDashboard(pricing: pricing)
                trackingStatus = L10n.text("status.notConnected", fallback: "Not connected")
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

    func purchase(_ productID: ProductID) {
        guard let purchaseService, purchasesAvailable, purchasingProductID == nil else { return }
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

    func purchaseGameItem(_ item: GameItemDefinition) {
        guard let store, purchasingItemID == nil else { return }
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
        Task { [weak self] in
            do {
                try await store.purchaseGameItem(item, replacementNatureID: replacementNatureID)
                guard let self else { return }
                apply(await store.snapshot())
                switch item.kind {
                case .rareCandy:
                    itemPurchaseMessage = L10n.format("item.candy.applied", fallback: "+%lld XP applied.", item.xpGrant ?? 0)
                case .mint: itemPurchaseMessage = L10n.text("item.mint.applied", fallback: "Nature rerolled.")
                case .shinyCharm: itemPurchaseMessage = L10n.text("item.charm.applied", fallback: "Shiny Charm will affect future hatches.")
                case .randomEgg: itemPurchaseMessage = L10n.text("item.egg.applied", fallback: "Random Egg added. Use it after final evolution.")
                }
            } catch GameShopStoreError.insufficientCoins {
                self?.itemPurchaseMessage = L10n.text("item.insufficientCoins", fallback: "Not enough Token Coins.")
            } catch GameShopStoreError.alreadyOwned {
                self?.itemPurchaseMessage = L10n.text("item.alreadyOwned", fallback: "You already own this item.")
            } catch {
                self?.itemPurchaseMessage = L10n.text("item.applyFailed", fallback: "Item could not be applied.")
            }
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

    func setRefreshIntervalMinutes(_ minutes: Int) {
        refreshIntervalMinutes = AppSettings.validatedRefreshInterval(minutes)
        persistAppSettings(restartTracking: true)
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

    func removeLogPattern(_ pattern: String, providerID: ProviderID) {
        switch providerID {
        case .claudeCode: claudeAdditionalLogPatterns.removeAll { $0 == pattern }
        case .codex: codexAdditionalLogPatterns.removeAll { $0 == pattern }
        default: return
        }
        persistAppSettings(restartTracking: true)
    }

    func setQuotaNotificationsEnabled(_ enabled: Bool) {
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
        guard !isCheckingForUpdates else { return }
        Task { [weak self] in await self?.performUpdateCheck() }
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
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
        if let definitionID, !ownedAnimalIDs.contains(definitionID) { return }
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
        guard !isRefreshing, let store, let economy, onboardingCompleted else { return }
        isRefreshing = true
        let providers = enabledUsageProviders()
        let coordinator = UsageTrackingCoordinator(
            store: store,
            providers: providers,
            effectiveTokensPerCoin: economy.effectiveTokensPerCoin
        )
        Task { [weak self] in
            do {
                let snapshot = try await coordinator.scanOnce()
                guard let self else { return }
                let events = pendingCompanionEvents(in: snapshot)
                apply(snapshot)
                usageDashboard = await store.usageDashboard(pricing: pricing)
                await refreshQuota()
                await refreshProviderStatus(force: true)
                await deliverCompanionEvents(events)
                trackingStatus = providers.isEmpty
                    ? L10n.text("status.trackingPaused", fallback: "Tracking paused")
                    : L10n.text("status.tracking", fallback: "Tracking")
            } catch {
                self?.trackingStatus = L10n.text("status.trackingUnavailable", fallback: "Tracking unavailable")
            }
            self?.isRefreshing = false
        }
    }

    func stopTracking() {
        trackingTask?.cancel()
        trackingTask = nil
    }

    private func startTracking() {
        guard trackingTask == nil, let store, let economy, onboardingCompleted else { return }
        let providers = enabledUsageProviders()
        let coordinator = UsageTrackingCoordinator(
            store: store,
            providers: providers,
            effectiveTokensPerCoin: economy.effectiveTokensPerCoin
        )
        trackingTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    let snapshot = try await coordinator.scanOnce()
                    guard let self else { return }
                    let events = pendingCompanionEvents(in: snapshot)
                    apply(snapshot)
                    usageDashboard = await store.usageDashboard(pricing: pricing)
                    await refreshQuota()
                    await refreshProviderStatus()
                    await deliverCompanionEvents(events)
                    trackingStatus = providers.isEmpty
                        ? L10n.text("status.trackingPaused", fallback: "Tracking paused")
                        : L10n.text("status.tracking", fallback: "Tracking")
                } catch {
                    self?.trackingStatus = L10n.text("status.trackingUnavailable", fallback: "Tracking unavailable")
                }
                guard let self, refreshIntervalMinutes > 0 else { break }
                try? await Task.sleep(for: .seconds(refreshIntervalMinutes * 60))
            }
            self?.trackingTask = nil
        }
    }

    private func apply(_ snapshot: PersistedAppSnapshot) {
        onboardingCompleted = snapshot.onboardingCompleted
        companionName = snapshot.companionName
        currentAnimalID = snapshot.currentAnimalID
        currentXP = snapshot.currentXP
        animalInstances = snapshot.animalInstances
        starterGrantID = snapshot.starterGrantID
        activeProductIDs = snapshot.activeProductIDs
        acknowledgedStageIndex = snapshot.currentAnimalInstanceID.flatMap { currentID in
            snapshot.animalInstances.first { $0.id == currentID }?.acknowledgedStageIndex
        } ?? 1
        tokenCoins = snapshot.tokenCoins
        itemInventory = snapshot.itemInventory
        todayTokens = snapshot.todayTokens
        todayXP = snapshot.todayXP
        claudeTrackingEnabled = snapshot.appSettings.claudeTrackingEnabled
        codexTrackingEnabled = snapshot.appSettings.codexTrackingEnabled
        refreshIntervalMinutes = snapshot.appSettings.refreshIntervalMinutes
        animationQuality = AnimationQuality(rawValue: snapshot.appSettings.animationQuality) ?? .powerSaver
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
        let licenseURL = EvoBarStore.defaultStoreURL()
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
        guard let store else { return }
        let verified: EntitlementSnapshot
        if let signedLicensePurchaseService {
            verified = (try? await signedLicensePurchaseService.currentEntitlements())
                ?? EntitlementSnapshot(activeProductIDs: [])
        } else {
            verified = EntitlementSnapshot(activeProductIDs: [])
        }
        do {
            try await store.updateActiveProductIDs(verified.activeProductIDs)
            apply(await store.snapshot())
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
            definition: definition
        )
    }

    private func deliverCompanionEvents(_ events: [CompanionEvent]) async {
        for event in events {
            await notificationService.deliver(
                identifier: event.id,
                title: L10n.text("notification.evolution.title", fallback: "Evolution ready!"),
                body: L10n.format(
                    "notification.evolution.body",
                    fallback: "%@ can evolve into %@.",
                    event.companionName,
                    event.targetStageName
                )
            )
        }
    }

    private func performUpdateCheck() async {
        guard !isCheckingForUpdates else { return }
        appUpdateState = .checking
        appUpdateState = await appUpdateService.check(currentVersion: installedVersion)
    }

    private func enabledUsageProviders() -> [any UsageProvider] {
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
        Task { [weak self] in
            try? await store.updateAppSettings(settings)
            guard restartTracking, let self else { return }
            stopTracking()
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
            desktopPetY: desktopPetPosition.map { Double($0.y) }
        )
    }

    private func persist(_ entitlements: EntitlementSnapshot) async throws {
        guard let store else { return }
        try await store.updateActiveProductIDs(entitlements.activeProductIDs)
        apply(await store.snapshot())
    }

    private static func compact(_ value: Int64) -> String {
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
