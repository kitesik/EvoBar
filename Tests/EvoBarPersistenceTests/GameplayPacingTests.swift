import EvoBarCore
import EvoBarPersistence
import EvoBarUsage
import Foundation
import Testing

/// A deterministic normal-economy walkthrough, not a forecast for real users.
/// Daily gifts use their minimum coins, with no bonus XP or gifted eggs.
@Suite struct GameplayPacingTests {
    @Test(arguments: [50_000, 250_000, 500_000, 1_000_000, 5_000_000, 20_000_000] as [Int64])
    func firstEvolutionAndPurchasedEggSurviveDailyRelaunch(tokens: Int64) async throws {
        let expectedEggDay: [Int64: Int] = [50_000: 6, 250_000: 3, 500_000: 2, 1_000_000: 1, 5_000_000: 1, 20_000_000: 1]
        let buyDay = try #require(expectedEggDay[tokens])
        let hatchDay = buyDay + 3
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EvoBarPacing-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("state.json")
        let start = Date(timeIntervalSince1970: 1_704_110_400)
        let catalog = try ManifestLoader.bundledCatalog()
        let animal = try #require(catalog.animals.first { $0.id == "cat" })
        let economy = try ManifestLoader.bundledEconomy()
        let item = try #require(economy.items.first { $0.kind == .randomEgg })
        var store = try EvoBarStore(fileURL: fileURL)
        let original = try await store.completeOnboarding(
            starterID: animal.id, companionName: "Pacing fixture", startedAt: start)
        var firstEvolutionDay: Int?
        var eggID: UUID?

        for day in 1...hatchDay {
            let now = start.addingTimeInterval(Double(day - 1) * 86_400 + 60)
            // The complete simulation must work across actual disk reloads.
            store = try EvoBarStore(fileURL: fileURL)
            let batch = ScanBatch(events: [UsageEvent(
                stableID: UsageEventID(rawValue: "pacing-day-\(day)"), provider: .claudeCode,
                sessionID: "synthetic-pacing", timestamp: now, modelID: "fixture-model",
                usage: TokenUsage(inputTokens: tokens, outputTokens: 0, totalTokens: tokens),
                sourceFingerprint: "synthetic-pacing")],
                checkpoint: SourceCheckpoint(byteOffset: UInt64(day), fileSize: UInt64(day)),
                malformedLineCount: 0)
            #expect(try await store.ingest(batch: batch, sourceKey: "synthetic-pacing",
                providerID: .claudeCode, effectiveTokensPerCoin: economy.effectiveTokensPerCoin) == 1)
            let absorption = try await store.absorbPendingXP(
                now: now, bonusRoll: 0.5, giftCoinRoll: 0, giftItemRoll: 0.5)
            #expect(absorption.bonus == 0)
            #expect(absorption.gift?.coins == 2)
            #expect(absorption.gift?.xp == 0 && absorption.gift?.eggs == 0)
            let grown = await store.snapshot(now: now)
            let current = try #require(grown.animalInstances.first { $0.isCurrent })
            // Reloading never silently advances an eligible animal or loses XP.
            let reopenedBeforeEvolution = try EvoBarStore(fileURL: fileURL)
            let restoredBeforeEvolution = await reopenedBeforeEvolution.snapshot(now: now)
            #expect(restoredBeforeEvolution.animalInstances == grown.animalInstances)
            for stage in animal.stages where stage.index > current.acknowledgedStageIndex
                && stage.xpThreshold <= current.currentXP {
                try await store.acknowledgeEvolution(
                    to: stage.index, finalStageIndex: animal.stages.count, evolvedAt: now)
                if firstEvolutionDay == nil { firstEvolutionDay = day }
            }
            if day < buyDay {
                #expect(grown.tokenCoins < item.tokenCoinPrice)
                await #expect(throws: GameShopStoreError.insufficientCoins) {
                    try await store.purchaseGameItem(item, chargeCoins: true)
                }
            } else if day == buyDay {
                try await store.purchaseGameItem(item, chargeCoins: true)
                #expect(await store.snapshot(now: now).tokenCoins == grown.tokenCoins - item.tokenCoinPrice)
                // Placement occurs AFTER today's usage: it earns no warmth yet.
                let placed = try await store.placeEggInIncubator(at: now.addingTimeInterval(1))
                eggID = placed.id
                #expect(placed.activeDays == 0)
            }
            let beforeReplay = await store.snapshot(now: now)
            #expect(try await store.ingest(batch: batch, sourceKey: "synthetic-pacing",
                providerID: .claudeCode, effectiveTokensPerCoin: economy.effectiveTokensPerCoin) == 0)
            let afterReplay = await store.snapshot(now: now)
            #expect(afterReplay.animalInstances == beforeReplay.animalInstances)
            #expect(afterReplay.tokenCoins == beforeReplay.tokenCoins)
            #expect(afterReplay.incubator == beforeReplay.incubator)
            if day >= buyDay {
                let egg = try #require(afterReplay.incubator.first)
                #expect(egg.activeDays == day - buyDay)
                #expect(egg.isReady == (day == hatchDay))
            }
        }
        // Very-light use reaches its first evolution on the third active day;
        // a first-day evolution is still not a universal promise.
        let expectedEvolutionDay: Int? = tokens == 50_000 ? 3 : 1
        #expect(firstEvolutionDay == expectedEvolutionDay)
        store = try EvoBarStore(fileURL: fileURL)
        let beforeHatch = await store.snapshot()
        let readyID = try #require(eggID)
        #expect(beforeHatch.incubator.first?.isReady == true)
        // A duplicate starter is an allowed outcome, requiring no paid grant.
        let arrival = try await store.hatchEgg(id: readyID, definitionID: animal.id,
            name: "Waiting fixture", natureID: "steady", rarity: .common, isShiny: false)
        let reopened = try EvoBarStore(fileURL: fileURL)
        let afterHatch = await reopened.snapshot()
        #expect(afterHatch.currentAnimalInstanceID == original.id)
        #expect(afterHatch.animalInstances.first { $0.id == original.id }
            == beforeHatch.animalInstances.first { $0.id == original.id })
        #expect(arrival.isWaitingToBeRaised && arrival.canBeRaisedNext)
        #expect(afterHatch.animalInstances.contains(arrival))
        #expect(afterHatch.animalInstances.count == 2 && afterHatch.incubator.isEmpty)
        print("Synthetic pacing: tokens=\(tokens), firstEvolution=\(firstEvolutionDay ?? 0), purchasedEgg=\(buyDay), readyAndOpened=\(hatchDay)")
    }
}
