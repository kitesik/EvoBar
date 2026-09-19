#if DEBUG
import EvoBarCore
import EvoBarPersistence
import EvoBarUsage
import Foundation

/// Tests the real model with a disposable ready egg, never presentation-only IDs.
@MainActor
enum HatchRecoveryReview {
    static func verify(renderFailure: (AppModel) async throws -> Void) async throws {
        try await verifyPlacementRecovery()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EvoBarHatchReview-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = AppRuntimeEnvironment(smokeTestOutputURL: directory.appendingPathComponent("report.json"))
        guard let url = runtime.storeURL else { throw Failure.fixtureUnavailable }
        let seed = try EvoBarStore(fileURL: url)
        let start = Date().addingTimeInterval(-4 * 86_400)
        let original = try await seed.completeOnboarding(
            starterID: "cat", companionName: "Fixture friend", startedAt: start)
        guard let item = try ManifestLoader.bundledEconomy().items.first(where: { $0.kind == .randomEgg })
        else { throw Failure.fixtureUnavailable }
        try await seed.purchaseGameItem(item, chargeCoins: false)
        let egg = try await seed.placeEggInIncubator(at: start)
        for day in 1...3 {
            let event = UsageEvent(
                stableID: UsageEventID(rawValue: "hatch-review-\(day)"), provider: .claudeCode,
                sessionID: "synthetic-session", timestamp: start.addingTimeInterval(Double(day) * 86_400),
                modelID: "fixture-model", usage: TokenUsage(inputTokens: 100_000, outputTokens: 0, totalTokens: 100_000),
                sourceFingerprint: "synthetic-hatch-review")
            _ = try await seed.ingest(
                batch: ScanBatch(events: [event],
                    checkpoint: SourceCheckpoint(byteOffset: UInt64(day), fileSize: UInt64(day)), malformedLineCount: 0),
                sourceKey: "synthetic-hatch-review", providerID: .claudeCode, effectiveTokensPerCoin: 100_000)
        }
        let model = AppModel(runtime: runtime)
        model.load()
        try await waitUntil { model.loadState != .loading }
        guard model.loadState == .ready, model.incubator.first?.isReady == true else {
            throw Failure.fixtureUnavailable
        }
        model.isPanelVisible = true
        model.selectedSection = .collection
        let before = model.animalInstances
        let eggs = model.incubator
        let saved = directory.appendingPathComponent("saved.json")
        try FileManager.default.moveItem(at: url, to: saved)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        model.openEgg(id: egg.id)
        guard model.isHatchingEgg else { throw Failure.didNotStart }
        try await waitUntil { !model.isHatchingEgg }
        guard model.hatchCeremony == nil, model.hatchDiscovery == nil,
              model.animalInstances == before, model.incubator == eggs,
              model.currentAnimalInstance?.id == original.id, model.canOpenEgg,
              model.incubatorMessage == L10n.text("incubator.openFailed", fallback: "Could not open the egg. Your egg is safe; try again.")
        else { throw Failure.failedSaveChangedPresentation }
        // Rendering Home must not absorb this fixture's pending growth.
        model.isPanelVisible = false
        try await renderFailure(model)
        model.isPanelVisible = true
        guard model.animalInstances == before, model.incubator == eggs else {
            throw Failure.failedSaveChangedPresentation
        }
        try FileManager.default.removeItem(at: url)
        try FileManager.default.moveItem(at: saved, to: url)

        model.openEgg(id: egg.id)
        model.openEgg(id: egg.id) // A second click cannot schedule another draw/save.
        try await waitUntil { model.hatchCeremony != nil }
        guard let arrival = model.hatchDiscovery, model.incubatorMessage == nil,
              model.animalInstances.count == before.count + 1,
              model.animalInstances.filter({ $0.id != arrival.id }) == before,
              model.currentAnimalInstance?.id == original.id, model.incubator.isEmpty,
              arrival.isWaitingToBeRaised, !model.canOpenEgg else { throw Failure.retryFailed }
        // The result must be durable before its ceremony can be acknowledged.
        let reopened = try EvoBarStore(fileURL: url)
        guard await reopened.snapshot().animalInstances == model.animalInstances else {
            throw Failure.resultNotDurable
        }
        model.acknowledgeHatch(viewCollection: true)
        guard model.hatchDiscovery?.id == arrival.id, model.selectedSection == .home else {
            throw Failure.acknowledgedDuringCeremony
        }
        try await waitUntil { !model.isHatchingEgg }
        guard model.hatchCeremony == nil, model.hatchDiscovery?.id == arrival.id else {
            throw Failure.discoveryLost
        }
        model.acknowledgeHatch(viewCollection: true)
        let committed = model.animalInstances
        guard model.hatchDiscovery == nil, model.selectedSection == .collection else {
            throw Failure.discoveryLost
        }
        model.openEgg(id: egg.id)
        guard !model.isHatchingEgg, model.animalInstances == committed,
              model.hatchCeremony == nil, model.hatchDiscovery == nil else { throw Failure.replayedEgg }
    }

    private static func verifyPlacementRecovery() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EvoBarPlacementReview-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = AppRuntimeEnvironment(smokeTestOutputURL: directory.appendingPathComponent("report.json"))
        guard let url = runtime.storeURL else { throw Failure.fixtureUnavailable }
        let seed = try EvoBarStore(fileURL: url)
        _ = try await seed.completeOnboarding(starterID: "cat", companionName: "Placement fixture")
        guard let item = try ManifestLoader.bundledEconomy().items.first(where: { $0.kind == .randomEgg })
        else { throw Failure.fixtureUnavailable }
        // Two eggs ensure a duplicate call would be observable, not masked by stock=0.
        try await seed.purchaseGameItem(item, chargeCoins: false)
        try await seed.purchaseGameItem(item, chargeCoins: false)
        let model = AppModel(runtime: runtime)
        model.load()
        try await waitUntil { model.loadState != .loading }
        guard model.loadState == .ready, model.randomEggCount == 2,
              model.incubator.isEmpty, !model.incubatorNeedsAttention else { throw Failure.fixtureUnavailable }
        let animals = model.animalInstances
        let saved = directory.appendingPathComponent("saved.json")
        try FileManager.default.moveItem(at: url, to: saved)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        model.placeEggInIncubator()
        guard model.isPlacingEgg else { throw Failure.didNotStart }
        try await waitUntil { !model.isPlacingEgg }
        guard model.canPlaceEgg, model.randomEggCount == 2, model.incubator.isEmpty,
              model.animalInstances == animals, model.incubatorNeedsAttention,
              model.incubatorMessage == L10n.text("incubator.failed", fallback: "The egg could not be placed.")
        else { throw Failure.placementRecoveryFailed }
        try FileManager.default.removeItem(at: url)
        try FileManager.default.moveItem(at: saved, to: url)
        model.placeEggInIncubator()
        model.placeEggInIncubator()
        try await waitUntil { !model.isPlacingEgg }
        guard model.randomEggCount == 1, model.incubator.count == 1,
              model.incubator.first?.isReady == false, model.incubatorMessage == nil,
              !model.incubatorNeedsAttention, model.animalInstances == animals,
              model.hatchCeremony == nil, model.hatchDiscovery == nil else { throw Failure.placementRecoveryFailed }
        let reopened = try EvoBarStore(fileURL: url)
        let snapshot = await reopened.snapshot()
        guard snapshot.incubator == model.incubator, snapshot.itemInventory["random-egg"] == 1,
              snapshot.animalInstances == animals else { throw Failure.resultNotDurable }
    }

    private static func waitUntil(_ predicate: () -> Bool) async throws {
        for _ in 0..<1_000 {
            if predicate() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        throw Failure.timedOut
    }

    private enum Failure: Error {
        case fixtureUnavailable, didNotStart, failedSaveChangedPresentation, retryFailed
        case resultNotDurable, acknowledgedDuringCeremony, discoveryLost, replayedEgg, timedOut
        case placementRecoveryFailed
    }
}
#endif
