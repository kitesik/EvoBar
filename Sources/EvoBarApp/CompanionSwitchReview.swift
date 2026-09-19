#if DEBUG
import EvoBarCore
import EvoBarPersistence
import EvoBarUsage
import Foundation

/// Exercises the real switch and success-only dismissal with a disposable save.
/// No log discovery, notifications, or user companion records participate.
@MainActor
enum CompanionSwitchReview {
    static func verify(
        renderFailure: (AppModel, AnimalDefinition) async throws -> Void
    ) async throws {
        do {
            try await verifyIsolated(renderFailure: renderFailure)
        } catch let failure as Failure {
            // Fixed test-case identifiers only; never print a save or raw error.
            FileHandle.standardError.write(Data("Switch review failed: \(failure).\n".utf8))
            throw failure
        }
    }

    private static func verifyIsolated(
        renderFailure: (AppModel, AnimalDefinition) async throws -> Void
    ) async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EvoBarSwitchReview-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = AppRuntimeEnvironment(smokeTestOutputURL: directory.appendingPathComponent("report.json"))
        guard let url = runtime.storeURL else { throw Failure.fixtureUnavailable }
        let seed = try EvoBarStore(fileURL: url)
        let start = Date().addingTimeInterval(-4 * 86_400)
        let original = try await seed.completeOnboarding(
            starterID: "cat", companionName: "Mochi", startedAt: start)
        guard let eggItem = try ManifestLoader.bundledEconomy().items.first(where: { $0.kind == .randomEgg })
        else { throw Failure.fixtureUnavailable }
        try await seed.purchaseGameItem(eggItem, chargeCoins: false)
        let egg = try await seed.placeEggInIncubator(at: start)
        for day in 1...3 {
            let event = UsageEvent(
                stableID: UsageEventID(rawValue: "switch-review-\(day)"), provider: .claudeCode,
                sessionID: "synthetic-session", timestamp: start.addingTimeInterval(Double(day) * 86_400),
                modelID: "fixture-model", usage: TokenUsage(inputTokens: 100_000, outputTokens: 0, totalTokens: 100_000),
                sourceFingerprint: "synthetic-switch-review")
            _ = try await seed.ingest(
                batch: ScanBatch(events: [event],
                    checkpoint: SourceCheckpoint(byteOffset: UInt64(day), fileSize: UInt64(day)), malformedLineCount: 0),
                sourceKey: "synthetic-switch-review", providerID: .claudeCode, effectiveTokensPerCoin: 100_000)
            if day == 1 {
                // A genuinely raised companion, with later arrivals still waiting.
                _ = try await seed.absorbPendingXP(
                    now: event.timestamp, bonusRoll: 0.5, giftCoinRoll: 0, giftItemRoll: 0.5)
            }
        }
        let waiting = try await seed.hatchEgg(
            id: egg.id, definitionID: "dog", name: "Waiting", natureID: "steady",
            rarity: .common, isShiny: true)
        let model = AppModel(runtime: runtime)
        model.load()
        try await waitUntil { model.loadState != .loading }
        guard model.loadState == .ready,
              let animal = model.catalog?.animals.first(where: { $0.id == waiting.definitionID })
        else { throw Failure.fixtureUnavailable }
        model.selectedSection = .collection
        let before = model.animalInstances
        var dismissalCount = 0
        var callbackSawSavedCompanion = false

        // Invalid names cannot dismiss the detail or change the individual.
        model.raiseCompanion(instanceID: waiting.id, name: " \n ") { dismissalCount += 1 }
        try await waitUntil { !model.isSwitchingCompanion }
        guard dismissalCount == 0, model.animalInstances == before,
              model.selectedSection == .collection,
              model.switchMessage == L10n.text("switch.needName", fallback: "Give them a name first.")
        else { throw Failure.failedSwitchDismissed }

        // Replace only this temporary save's destination with an empty directory.
        let saved = directory.appendingPathComponent("saved.json")
        try FileManager.default.moveItem(at: url, to: saved)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        model.raiseCompanion(instanceID: waiting.id, name: "Nova") { dismissalCount += 1 }
        try await waitUntil { !model.isSwitchingCompanion }
        guard dismissalCount == 0, model.animalInstances == before,
              model.currentAnimalInstance?.id == original.id, model.selectedSection == .collection,
              model.switchMessage == L10n.text("switch.failed", fallback: "That companion could not be raised.")
        else { throw Failure.failedSwitchDismissed }
        try await renderFailure(model, animal)
        model.switchMessage = nil
        guard model.animalInstances == before else { throw Failure.feedbackChangedCompanion }
        try FileManager.default.removeItem(at: url)
        try FileManager.default.moveItem(at: saved, to: url)

        // A retry dismisses once, after publishing the saved companion. A second
        // click while the first is in flight cannot enqueue another switch.
        model.raiseCompanion(instanceID: waiting.id, name: "  Nova  ") {
            dismissalCount += 1
            callbackSawSavedCompanion = model.currentAnimalInstance?.id == waiting.id
                && model.companionName == "Nova"
        }
        model.raiseCompanion(instanceID: waiting.id, name: "Duplicate") { dismissalCount += 1 }
        try await waitUntil { !model.isSwitchingCompanion }
        guard dismissalCount == 1, callbackSawSavedCompanion, model.switchMessage == nil,
              model.selectedSection == .home, model.animalInstances.filter(\.isCurrent).count == 1,
              let resting = model.animalInstances.first(where: { $0.id == original.id }),
              let prior = before.first(where: { $0.id == original.id }), resting.isResting,
              resting.pendingXP == prior.pendingXP, resting.cumulativeTokens == prior.cumulativeTokens
        else { throw Failure.retryFailed }
        let reopened = try EvoBarStore(fileURL: url)
        guard await reopened.snapshot().animalInstances == model.animalInstances else { throw Failure.retryNotDurable }

        // Resuming a resting companion uses the same success-only contract and
        // restores its saved name and waiting growth without creating a new one.
        model.selectedSection = .collection
        model.raiseCompanion(instanceID: original.id) { dismissalCount += 1 }
        try await waitUntil { !model.isSwitchingCompanion }
        guard dismissalCount == 2, model.currentAnimalInstance?.id == original.id,
              model.companionName == prior.name, model.pendingXP == prior.pendingXP,
              model.animalInstances.count == before.count, model.selectedSection == .home
        else { throw Failure.retryFailed }
    }

    private static func waitUntil(_ predicate: () -> Bool) async throws {
        for _ in 0..<500 {
            if predicate() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        throw Failure.timedOut
    }

    private enum Failure: Error {
        case fixtureUnavailable, failedSwitchDismissed, feedbackChangedCompanion
        case retryFailed, retryNotDurable, timedOut
    }
}
#endif
