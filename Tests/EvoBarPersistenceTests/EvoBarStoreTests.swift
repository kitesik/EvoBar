import EvoBarCore
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
        #expect(first.currentXP == 100)
        #expect(first.tokenCoins == 10)
        #expect(second.todayTokens == first.todayTokens)
        #expect(second.currentXP == first.currentXP)
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
        #expect(todaySnapshot.currentXP == 200)
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
        #expect(graduated.currentXP == 100)
        #expect(graduated.cumulativeTokens == 1_000_000)
        #expect(current.isCurrent)
        #expect(current.name == "Nova")
        #expect(current.definitionID == "dog")
        #expect(current.currentXP == 50)
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
        try await store.updateActiveProductIDs(["evobar.animal.fox", "evobar.bundle.forest"])

        let relaunched = try EvoBarStore(fileURL: fileURL)
        let snapshot = await relaunched.snapshot()
        #expect(snapshot.activeProductIDs == ["evobar.animal.fox", "evobar.bundle.forest"])
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

        try await store.purchaseGameItem(candy)
        try await store.purchaseGameItem(mint, replacementNatureID: "steady")
        try await store.purchaseGameItem(charm)
        try await store.purchaseGameItem(egg)
        let purchased = await store.snapshot()
        let current = try #require(purchased.animalInstances.first)
        #expect(current.currentXP == 25)
        #expect(current.natureID == "steady")
        #expect(purchased.itemInventory[charm.id] == 1)
        #expect(purchased.itemInventory[egg.id] == 1)
        #expect(purchased.tokenCoins == 1_000 - candy.tokenCoinPrice - mint.tokenCoinPrice - charm.tokenCoinPrice - egg.tokenCoinPrice)

        await #expect(throws: GameShopStoreError.alreadyOwned) {
            try await store.purchaseGameItem(charm)
        }
        #expect(await store.snapshot().tokenCoins == purchased.tokenCoins)
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
