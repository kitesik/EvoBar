import EvoBarCore
import EvoBarEvolution
import EvoBarPersistence
import EvoBarUsage
import Foundation
import Testing

@Suite struct EvoBarStoreTests {
    @Test func duplicateEventIsNotCountedOrRewardedTwice() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        let timestamp = Date()
        let event = usageEvent(id: "event-1", timestamp: timestamp, tokens: 1_000_000)
        let batch = ScanBatch(
            events: [event],
            checkpoint: SourceCheckpoint(byteOffset: 100, fileSize: 100),
            malformedLineCount: 0
        )

        let firstInsert = try await store.ingest(
            batch: batch,
            sourceKey: "source",
            providerID: .claudeCode,
            effectiveTokensPerCoin: 100_000
        )
        let first = await store.snapshot(now: timestamp)
        let duplicateInsert = try await store.ingest(
            batch: batch,
            sourceKey: "source",
            providerID: .claudeCode,
            effectiveTokensPerCoin: 100_000
        )
        let second = await store.snapshot(now: timestamp)

        #expect(firstInsert == 1)
        #expect(duplicateInsert == 0)
        #expect(first.todayTokens == 1_000_000)
        #expect(first.todayXP == 100)
        #expect(first.pendingXP == 100)
        #expect(first.currentXP == 0)
        #expect(first.tokenCoins == 10)
        #expect(second.todayTokens == first.todayTokens)
        #expect(second.pendingXP == first.pendingXP)
        #expect(second.tokenCoins == first.tokenCoins)
    }

    @Test func persistedStateAndCheckpointSurviveRelaunch() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EvoBarStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("state.json")
        let timestamp = Date()

        let firstStore = try EvoBarStore(fileURL: fileURL)
        try await onboard(firstStore)
        let event = usageEvent(id: "event-relaunch", timestamp: timestamp, tokens: 2_000_000)
        let expectedCheckpoint = SourceCheckpoint(
            byteOffset: 321,
            fileSize: 321,
            generation: 2,
            sessionID: "session"
        )
        _ = try await firstStore.ingest(
            batch: ScanBatch(
                events: [event],
                checkpoint: expectedCheckpoint,
                malformedLineCount: 0
            ),
            sourceKey: "source-relaunch",
            providerID: .codex,
            effectiveTokensPerCoin: 100_000
        )
        let before = await firstStore.snapshot(now: timestamp)

        let relaunchedStore = try EvoBarStore(fileURL: fileURL)
        let after = await relaunchedStore.snapshot(now: timestamp)
        let checkpoint = await relaunchedStore.checkpoint(for: "source-relaunch")

        #expect(after.todayTokens == before.todayTokens)
        #expect(after.currentXP == before.currentXP)
        #expect(after.tokenCoins == before.tokenCoins)
        #expect(checkpoint == expectedCheckpoint)
    }

    @Test func persistedStateUsesOwnerOnlyFilesystemPermissions() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EvoBarPermissionTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("state.json")
        let store = try EvoBarStore(fileURL: fileURL)
        try await onboard(store)

        let directoryAttributes = try FileManager.default.attributesOfItem(atPath: directory.path)
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let directoryMode = try #require(directoryAttributes[.posixPermissions] as? NSNumber)
        let fileMode = try #require(fileAttributes[.posixPermissions] as? NSNumber)

        #expect(directoryMode.intValue & 0o777 == 0o700)
        #expect(fileMode.intValue & 0o777 == 0o600)

        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o644))],
            ofItemAtPath: fileURL.path
        )
        _ = try EvoBarStore(fileURL: fileURL)
        let repairedAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let repairedMode = try #require(repairedAttributes[.posixPermissions] as? NSNumber)
        #expect(repairedMode.intValue & 0o777 == 0o600)
    }

    @Test func corruptedPrimaryRecoversFromLastValidOwnerOnlyBackup() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EvoBarRecoveryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("state.json")
        let backupURL = fileURL.appendingPathExtension("backup")
        let timestamp = Date()
        let store = try EvoBarStore(fileURL: fileURL)
        try await onboard(store)
        _ = try await store.ingest(
            batch: ScanBatch(
                events: [usageEvent(id: "recoverable", timestamp: timestamp, tokens: 500_000)],
                checkpoint: SourceCheckpoint(byteOffset: 50, fileSize: 50),
                malformedLineCount: 0
            ),
            sourceKey: "recovery-source",
            providerID: .claudeCode,
            effectiveTokensPerCoin: 100_000
        )
        try await store.updateAppSettings(AppSettings(animationQuality: "balanced"))
        let before = await store.snapshot(now: timestamp)

        try Data("not-json".utf8).write(to: fileURL, options: .atomic)
        let recoveredStore = try EvoBarStore(fileURL: fileURL)
        let recovered = await recoveredStore.snapshot(now: timestamp)
        let repairedData = try Data(contentsOf: fileURL)
        let backupData = try Data(contentsOf: backupURL)
        let backupAttributes = try FileManager.default.attributesOfItem(atPath: backupURL.path)
        let backupMode = try #require(backupAttributes[.posixPermissions] as? NSNumber)

        #expect(recovered.onboardingCompleted)
        #expect(recovered.todayTokens == before.todayTokens)
        #expect(recovered.currentXP == before.currentXP)
        #expect(repairedData == backupData)
        #expect(backupMode.intValue & 0o777 == 0o600)
    }

    @Test func resetReplacesBackupSoOldDataCannotBeRestored() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EvoBarResetRecoveryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("state.json")
        let store = try EvoBarStore(fileURL: fileURL)
        try await onboard(store)
        try await store.updateAppSettings(AppSettings(animationQuality: "smooth"))
        try await store.resetAllData()

        try Data("corrupted-after-reset".utf8).write(to: fileURL, options: .atomic)
        let recoveredStore = try EvoBarStore(fileURL: fileURL)
        let recovered = await recoveredStore.snapshot()

        #expect(!recovered.onboardingCompleted)
        #expect(recovered.animalInstances.isEmpty)
        #expect(recovered.todayTokens == 0)
        #expect(recovered.currentXP == 0)
    }

    @Test func growthDayBoundaryKeepsDailyAwardsIndependent() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let today = calendar.startOfDay(for: Date())
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: today))
        let yesterdayEvent = usageEvent(
            id: "yesterday",
            timestamp: yesterday.addingTimeInterval(86_399),
            tokens: 1_000_000
        )
        let todayEvent = usageEvent(
            id: "today",
            timestamp: today,
            tokens: 1_000_000
        )
        _ = try await store.ingest(
            batch: ScanBatch(
                events: [yesterdayEvent, todayEvent],
                checkpoint: SourceCheckpoint(byteOffset: 200, fileSize: 200),
                malformedLineCount: 0
            ),
            sourceKey: "day-boundary",
            providerID: .claudeCode,
            effectiveTokensPerCoin: 100_000
        )

        let yesterdaySnapshot = await store.snapshot(now: yesterday.addingTimeInterval(86_399))
        let todaySnapshot = await store.snapshot(now: today)
        #expect(yesterdaySnapshot.todayTokens == 1_000_000)
        #expect(todaySnapshot.todayTokens == 1_000_000)
        #expect(yesterdaySnapshot.todayXP == 100)
        #expect(todaySnapshot.todayXP == 100)
        #expect(todaySnapshot.pendingXP == 200)
        #expect(todaySnapshot.tokenCoins == 20)
    }

    @Test func onboardingCreatesExactlyOneTrimmedStarter() async throws {
        let store = try EvoBarStore(fileURL: nil)
        let fresh = await store.snapshot()
        #expect(!fresh.onboardingCompleted)
        #expect(fresh.animalInstances.isEmpty)

        await #expect(throws: OnboardingStoreError.emptyName) {
            try await store.completeOnboarding(starterID: "cat", companionName: "   ")
        }
        let created = try await store.completeOnboarding(
            starterID: "dog",
            companionName: "  Nova  ",
            startedAt: Date(timeIntervalSinceReferenceDate: 100)
        )
        let completed = await store.snapshot()

        #expect(created.name == "Nova")
        #expect(created.definitionID == "dog")
        #expect(completed.onboardingCompleted)
        #expect(completed.currentAnimalInstanceID == created.id)
        #expect(completed.animalInstances.count == 1)
        await #expect(throws: OnboardingStoreError.alreadyCompleted) {
            try await store.completeOnboarding(starterID: "cat", companionName: "Second")
        }
    }

    @Test func versionOneStateMigratesWithoutLosingCompanionUsage() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EvoBarMigrationTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("state.json")
        let legacyDate = Date(timeIntervalSinceReferenceDate: 100)
        let legacyState: [String: Any] = [
            "schemaVersion": 1,
            "events": [
                "legacy-event": [
                    "providerID": "claude-code",
                    "sessionID": "legacy-session",
                    "timestamp": legacyDate.timeIntervalSinceReferenceDate,
                    "modelID": "legacy-model",
                    "usage": [
                        "inputTokens": 1_000,
                        "outputTokens": 0,
                        "cacheReadTokens": 0,
                        "cacheWriteTokens": 0,
                        "reasoningTokens": 0,
                        "totalTokens": 1_000,
                    ],
                    "sourceFingerprint": "legacy-source",
                    "dayKey": "UTC|2001-01-01",
                ],
            ],
            "dailyAggregates": [:],
            "checkpoints": [:],
            "settings": [
                "companionName": "Legacy",
                "currentAnimalID": "cat",
                "currentXP": 42,
                "tokenCoins": 7,
                "growthTimeZoneID": "UTC",
                "trackingStartedAt": legacyDate.timeIntervalSinceReferenceDate,
                "claudeTrackingEnabled": true,
                "codexTrackingEnabled": true,
            ],
        ]
        try JSONSerialization.data(withJSONObject: legacyState, options: [.sortedKeys])
            .write(to: fileURL)

        let migratedStore = try EvoBarStore(fileURL: fileURL)
        let snapshot = await migratedStore.snapshot()
        let instance = try #require(snapshot.animalInstances.first)

        #expect(snapshot.onboardingCompleted)
        #expect(snapshot.companionName == "Legacy")
        #expect(snapshot.starterGrantID == "cat")
        #expect(snapshot.currentXP == 42)
        #expect(snapshot.tokenCoins == 7)
        #expect(instance.cumulativeTokens == 1_000)
        #expect(instance.providerTokens[.claudeCode] == 1_000)
        #expect(instance.lastActivityAt == legacyDate)
    }

    @Test func evolutionAcknowledgementIsOrderedAndPersistsFinalDate() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        await #expect(throws: EvolutionStoreError.invalidStage) {
            try await store.acknowledgeEvolution(to: 3, finalStageIndex: 5)
        }

        try await store.acknowledgeEvolution(to: 2, finalStageIndex: 5)
        try await store.acknowledgeEvolution(to: 3, finalStageIndex: 5)
        try await store.acknowledgeEvolution(to: 4, finalStageIndex: 5)
        let evolvedAt = Date(timeIntervalSinceReferenceDate: 500)
        try await store.acknowledgeEvolution(
            to: 5,
            finalStageIndex: 5,
            evolvedAt: evolvedAt
        )
        let instance = try #require(await store.snapshot().animalInstances.first)

        #expect(instance.acknowledgedStageIndex == 5)
        #expect(instance.finalEvolutionAt == evolvedAt)
        await #expect(throws: EvolutionStoreError.invalidStage) {
            try await store.acknowledgeEvolution(to: 6, finalStageIndex: 5)
        }
    }

    @Test func resetReturnsStoreToFreshInstallState() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        let event = usageEvent(id: "before-reset", timestamp: Date(), tokens: 1_000_000)
        _ = try await store.ingest(
            batch: ScanBatch(
                events: [event],
                checkpoint: SourceCheckpoint(byteOffset: 100, fileSize: 100),
                malformedLineCount: 0
            ),
            sourceKey: "reset-source",
            providerID: .claudeCode,
            effectiveTokensPerCoin: 100_000
        )

        try await store.resetAllData()
        let reset = await store.snapshot()

        #expect(!reset.onboardingCompleted)
        #expect(reset.animalInstances.isEmpty)
        #expect(reset.currentXP == 0)
        #expect(reset.todayTokens == 0)
        #expect(reset.tokenCoins == 0)
        #expect(await store.checkpoint(for: "reset-source") == nil)
    }

    @Test func graduationPreservesOldRecordAndCreditsOnlyNewGrowthToNextCompanion() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        let midday = Calendar.current.startOfDay(for: Date()).addingTimeInterval(43_200)
        let firstEvent = usageEvent(id: "first-life", timestamp: midday, tokens: 1_000_000)
        _ = try await store.ingest(
            batch: ScanBatch(
                events: [firstEvent],
                checkpoint: SourceCheckpoint(byteOffset: 100, fileSize: 100),
                malformedLineCount: 0
            ),
            sourceKey: "graduation-source",
            providerID: .claudeCode,
            effectiveTokensPerCoin: 100_000
        )
        let firstID = try #require(await store.snapshot(now: midday).currentAnimalInstanceID)

        await #expect(throws: GraduationStoreError.currentAnimalNotFinal) {
            try await store.graduateCurrentAndStart(
                definitionID: "dog",
                name: "Nova",
                natureID: "steady",
                rarity: .common,
                isShiny: false,
                finalStageIndex: 5
            )
        }
        for stage in 2...5 {
            try await store.acknowledgeEvolution(to: stage, finalStageIndex: 5)
        }
        let graduationDate = midday.addingTimeInterval(1)
        let next = try await store.graduateCurrentAndStart(
            definitionID: "dog",
            name: " Nova ",
            natureID: "steady",
            rarity: .common,
            isShiny: false,
            finalStageIndex: 5,
            at: graduationDate
        )

        let secondEvent = UsageEvent(
            stableID: UsageEventID(rawValue: "second-life"),
            provider: .codex,
            sessionID: "session-2",
            timestamp: midday.addingTimeInterval(2),
            modelID: "fixture-model",
            usage: TokenUsage(inputTokens: 1_000_000, outputTokens: 0, totalTokens: 1_000_000),
            sourceFingerprint: "fixture-source-2"
        )
        _ = try await store.ingest(
            batch: ScanBatch(
                events: [secondEvent],
                checkpoint: SourceCheckpoint(byteOffset: 200, fileSize: 200),
                malformedLineCount: 0
            ),
            sourceKey: "graduation-source",
            providerID: .codex,
            effectiveTokensPerCoin: 100_000
        )
        let snapshot = await store.snapshot(now: midday.addingTimeInterval(2))
        let graduated = try #require(snapshot.animalInstances.first { $0.id == firstID })
        let current = try #require(snapshot.animalInstances.first { $0.id == next.id })

        #expect(!graduated.isCurrent)
        #expect(graduated.graduatedAt == graduationDate)
        #expect(graduated.pendingXP == 100)
        #expect(graduated.cumulativeTokens == 1_000_000)
        #expect(current.isCurrent)
        #expect(current.name == "Nova")
        #expect(current.definitionID == "dog")
        #expect(current.pendingXP == 50)
        #expect(current.cumulativeTokens == 1_000_000)
        #expect(current.providerTokens[.codex] == 1_000_000)
        #expect(snapshot.todayXP == 50)
    }

    @Test func cachedProductEntitlementsPersistForOfflineUse() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EvoBarEntitlementTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("state.json")
        let store = try EvoBarStore(fileURL: fileURL)
        try await onboard(store)
        try await store.updateActiveProductIDs(["evobar.animal.fox", "evobar.bundle.prehistoric"])

        let relaunched = try EvoBarStore(fileURL: fileURL)
        let snapshot = await relaunched.snapshot()
        #expect(snapshot.activeProductIDs == ["evobar.animal.fox", "evobar.bundle.prehistoric"])
        #expect(snapshot.starterGrantID == "cat")
    }

    @Test func verifiedOwnershipCreatesFreshCompanionFromGraduatedOwnedLine() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        for stage in 2...5 {
            try await store.acknowledgeEvolution(to: stage, finalStageIndex: 5)
        }
        let paid = try await store.graduateCurrentAndStart(
            definitionID: "fox",
            name: "Ember",
            natureID: "bold",
            rarity: .rare,
            isShiny: true,
            finalStageIndex: 5
        )

        try await store.reconcileVerifiedOwnership(
            activeProductIDs: [],
            ownedAnimalIDs: ["cat"],
            validStarterGrantID: "cat"
        )
        let snapshot = await store.snapshot()
        let current = try #require(snapshot.animalInstances.first { $0.isCurrent })
        let revoked = try #require(snapshot.animalInstances.first { $0.id == paid.id })

        #expect(snapshot.onboardingCompleted)
        #expect(snapshot.activeProductIDs.isEmpty)
        #expect(snapshot.starterGrantID == "cat")
        #expect(current.definitionID == "cat")
        #expect(current.currentXP == 0)
        #expect(current.graduatedAt == nil)
        #expect(!revoked.isCurrent)
        #expect(snapshot.animalInstances.count == 3)
    }

    @Test func verifiedOwnershipRejectsForgedStarterAndReturnsToOnboarding() async throws {
        let store = try EvoBarStore(fileURL: nil)
        _ = try await store.completeOnboarding(starterID: "fox", companionName: "Forged")

        try await store.reconcileVerifiedOwnership(
            activeProductIDs: [],
            ownedAnimalIDs: [],
            validStarterGrantID: nil
        )
        let snapshot = await store.snapshot()

        #expect(!snapshot.onboardingCompleted)
        #expect(snapshot.currentAnimalInstanceID == nil)
        #expect(snapshot.starterGrantID == nil)
        #expect(snapshot.activeProductIDs.isEmpty)
        #expect(snapshot.animalInstances.count == 1)
        #expect(snapshot.animalInstances[0].definitionID == "fox")
        #expect(!snapshot.animalInstances[0].isCurrent)
    }

    @Test func appSettingsPersistAndValidateRefreshInterval() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EvoBarSettingsTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("state.json")
        let store = try EvoBarStore(fileURL: fileURL)
        let settings = AppSettings(
            claudeTrackingEnabled: false,
            codexTrackingEnabled: true,
            refreshIntervalMinutes: 99,
            animationQuality: "smooth",
            showTokenInMenuBar: false,
            showTokenBreakdown: false,
            quotaNotificationsEnabled: true,
            companionNotificationsEnabled: true,
            providerStatusChecksEnabled: false,
            automaticUpdateChecksEnabled: false,
            launchAtLoginEnabled: true,
            claudeAdditionalLogPatterns: ["~/private/*"],
            codexAdditionalLogPatterns: ["/Volumes/private/**"],
            desktopPetEnabled: true,
            desktopPetSize: 240,
            pinnedAnimalDefinitionID: "dog",
            desktopPetX: 120,
            desktopPetY: 80
        )
        try await store.updateAppSettings(settings)

        let relaunched = try EvoBarStore(fileURL: fileURL)
        let restored = await relaunched.snapshot().appSettings
        #expect(restored.refreshIntervalMinutes == 15)
        #expect(!restored.claudeTrackingEnabled)
        #expect(restored.codexTrackingEnabled)
        #expect(restored.animationQuality == "smooth")
        #expect(!restored.showTokenInMenuBar)
        #expect(restored.quotaNotificationsEnabled)
        #expect(restored.companionNotificationsEnabled)
        #expect(!restored.providerStatusChecksEnabled)
        #expect(!restored.automaticUpdateChecksEnabled)
        #expect(restored.launchAtLoginEnabled)
        #expect(restored.claudeAdditionalLogPatterns == ["~/private/*"])
        #expect(restored.codexAdditionalLogPatterns == ["/Volumes/private/**"])
        #expect(restored.desktopPetEnabled)
        #expect(restored.desktopPetSize == 192)
        #expect(restored.pinnedAnimalDefinitionID == "dog")
        #expect(restored.desktopPetX == 120)
        #expect(restored.desktopPetY == 80)
    }

    @Test func exportContainsAggregatesButNoEventsSessionsOrCheckpoints() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        try await store.updateAppSettings(AppSettings(
            claudeAdditionalLogPatterns: ["/Users/private/project/**/*.jsonl"]
        ))
        let event = usageEvent(id: "private-event-id", timestamp: Date(), tokens: 42_000)
        _ = try await store.ingest(
            batch: ScanBatch(
                events: [event],
                checkpoint: SourceCheckpoint(byteOffset: 42, fileSize: 42, sessionID: "private-session"),
                malformedLineCount: 0
            ),
            sourceKey: "private-source",
            providerID: .claudeCode,
            effectiveTokensPerCoin: 100_000
        )

        let data = try await store.exportData()
        let text = try #require(String(data: data, encoding: .utf8))
        #expect(text.contains("dailyUsage"))
        #expect(text.contains("rawTokens"))
        #expect(!text.contains("private-event-id"))
        #expect(!text.contains("private-session"))
        #expect(!text.contains("private-source"))
        #expect(!text.contains("checkpoints"))
        #expect(!text.contains("AdditionalLogPatterns"))
        #expect(!text.contains("/Users/private/project"))
    }

    @Test func gameItemsSpendCoinsAtomicallyAndApplyEffects() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        let event = usageEvent(id: "item-coins", timestamp: Date(), tokens: 1_000)
        _ = try await store.ingest(
            batch: ScanBatch(
                events: [event],
                checkpoint: SourceCheckpoint(byteOffset: 10, fileSize: 10),
                malformedLineCount: 0
            ),
            sourceKey: "item-source",
            providerID: .claudeCode,
            effectiveTokensPerCoin: 1
        )
        let economy = try ManifestLoader.bundledEconomy()
        let candy = try #require(economy.items.first { $0.kind == .rareCandy })
        let mint = try #require(economy.items.first { $0.kind == .mint })
        let charm = try #require(economy.items.first { $0.kind == .shinyCharm })
        let egg = try #require(economy.items.first { $0.kind == .randomEgg })

        try await store.purchaseGameItem(candy, candyRoll: 0.5)
        try await store.purchaseGameItem(mint, replacementNatureID: "steady")
        try await store.purchaseGameItem(charm)
        try await store.purchaseGameItem(egg)
        let purchased = await store.snapshot()
        let current = try #require(purchased.animalInstances.first)
        // Rare Candy waits with the rest of the growth; a middle roll is its listed XP.
        #expect(current.pendingXP == candy.xpGrant)
        #expect(current.natureID == "steady")
        #expect(purchased.itemInventory[charm.id] == 1)
        #expect(purchased.itemInventory[egg.id] == 1)
        #expect(purchased.tokenCoins == 1_000 - candy.tokenCoinPrice - mint.tokenCoinPrice - charm.tokenCoinPrice - egg.tokenCoinPrice)

        await #expect(throws: GameShopStoreError.alreadyOwned) {
            try await store.purchaseGameItem(charm)
        }
        #expect(await store.snapshot().tokenCoins == purchased.tokenCoins)
    }

    /// With everything unlocked during development, an item is applied without
    /// touching the wallet; the same purchase with an empty wallet is refused
    /// once coins are charged again.
    @Test func freeItemsApplyWithoutSpendingCoins() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        let economy = try ManifestLoader.bundledEconomy()
        let candy = try #require(economy.items.first { $0.kind == .rareCandy })
        #expect(await store.snapshot().tokenCoins == 0)

        try await store.purchaseGameItem(candy, chargeCoins: false, candyRoll: 0.5)
        let free = await store.snapshot()
        #expect(free.tokenCoins == 0)
        #expect(try #require(free.animalInstances.first).pendingXP == candy.xpGrant)

        await #expect(throws: GameShopStoreError.insufficientCoins) {
            try await store.purchaseGameItem(candy)
        }
        #expect(try #require(await store.snapshot().animalInstances.first).pendingXP == candy.xpGrant)
    }

    /// Growth arrives whole and once a day counts as care; a golden roll adds
    /// to it and never takes away.
    @Test func absorbingXPMovesItRollsABonusAndCountsCareOncePerDay() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        let timestamp = Date()
        func ingest(_ id: String, tokens: Int64, offset: TimeInterval) async throws {
            _ = try await store.ingest(
                batch: ScanBatch(
                    events: [usageEvent(id: id, timestamp: timestamp.addingTimeInterval(offset), tokens: tokens)],
                    checkpoint: SourceCheckpoint(byteOffset: 1, fileSize: 1),
                    malformedLineCount: 0
                ),
                sourceKey: "arrival-source",
                providerID: .claudeCode,
                effectiveTokensPerCoin: 100_000
            )
        }
        try await ingest("arrival-1", tokens: 1_000_000, offset: 0)
        #expect(await store.snapshot(now: timestamp).pendingXP == 100)

        let plain = try await store.absorbPendingXP(
            now: timestamp, bonusRoll: 0.5, giftCoinRoll: 0, giftItemRoll: 0.5)
        let after = await store.snapshot(now: timestamp)
        // The day's first arrival always carries a gift; pinned here to coins alone.
        #expect(plain == GrowthAbsorption(
            base: 100, bonus: 0, coins: 0, tier: nil,
            gift: DailyGift(coins: DailyGiftEngine.leastCoins, xp: 0, eggs: 0)))
        #expect(after.pendingXP == 0)
        #expect(after.currentXP == 100)
        #expect(after.affectionPoints == AffectionEngine.starting + AffectionEngine.petGain)
        #expect(after.tokenCoins == 10 + DailyGiftEngine.leastCoins)
        await #expect(throws: GameShopStoreError.nothingToAbsorb) {
            try await store.absorbPendingXP(now: timestamp, bonusRoll: 0.5)
        }

        // Raw 3M for the day is 2M effective: 100 more XP and 10 more coins.
        try await ingest("arrival-2", tokens: 2_000_000, offset: 1)
        let golden = try await store.absorbPendingXP(now: timestamp, bonusRoll: 0.01)
        let rich = await store.snapshot(now: timestamp)
        // A second arrival the same day carries no gift.
        #expect(golden == GrowthAbsorption(base: 100, bonus: 100, coins: 3, tier: .golden))
        #expect(rich.currentXP == 300)
        #expect(rich.tokenCoins == 23 + DailyGiftEngine.leastCoins)
        // Care was already counted for this growth day.
        #expect(rich.affectionPoints == after.affectionPoints)
    }

    /// The journal's dates are written as the moments happen: first growth,
    /// first golden roll, each stage, the top of affection, and the busiest day.
    /// The gift lands on the first arrival of a growth day and not on the
    /// second, its coins and XP are added to the same sweep, and an egg it
    /// rolls reaches the inventory.
    /// A backdrop is bought once, worn at once, refused twice, and taking it
    /// off leaves it owned.
    /// Every kind of care counts once toward the bond, and being away never
    /// takes any of it back.
    /// An egg warms once per working day, whatever hour usage lands in, and
    /// only a ready one opens.
    /// Setting one aside costs it nothing, the other picks up the growth from
    /// then on, and coming back finds everything where it was.
    @Test func raisingAnotherCompanionSetsTheFirstAsideWithoutLosingAnything() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        let now = Date()
        func work(_ id: String, offset: TimeInterval, tokens: Int64 = 1_000_000) async throws {
            _ = try await store.ingest(
                batch: ScanBatch(
                    events: [usageEvent(id: id, timestamp: now.addingTimeInterval(offset), tokens: tokens)],
                    checkpoint: SourceCheckpoint(byteOffset: 1, fileSize: 1),
                    malformedLineCount: 0
                ),
                sourceKey: "switch-source",
                providerID: .claudeCode,
                effectiveTokensPerCoin: 100_000
            )
        }
        try await work("switch-1", offset: 0)
        _ = try await store.absorbPendingXP(
            now: now, bonusRoll: 0.5, giftCoinRoll: 0, giftItemRoll: 0.5)
        try await store.acknowledgeEvolution(to: 2, finalStageIndex: 7)
        let first = try #require(await store.snapshot(now: now).animalInstances.first)
        #expect(first.currentXP == 100)

        // A second companion arrives through the incubator.
        let egg = try #require(ManifestLoader.bundledEconomy().items.first { $0.kind == .randomEgg })
        try await store.purchaseGameItem(egg, chargeCoins: false)
        let placed = try await store.placeEggInIncubator(at: now)
        for day in 1...3 { try await work("warm-\(day)", offset: Double(day) * 86_400) }
        let waiting = try await store.hatchEgg(
            id: placed.id, definitionID: "dog", name: "Dog", natureID: "steady",
            rarity: .common, isShiny: false, at: now)

        let raised = try await store.switchCurrentCompanion(to: waiting.id, name: "Nova", at: now)
        let swapped = await store.snapshot(now: now)
        let setAside = try #require(swapped.animalInstances.first { $0.id == first.id })
        #expect(raised.name == "Nova")
        #expect(swapped.currentAnimalInstanceID == waiting.id)
        // Nothing was spent and nothing retired: it rests, it has not graduated.
        #expect(setAside.isResting)
        #expect(setAside.graduatedAt == nil)
        #expect(setAside.currentXP == 100)
        #expect(setAside.acknowledgedStageIndex == 2)
        #expect(!setAside.isWaitingToBeRaised)

        // The days that warmed the egg credited the one growing then, and it
        // keeps that growth while it rests.
        let keptWhileResting = setAside.pendingXP
        #expect(keptWhileResting > 0)

        // Growth from here credits the one now being raised, and only it.
        try await work("switch-2", offset: 4 * 86_400, tokens: 2_000_000)
        let credited = await store.snapshot(now: now)
        #expect(try #require(credited.animalInstances.first { $0.id == waiting.id }).pendingXP > 0)
        #expect(try #require(credited.animalInstances.first { $0.id == first.id }).pendingXP
            == keptWhileResting)

        // And going back finds it exactly as it was left.
        let returned = try await store.switchCurrentCompanion(to: first.id, at: now)
        #expect(returned.currentXP == 100)
        #expect(returned.name == first.name)
        #expect(await store.snapshot(now: now).currentAnimalInstanceID == first.id)
    }

    /// The day's gift belongs to the day, so swapping who grows cannot collect
    /// a second one.
    @Test func switchingCompanionsDoesNotCollectTheGiftTwice() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        let now = Date()
        func work(_ id: String, offset: TimeInterval) async throws {
            _ = try await store.ingest(
                batch: ScanBatch(
                    events: [usageEvent(id: id, timestamp: now.addingTimeInterval(offset), tokens: 1_000_000)],
                    checkpoint: SourceCheckpoint(byteOffset: 1, fileSize: 1),
                    malformedLineCount: 0
                ),
                sourceKey: "gift-twice",
                providerID: .claudeCode,
                effectiveTokensPerCoin: 100_000
            )
        }
        try await work("twice-1", offset: 0)
        let firstArrival = try await store.absorbPendingXP(
            now: now, bonusRoll: 0.5, giftCoinRoll: 0, giftItemRoll: 0.5)
        #expect(firstArrival.gift != nil)

        let egg = try #require(ManifestLoader.bundledEconomy().items.first { $0.kind == .randomEgg })
        try await store.purchaseGameItem(egg, chargeCoins: false)
        let placed = try await store.placeEggInIncubator(at: now)
        for day in 1...3 { try await work("twice-warm-\(day)", offset: Double(day) * 86_400) }
        let waiting = try await store.hatchEgg(
            id: placed.id, definitionID: "dog", name: "Dog", natureID: "steady",
            rarity: .common, isShiny: false, at: now)
        try await store.switchCurrentCompanion(to: waiting.id, name: "Nova", at: now)

        // Work after the switch credits the one now being raised.
        try await work("twice-2", offset: 4 * 86_400)

        // It takes in its own growth, on the same growth day, and gets no
        // second gift for that day.
        let second = try await store.absorbPendingXP(
            now: now, bonusRoll: 0.5, giftCoinRoll: 0, giftItemRoll: 0.5)
        #expect(second.gift == nil)
        #expect(second.total > 0)
    }

    @Test func eggsWarmOnWorkingDaysAndHatchIntoACompanionThatWaits() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        let now = Date()
        let egg = try #require(ManifestLoader.bundledEconomy().items.first { $0.kind == .randomEgg })

        await #expect(throws: IncubatorStoreError.noEggToPlace) {
            try await store.placeEggInIncubator(at: now)
        }
        try await store.purchaseGameItem(egg, chargeCoins: false)
        let placed = try await store.placeEggInIncubator(at: now)
        let started = await store.snapshot(now: now)
        #expect(started.incubator.count == 1)
        #expect(started.itemInventory["random-egg"] == nil)
        #expect(started.incubator[0].activeDays == 0)

        func work(_ id: String, offset: TimeInterval) async throws {
            _ = try await store.ingest(
                batch: ScanBatch(
                    events: [usageEvent(id: id, timestamp: now.addingTimeInterval(offset), tokens: 100_000)],
                    checkpoint: SourceCheckpoint(byteOffset: 1, fileSize: 1),
                    malformedLineCount: 0
                ),
                sourceKey: "egg-source",
                providerID: .claudeCode,
                effectiveTokensPerCoin: 100_000
            )
        }
        // Two arrivals on one day are one day of warmth.
        try await work("egg-1", offset: 0)
        try await work("egg-2", offset: 60)
        #expect(await store.snapshot(now: now).incubator[0].activeDays == 1)

        await #expect(throws: IncubatorStoreError.notReady) {
            try await store.hatchEgg(
                id: placed.id, definitionID: "cat", name: "Cat", natureID: "curious",
                rarity: .common, isShiny: false, at: now)
        }

        try await work("egg-3", offset: 86_400)
        try await work("egg-4", offset: 2 * 86_400)
        let ready = await store.snapshot(now: now)
        #expect(ready.incubator[0].activeDays == IncubatingEgg.activeDaysToHatch)
        #expect(ready.incubator[0].isReady)

        let hatched = try await store.hatchEgg(
            id: placed.id, definitionID: "dog", name: "Dog", natureID: "steady",
            rarity: .common, isShiny: true, at: now)
        let after = await store.snapshot(now: now)
        #expect(after.incubator.isEmpty)
        #expect(hatched.isWaitingToBeRaised)
        // One that was raised and set aside is not waiting, whatever its dates.
        var raisedBefore = hatched
        raisedBefore.acknowledgedStageIndex = 3
        #expect(!raisedBefore.isWaitingToBeRaised)
        #expect(after.animalInstances.contains { $0.id == hatched.id && $0.isShiny })
        // The companion being raised is untouched by a hatch.
        #expect(after.currentAnimalInstanceID != hatched.id)
        await #expect(throws: IncubatorStoreError.noSuchEgg) {
            try await store.hatchEgg(
                id: placed.id, definitionID: "cat", name: "Duplicate", natureID: "curious",
                rarity: .common, isShiny: false, at: now)
        }
        #expect(await store.snapshot(now: now).animalInstances.count == after.animalInstances.count)
    }

    @Test(arguments: ["onboard", "evolve", "switch", "graduate-new", "graduate-waiting"])
    func companionTransitionsRecoverFromFailedSave(action: String) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("EvoBarTransition-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("state.json")
        let store = try EvoBarStore(fileURL: url)
        let now = Date()
        let start = now.addingTimeInterval(-4 * 86_400)
        try await store.saveBaseline(sourceKey: "transition-fixture", providerID: .claudeCode,
                                     checkpoint: SourceCheckpoint(byteOffset: 0, fileSize: 0))
        var waitingID: UUID?
        if action != "onboard" {
            try await store.completeOnboarding(starterID: "cat", companionName: "Mochi", startedAt: start)
            let eggItem = try #require(ManifestLoader.bundledEconomy().items.first { $0.kind == .randomEgg })
            try await store.purchaseGameItem(eggItem, chargeCoins: false)
            let egg = try await store.placeEggInIncubator(at: start)
            for day in 1...3 {
                _ = try await store.ingest(batch: ScanBatch(events: [usageEvent(
                    id: "transition-day-\(day)", timestamp: start.addingTimeInterval(Double(day) * 86_400), tokens: 1_000_000)],
                    checkpoint: SourceCheckpoint(byteOffset: UInt64(day), fileSize: UInt64(day)), malformedLineCount: 0),
                    sourceKey: "transition-fixture", providerID: .claudeCode, effectiveTokensPerCoin: 100_000)
            }
            waitingID = try await store.hatchEgg(id: egg.id, definitionID: "dog", name: "Waiting",
                natureID: "steady", rarity: .common, isShiny: true, at: now).id
            try await store.purchaseGameItem(eggItem, chargeCoins: false)
            if action.hasPrefix("graduate") {
                for stage in 2...7 { try await store.acknowledgeEvolution(to: stage, finalStageIndex: 7) }
            }
        }
        let before = await store.snapshot(now: now)
        func transition() async throws {
            switch action {
            case "onboard":
                try await store.completeOnboarding(starterID: "cat", companionName: "Mochi", startedAt: start)
            case "evolve":
                try await store.acknowledgeEvolution(to: 2, finalStageIndex: 7, evolvedAt: now)
            case "switch":
                try await store.switchCurrentCompanion(to: #require(waitingID), name: "Nova", at: now)
            case "graduate-waiting":
                try await store.graduateCurrentAndAdopt(instanceID: #require(waitingID), name: "Nova", finalStageIndex: 7, at: now)
            default:
                try await store.graduateCurrentAndStart(definitionID: "fox", name: "Next", natureID: "steady",
                    rarity: .uncommon, isShiny: false, finalStageIndex: 7, consumingItemID: "random-egg", at: now)
            }
        }
        let backup = directory.appendingPathComponent("saved.json")
        try FileManager.default.moveItem(at: url, to: backup)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        await #expect(throws: (any Error).self) { try await transition() }
        let failed = await store.snapshot(now: now)
        #expect(failed.animalInstances == before.animalInstances)
        #expect(failed.currentAnimalInstanceID == before.currentAnimalInstanceID)
        #expect(failed.onboardingCompleted == before.onboardingCompleted)
        #expect(failed.starterGrantID == before.starterGrantID)
        #expect(failed.trackingStartedAt == before.trackingStartedAt)
        #expect(failed.itemInventory == before.itemInventory)
        #expect(failed.pendingXP == before.pendingXP)
        #expect(failed.tokenCoins == before.tokenCoins)
        try FileManager.default.removeItem(at: url)
        try FileManager.default.moveItem(at: backup, to: url)
        try await transition()
        let committed = await store.snapshot(now: now)
        let reopened = try EvoBarStore(fileURL: url)
        let restored = await reopened.snapshot(now: now)
        #expect(committed.animalInstances != before.animalInstances)
        #expect(committed.animalInstances.filter(\.isCurrent).count == 1)
        #expect(restored.animalInstances == committed.animalInstances)
        #expect(restored.currentAnimalInstanceID == committed.currentAnimalInstanceID)
        #expect(restored.itemInventory == committed.itemInventory)
        #expect(restored.trackingStartedAt == committed.trackingStartedAt)
        #expect(restored.onboardingCompleted == true)
        if action == "graduate-new" { #expect(restored.itemInventory["random-egg"] == nil) }
    }

    @Test func eggDaysIgnorePrePlacementUsageAndDuplicateDatesAcrossProviders() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("EvoBarEggDays-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("state.json")
        let store = try EvoBarStore(fileURL: url)
        try await onboard(store)
        let start = Date(timeIntervalSince1970: 1_750_032_000)
        let item = try #require(ManifestLoader.bundledEconomy().items.first { $0.kind == .randomEgg })
        try await store.purchaseGameItem(item, chargeCoins: false)
        try await store.placeEggInIncubator(at: start)
        func log(_ target: EvoBarStore, _ id: String, _ offset: TimeInterval,
                 tokens: Int64 = 100, provider: ProviderID = .claudeCode) async throws {
            var event = usageEvent(id: id, timestamp: start.addingTimeInterval(offset), tokens: tokens)
            event = UsageEvent(stableID: event.stableID, provider: provider, sessionID: event.sessionID,
                               timestamp: event.timestamp, modelID: event.modelID,
                               usage: event.usage, sourceFingerprint: event.sourceFingerprint)
            _ = try await target.ingest(batch: ScanBatch(events: [event],
                checkpoint: SourceCheckpoint(byteOffset: 1, fileSize: 1), malformedLineCount: 0),
                sourceKey: provider.rawValue, providerID: provider, effectiveTokensPerCoin: 100_000)
        }
        try await log(store, "before-placement", -86_400)
        try await log(store, "zero-usage", 3_600, tokens: 0)
        #expect(await store.snapshot().incubator[0].activeDays == 0)
        try await log(store, "later-day", 90_000)
        try await log(store, "earlier-day", 3_600)
        try await log(store, "later-day-codex", 90_001, provider: .codex)
        #expect(await store.snapshot().incubator[0].activeDays == 2)

        // Emulate the prior save format and exercise its real migration path.
        var saved = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        var settings = try #require(saved["settings"] as? [String: Any])
        var eggs = try #require(settings["incubator"] as? [[String: Any]])
        eggs[0].removeValue(forKey: "countedDayKeys")
        settings["incubator"] = eggs
        saved["settings"] = settings
        try JSONSerialization.data(withJSONObject: saved).write(to: url, options: .atomic)
        let reopened = try EvoBarStore(fileURL: url)
        try await log(reopened, "earlier-day-codex", 3_601, provider: .codex)
        #expect(await reopened.snapshot().incubator[0].activeDays == 2)
        try await log(reopened, "third-day", 176_400)
        #expect(await reopened.snapshot().incubator[0].isReady == true)
    }

    @Test(arguments: ["treat", "candy", "pet", "absorb", "egg", "charm", "mint", "scene"])
    func companionRewardsRollBackWhenSavingFails(action: String) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("EvoBarRewardWrite-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("state.json")
        let store = try EvoBarStore(fileURL: url)
        try await onboard(store)
        let now = Date()
        _ = try await store.ingest(batch: ScanBatch(events: [usageEvent(
            id: "reward-fixture", timestamp: now, tokens: 500_000_000)],
            checkpoint: SourceCheckpoint(byteOffset: 1, fileSize: 1), malformedLineCount: 0),
            sourceKey: "reward-fixture", providerID: .claudeCode, effectiveTokensPerCoin: 100_000)
        let before = await store.snapshot(now: now)
        let economy = try ManifestLoader.bundledEconomy()
        func mutate() async throws {
            switch action {
            case "pet": try await store.petCurrentAnimal(now: now)
            case "absorb":
                _ = try await store.absorbPendingXP(now: now, bonusRoll: 0.9, giftCoinRoll: 0, giftItemRoll: 0.9)
            default:
                let kinds: [String: GameItemKind] = ["treat": .treat, "candy": .rareCandy, "egg": .randomEgg,
                    "charm": .shinyCharm, "mint": .mint, "scene": .sceneTheme]
                let kind = try #require(kinds[action])
                let item = try #require(economy.items.first { $0.kind == kind })
                try await store.purchaseGameItem(item, replacementNatureID: "steady", candyRoll: 0.5)
            }
        }
        let savedURL = directory.appendingPathComponent("saved.json")
        try FileManager.default.moveItem(at: url, to: savedURL)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        await #expect(throws: (any Error).self) { try await mutate() }
        let failed = await store.snapshot(now: now)
        #expect(failed.animalInstances == before.animalInstances)
        #expect(failed.tokenCoins == before.tokenCoins)
        #expect(failed.pendingXP == before.pendingXP)
        #expect(failed.itemInventory == before.itemInventory)
        #expect(failed.appSettings == before.appSettings)
        try FileManager.default.removeItem(at: url)
        try FileManager.default.moveItem(at: savedURL, to: url)
        try await mutate()
        let committed = await store.snapshot(now: now)
        let reopened = try EvoBarStore(fileURL: url)
        let restored = await reopened.snapshot(now: now)
        #expect(restored.animalInstances == committed.animalInstances)
        #expect(restored.tokenCoins == committed.tokenCoins)
        #expect(restored.itemInventory == committed.itemInventory)
        #expect(restored.appSettings == committed.appSettings)
        #expect(committed.animalInstances != before.animalInstances || committed.itemInventory != before.itemInventory)
    }

    @Test func readyEggWaitsAcrossRelaunchAndHatchIsPermanent() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EvoBarHatchTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("state.json")
        let store = try EvoBarStore(fileURL: url)
        try await onboard(store)
        let now = Date()
        let item = try #require(ManifestLoader.bundledEconomy().items.first { $0.kind == .randomEgg })
        try await store.purchaseGameItem(item, chargeCoins: false)
        // A directory at the save-file path simulates a failed atomic write.
        let savedURL = directory.appendingPathComponent("saved.json")
        try FileManager.default.moveItem(at: url, to: savedURL)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        await #expect(throws: (any Error).self) {
            try await store.placeEggInIncubator(at: now)
        }
        #expect(await store.snapshot().incubator.isEmpty)
        #expect(await store.snapshot().itemInventory["random-egg"] == 1)
        try FileManager.default.removeItem(at: url)
        try FileManager.default.moveItem(at: savedURL, to: url)
        let egg = try await store.placeEggInIncubator(at: now)
        for day in 0..<3 {
            _ = try await store.ingest(
                batch: ScanBatch(events: [usageEvent(id: "hatch-day-\(day)",
                    timestamp: now.addingTimeInterval(Double(day) * 86_400), tokens: 100_000)],
                    checkpoint: SourceCheckpoint(byteOffset: UInt64(day + 1), fileSize: UInt64(day + 1)),
                    malformedLineCount: 0),
                sourceKey: "hatch", providerID: .claudeCode, effectiveTokensPerCoin: 100_000)
        }
        let reopened = try EvoBarStore(fileURL: url)
        let before = await reopened.snapshot()
        #expect(before.incubator.first?.id == egg.id)
        #expect(before.incubator.first?.isReady == true)
        try FileManager.default.moveItem(at: url, to: savedURL)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        await #expect(throws: (any Error).self) {
            try await reopened.hatchEgg(id: egg.id, definitionID: "cat", name: "Lost friend",
                natureID: "curious", rarity: .common, isShiny: true)
        }
        let failed = await reopened.snapshot()
        #expect(failed.incubator == before.incubator)
        #expect(failed.animalInstances == before.animalInstances)
        #expect(failed.currentAnimalInstanceID == before.currentAnimalInstanceID)
        #expect(failed.itemInventory == before.itemInventory)
        #expect(failed.tokenCoins == before.tokenCoins)
        #expect(failed.pendingXP == before.pendingXP)
        try FileManager.default.removeItem(at: url)
        try FileManager.default.moveItem(at: savedURL, to: url)
        let arrival = try await reopened.hatchEgg(id: egg.id, definitionID: "cat", name: "New friend",
            natureID: "curious", rarity: .common, isShiny: true)
        let reloaded = try EvoBarStore(fileURL: url)
        let after = await reloaded.snapshot()
        #expect(after.incubator.isEmpty)
        #expect(after.currentAnimalInstanceID == before.currentAnimalInstanceID)
        #expect(after.animalInstances.count == before.animalInstances.count + 1)
        #expect(after.animalInstances.filter { $0.id != arrival.id } == before.animalInstances)
        #expect(after.itemInventory == before.itemInventory)
        #expect(after.tokenCoins == before.tokenCoins)
        #expect(after.animalInstances.contains { $0.id == arrival.id && $0.isShiny && $0.isWaitingToBeRaised })
        await #expect(throws: IncubatorStoreError.noSuchEgg) {
            try await reloaded.hatchEgg(id: egg.id, definitionID: "cat", name: "Duplicate",
                natureID: "curious", rarity: .common, isShiny: false)
        }
        let replayed = await reloaded.snapshot()
        #expect(replayed.animalInstances == after.animalInstances)
        #expect(replayed.incubator == after.incubator)
        let finalReload = try EvoBarStore(fileURL: url)
        #expect(await finalReload.snapshot().animalInstances == after.animalInstances)
    }

    /// Adopting one that waited graduates the old companion and raises it,
    /// keeping everything it hatched with.
    @Test func adoptingAWaitingCompanionGraduatesTheOldOne() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        let now = Date()
        let egg = try #require(ManifestLoader.bundledEconomy().items.first { $0.kind == .randomEgg })
        try await store.purchaseGameItem(egg, chargeCoins: false)
        let placed = try await store.placeEggInIncubator(at: now)
        for day in 0..<3 {
            _ = try await store.ingest(
                batch: ScanBatch(
                    events: [usageEvent(
                        id: "adopt-\(day)", timestamp: now.addingTimeInterval(Double(day) * 86_400),
                        tokens: 100_000)],
                    checkpoint: SourceCheckpoint(byteOffset: 1, fileSize: 1),
                    malformedLineCount: 0
                ),
                sourceKey: "adopt-source",
                providerID: .claudeCode,
                effectiveTokensPerCoin: 100_000
            )
        }
        let waiting = try await store.hatchEgg(
            id: placed.id, definitionID: "fox", name: "Fox", natureID: "bright",
            rarity: .uncommon, isShiny: false, at: now)

        // Not until the companion being raised has finished.
        await #expect(throws: GraduationStoreError.currentAnimalNotFinal) {
            try await store.graduateCurrentAndAdopt(
                instanceID: waiting.id, name: "Sora", finalStageIndex: 7, at: now)
        }
        for stage in 2...7 { try await store.acknowledgeEvolution(to: stage, finalStageIndex: 7) }

        let adopted = try await store.graduateCurrentAndAdopt(
            instanceID: waiting.id, name: "Sora", finalStageIndex: 7, at: now)
        let after = await store.snapshot(now: now)
        #expect(adopted.name == "Sora")
        #expect(adopted.definitionID == "fox")
        #expect(adopted.natureID == "bright")
        #expect(after.currentAnimalInstanceID == adopted.id)
        #expect(after.animalInstances.contains { $0.definitionID == "cat" && $0.graduatedAt != nil })
        // Adopted means raised, so it is no longer one of the waiting.
        #expect(after.animalInstances.filter(\.isWaitingToBeRaised).isEmpty)
        let raised = try #require(after.animalInstances.first { $0.id == waiting.id })
        #expect(raised.isCurrent)
        #expect(!raised.isWaitingToBeRaised)
    }

    @Test func everyActOfCareRaisesTheBondAndNoneOfItIsLost() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        let now = Date()
        #expect(await store.snapshot(now: now).careCount == 0)

        for _ in 0..<3 { try await store.petCurrentAnimal(now: now) }
        let treat = try #require(ManifestLoader.bundledEconomy().items.first { $0.kind == .treat })
        try await store.purchaseGameItem(treat, chargeCoins: false)
        _ = try await store.ingest(
            batch: ScanBatch(
                events: [usageEvent(id: "bond-1", timestamp: now, tokens: 1_000_000)],
                checkpoint: SourceCheckpoint(byteOffset: 1, fileSize: 1),
                malformedLineCount: 0
            ),
            sourceKey: "bond-source",
            providerID: .claudeCode,
            effectiveTokensPerCoin: 100_000
        )
        _ = try await store.absorbPendingXP(
            now: now, bonusRoll: 0.5, giftCoinRoll: 0, giftItemRoll: 0.5)

        // Three pettings, one treat, and the day's first growth.
        let warm = await store.snapshot(now: now)
        #expect(warm.careCount == 5)
        #expect(warm.affectionPoints > AffectionEngine.starting)

        // A fortnight away cools the mood and leaves the bond where it was.
        let later = now.addingTimeInterval(14 * 86_400)
        let cold = await store.snapshot(now: later)
        #expect(cold.careCount == warm.careCount)
        #expect(cold.affectionPoints < warm.affectionPoints)
    }

    @Test func sceneThemesAreBoughtOnceAndWornByChoice() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        let economy = try ManifestLoader.bundledEconomy()
        let themes = economy.items.filter { $0.kind == .sceneTheme }
        #expect(themes.count == SceneTheme.allCases.count)
        #expect(Set(themes.map(\.id)) == Set(SceneTheme.allCases.map(\.itemID)))
        let night = try #require(themes.first { $0.id == SceneTheme.night.itemID })

        try await store.purchaseGameItem(night, chargeCoins: false)
        let worn = await store.snapshot()
        #expect(worn.itemInventory[night.id] == 1)
        #expect(worn.appSettings.sceneThemeID == night.id)
        #expect(SceneTheme(itemID: night.id) == .night)

        await #expect(throws: GameShopStoreError.alreadyOwned) {
            try await store.purchaseGameItem(night, chargeCoins: false)
        }

        var settings = worn.appSettings
        settings.sceneThemeID = nil
        try await store.updateAppSettings(settings)
        let bare = await store.snapshot()
        #expect(bare.appSettings.sceneThemeID == nil)
        #expect(bare.itemInventory[night.id] == 1)
    }

    @Test func theDailyGiftLandsOnceAGrowthDay() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        let now = Date()
        func ingest(_ id: String, tokens: Int64, offset: TimeInterval) async throws {
            _ = try await store.ingest(
                batch: ScanBatch(
                    events: [usageEvent(id: id, timestamp: now.addingTimeInterval(offset), tokens: tokens)],
                    checkpoint: SourceCheckpoint(byteOffset: 1, fileSize: 1),
                    malformedLineCount: 0
                ),
                sourceKey: "gift-source",
                providerID: .claudeCode,
                effectiveTokensPerCoin: 100_000
            )
        }
        try await ingest("gift-1", tokens: 1_000_000, offset: 0)
        let first = try await store.absorbPendingXP(
            now: now, bonusRoll: 0.5, giftCoinRoll: 0.5, giftItemRoll: 0.01, giftCandyXP: 60)
        let afterFirst = await store.snapshot(now: now)
        #expect(first.gift == DailyGift(coins: 4, xp: 0, eggs: 1))
        #expect(first.total == 100)
        // Ten coins from the day's tokens, four from the gift.
        #expect(afterFirst.tokenCoins == 14)
        #expect(afterFirst.itemInventory["random-egg"] == 1)

        try await ingest("gift-2", tokens: 2_000_000, offset: 1)
        let second = try await store.absorbPendingXP(
            now: now, bonusRoll: 0.5, giftCoinRoll: 0.5, giftItemRoll: 0.01, giftCandyXP: 60)
        let afterSecond = await store.snapshot(now: now)
        #expect(second.gift == nil)
        #expect(afterSecond.itemInventory["random-egg"] == 1)
        #expect(afterSecond.tokenCoins == 24)

        // A gift that rolls a candy adds its XP to the same sweep.
        let tomorrow = now.addingTimeInterval(86_400)
        try await ingest("gift-3", tokens: 1_000_000, offset: 86_400)
        let third = try await store.absorbPendingXP(
            now: tomorrow, bonusRoll: 0.5, giftCoinRoll: 0, giftItemRoll: 0.10, giftCandyXP: 60)
        #expect(third.gift == DailyGift(coins: 2, xp: 60, eggs: 0))
        #expect(third.total == third.base + 60)
    }

    @Test func journalDatesAreRecordedAsTheyHappen() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        let now = Date()
        _ = try await store.ingest(
            batch: ScanBatch(
                events: [usageEvent(id: "journal-1", timestamp: now, tokens: 1_000_000)],
                checkpoint: SourceCheckpoint(byteOffset: 1, fileSize: 1),
                malformedLineCount: 0
            ),
            sourceKey: "journal-source",
            providerID: .claudeCode,
            effectiveTokensPerCoin: 100_000
        )
        let golden = try await store.absorbPendingXP(
            now: now, bonusRoll: 0.01, giftCoinRoll: 0, giftItemRoll: 0.5)
        #expect(golden.tier == .golden)
        try await store.acknowledgeEvolution(to: 2, finalStageIndex: 7, evolvedAt: now)
        // 50 to start, 2 for growth, 10 for five pets and 24 for two treats: past 80.
        for _ in 0..<5 { try await store.petCurrentAnimal(now: now) }
        let treat = try #require(ManifestLoader.bundledEconomy().items.first { $0.kind == .treat })
        try await store.purchaseGameItem(treat, chargeCoins: false)
        try await store.purchaseGameItem(treat, chargeCoins: false)

        let snapshot = await store.snapshot(now: now)
        let instance = try #require(snapshot.animalInstances.first)
        #expect(instance.firstGrowthAt == now)
        #expect(instance.firstGoldenAt == now)
        #expect(instance.evolutionDates[2] == now)
        #expect(instance.adoringAt != nil)
        #expect(snapshot.busiestDays[instance.id]?.tokens == 1_000_000)
    }

    @Test func randomEggIsConsumedOnlyBySuccessfulGraduation() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        for stage in 2...5 {
            try await store.acknowledgeEvolution(to: stage, finalStageIndex: 5)
        }
        await #expect(throws: GraduationStoreError.requiredItemUnavailable) {
            try await store.graduateCurrentAndStart(
                definitionID: "dog",
                name: "Nova",
                natureID: "steady",
                rarity: .common,
                isShiny: false,
                finalStageIndex: 5,
                consumingItemID: "random-egg"
            )
        }

        let event = usageEvent(id: "egg-coins", timestamp: Date(), tokens: 100)
        _ = try await store.ingest(
            batch: ScanBatch(
                events: [event],
                checkpoint: SourceCheckpoint(byteOffset: 10, fileSize: 10),
                malformedLineCount: 0
            ),
            sourceKey: "egg-source",
            providerID: .claudeCode,
            effectiveTokensPerCoin: 1
        )
        let egg = try #require(ManifestLoader.bundledEconomy().items.first { $0.kind == .randomEgg })
        try await store.purchaseGameItem(egg)
        _ = try await store.graduateCurrentAndStart(
            definitionID: "dog",
            name: "Nova",
            natureID: "steady",
            rarity: .common,
            isShiny: false,
            finalStageIndex: 5,
            consumingItemID: egg.id
        )
        #expect(await store.snapshot().itemInventory[egg.id] == nil)
    }

    /// The dashboard carries the story of each window and, across days, the
    /// streak, yesterday's total and the record day.
    @Test func usageDashboardTellsTheStoryOfTheDay() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 10, hour: 12)))
        _ = try await store.ingest(
            batch: ScanBatch(
                events: [
                    usageEvent(id: "story-1", timestamp: now.addingTimeInterval(-300), tokens: 200_000),
                    usageEvent(id: "story-2", timestamp: now, tokens: 700_000),
                    usageEvent(id: "story-3", timestamp: now.addingTimeInterval(-86_400), tokens: 1_000_000),
                ],
                checkpoint: SourceCheckpoint(byteOffset: 1, fileSize: 1),
                malformedLineCount: 0
            ),
            sourceKey: "story-source",
            providerID: .claudeCode,
            effectiveTokensPerCoin: 100_000
        )
        let dashboard = await store.usageDashboard(now: now)
        let today = try #require(dashboard.window(.today))
        // Five minutes between two events of one session, plus the minute after the last.
        #expect(today.story.activeSeconds == 360)
        #expect(today.story.longestSessionSeconds == 360)
        #expect(today.story.peakHour == 12)
        #expect(today.usage.totalTokens == 900_000)
        // Yesterday's lone event is a minute of its own.
        #expect(try #require(dashboard.window(.week)).story.activeSeconds == 420)
        #expect(dashboard.streakDays == 2)
        #expect(dashboard.yesterdayTokens == 1_000_000)
        #expect(dashboard.bestDay?.tokens == 1_000_000)
        #expect(dashboard.bestDay.map { calendar.isDate($0.date, inSameDayAs: now.addingTimeInterval(-86_400)) } == true)
    }

    @Test func usageDashboardSeparatesRollingCalendarProviderAndModelWindows() async throws {
        let store = try EvoBarStore(fileURL: nil)
        try await onboard(store)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        let now = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 9,
            day: 10,
            hour: 12
        )))
        let weekStart = try #require(calendar.dateInterval(of: .weekOfYear, for: now)?.start)
        let monthStart = try #require(calendar.dateInterval(of: .month, for: now)?.start)
        let events = [
            dashboardEvent(
                id: "rolling-claude",
                provider: .claudeCode,
                session: "c1",
                timestamp: now.addingTimeInterval(-2 * 60 * 60),
                model: "claude-sonnet-5",
                input: 70,
                output: 30
            ),
            dashboardEvent(
                id: "today-codex",
                provider: .codex,
                session: "x1",
                timestamp: now.addingTimeInterval(-6 * 60 * 60),
                model: "gpt-5.6-terra",
                input: 120,
                output: 80
            ),
            dashboardEvent(
                id: "week-claude",
                provider: .claudeCode,
                session: "c2",
                timestamp: weekStart.addingTimeInterval(24 * 60 * 60),
                model: "claude-opus-4-7",
                input: 200,
                output: 100
            ),
            dashboardEvent(
                id: "month-codex",
                provider: .codex,
                session: "x2",
                timestamp: monthStart.addingTimeInterval(24 * 60 * 60),
                model: "gpt-5.4",
                input: 250,
                output: 150
            ),
            dashboardEvent(
                id: "previous-month",
                provider: .claudeCode,
                session: "old",
                timestamp: monthStart.addingTimeInterval(-1),
                model: "old-model",
                input: 500,
                output: 0
            ),
            dashboardEvent(
                id: "future",
                provider: .codex,
                session: "future",
                timestamp: now.addingTimeInterval(1),
                model: "future-model",
                input: 900,
                output: 0
            ),
        ]
        _ = try await store.ingest(
            batch: ScanBatch(
                events: events,
                checkpoint: SourceCheckpoint(byteOffset: 1_000, fileSize: 1_000),
                malformedLineCount: 0
            ),
            sourceKey: "dashboard-source",
            providerID: .claudeCode,
            effectiveTokensPerCoin: 100_000
        )

        let dashboard = await store.usageDashboard(
            now: now,
            pricing: try ManifestLoader.bundledPricing()
        )
        let rolling = try #require(dashboard.window(.rollingFiveHours))
        let today = try #require(dashboard.window(.today))
        let week = try #require(dashboard.window(.week))
        let month = try #require(dashboard.window(.month))

        #expect(rolling.usage.totalTokens == 100)
        #expect(today.usage.totalTokens == 300)
        #expect(today.usage.inputTokens == 190)
        #expect(today.usage.outputTokens == 110)
        #expect(today.sessionCount == 2)
        #expect(today.providers.first { $0.providerID == .claudeCode }?.usage.totalTokens == 100)
        #expect(today.providers.first { $0.providerID == .codex }?.usage.totalTokens == 200)
        #expect(today.models.map(\.modelID) == ["gpt-5.6-terra", "claude-sonnet-5"])
        #expect(today.estimatedAPICostUSD == Decimal(string: "0.00164"))
        #expect(today.costCoverage == 1)
        #expect(week.usage.totalTokens == 600)
        #expect(month.usage.totalTokens == 1_000)
        #expect(month.models.allSatisfy { $0.modelID != "old-model" && $0.modelID != "future-model" })
    }

    private func onboard(_ store: EvoBarStore) async throws {
        try await store.completeOnboarding(starterID: "cat", companionName: "Mochi")
    }

    private func usageEvent(id: String, timestamp: Date, tokens: Int64) -> UsageEvent {
        UsageEvent(
            stableID: UsageEventID(rawValue: id),
            provider: .claudeCode,
            sessionID: "session",
            timestamp: timestamp,
            modelID: "fixture-model",
            usage: TokenUsage(inputTokens: tokens, outputTokens: 0, totalTokens: tokens),
            sourceFingerprint: "fixture-source"
        )
    }

    private func dashboardEvent(
        id: String,
        provider: ProviderID,
        session: String,
        timestamp: Date,
        model: String?,
        input: Int64,
        output: Int64
    ) -> UsageEvent {
        UsageEvent(
            stableID: UsageEventID(rawValue: id),
            provider: provider,
            sessionID: session,
            timestamp: timestamp,
            modelID: model,
            usage: TokenUsage(
                inputTokens: input,
                outputTokens: output,
                totalTokens: input + output
            ),
            sourceFingerprint: "dashboard-fixture"
        )
    }
}
