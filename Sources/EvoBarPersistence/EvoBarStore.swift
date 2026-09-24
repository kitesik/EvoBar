import EvoBarCore
import EvoBarEvolution
import EvoBarUsage
import Foundation

public struct PersistedAppSnapshot: Sendable {
    public let onboardingCompleted: Bool
    public let currentAnimalInstanceID: UUID?
    public let companionName: String
    public let currentAnimalID: AnimalDefinitionID
    public let currentXP: Int64
    public let animalInstances: [AnimalInstance]
    public let starterGrantID: AnimalDefinitionID?
    public let activeProductIDs: Set<ProductID>
    public let tokenCoins: Int64
    public let todayTokens: Int64
    public let todayXP: Int64
    /// Raw token totals of up to 30 earlier recorded days, newest first.
    public let dailyRawTokens: [Int64]
    /// Raw token totals for the seven calendar days ending today, oldest first,
    /// with days that saw no usage as zero. The home tab charts these.
    public let weekRawTokens: [Int64]
    /// XP that arrived from work and has not been taken in yet.
    public let pendingXP: Int64
    /// Decayed affection of the active companion, in hundredths.
    public let affectionPoints: Int64
    /// Every act of care the active companion has received.
    public let careCount: Int
    public let petsRemainingToday: Int
    public let treatsRemainingToday: Int
    public let growthTimeZoneID: String
    public let trackingStartedAt: Date
    public let appSettings: AppSettings
    public let itemInventory: [String: Int]
    /// Each individual's busiest recorded day, for its journal.
    public let busiestDays: [UUID: UsageRecordDay]
    /// Eggs warming, oldest first.
    public let incubator: [IncubatingEgg]
}

public enum OnboardingStoreError: Error, Equatable {
    case alreadyCompleted
    case emptyName
}

public enum EvolutionStoreError: Error, Equatable {
    case noCurrentAnimal
    case invalidStage
}

public enum CompanionSwitchError: Error, Equatable {
    case noSuchCompanion
    case alreadyGrowing
    case graduated
    case emptyName
}

public enum CompanionRenameError: Error, Equatable {
    case noSuchCompanion
    case notWaiting
    case emptyName
}

public enum IncubatorStoreError: Error, Equatable {
    case noEggToPlace
    case full
    case noSuchEgg
    case notReady
}

public enum GraduationStoreError: Error, Equatable {
    case noCurrentAnimal
    case currentAnimalNotFinal
    case emptyName
    case requiredItemUnavailable
}

public enum GameShopStoreError: Error, Equatable {
    case insufficientCoins
    case noCurrentAnimal
    case invalidItem
    case alreadyOwned
    case unchangedNature
    case dailyLimitReached
    case nothingToAbsorb
}

public actor EvoBarStore {
    private let fileURL: URL?
    private var state: PersistenceState

    public init(fileURL: URL? = EvoBarStore.defaultStoreURL()) throws {
        self.fileURL = fileURL
        if let fileURL, FileManager.default.fileExists(atPath: fileURL.path) {
            let decoder = JSONDecoder()
            do {
                self.state = try decoder.decode(
                    PersistenceState.self,
                    from: Data(contentsOf: fileURL)
                )
            } catch {
                let primaryError = error
                let backupURL = Self.backupURL(for: fileURL)
                guard FileManager.default.fileExists(atPath: backupURL.path) else {
                    throw primaryError
                }
                let backupData = try Data(contentsOf: backupURL)
                self.state = try decoder.decode(PersistenceState.self, from: backupData)
                try backupData.write(to: fileURL, options: .atomic)
                try Self.hardenPermissions(for: backupURL)
            }
            try Self.hardenPermissions(for: fileURL)
            let backupURL = Self.backupURL(for: fileURL)
            if FileManager.default.fileExists(atPath: backupURL.path) {
                try Self.hardenPermissions(for: backupURL)
            }
        } else {
            self.state = PersistenceState()
        }
    }

    public static func defaultStoreURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base
            .appendingPathComponent("com.evobar.app", isDirectory: true)
            .appendingPathComponent("EvoBar-v1.json")
    }

    public func checkpoint(for sourceKey: String) -> SourceCheckpoint? {
        guard let record = state.checkpoints[sourceKey] else { return nil }
        return SourceCheckpoint(
            byteOffset: record.byteOffset,
            fileSize: record.fileSize,
            generation: record.generation,
            sessionID: record.sessionID,
            modelID: record.modelID
        )
    }

    public func saveBaseline(
        sourceKey: String,
        providerID: ProviderID,
        checkpoint: SourceCheckpoint
    ) throws {
        state.checkpoints[sourceKey] = PersistedCheckpoint(
            providerID: providerID,
            byteOffset: checkpoint.byteOffset,
            fileSize: checkpoint.fileSize,
            generation: checkpoint.generation,
            sessionID: checkpoint.sessionID,
            modelID: checkpoint.modelID,
            updatedAt: Date()
        )
        try persist()
    }

    @discardableResult
    public func completeOnboarding(
        starterID: AnimalDefinitionID,
        companionName: String,
        natureID: String = "curious",
        startedAt: Date = Date()
    ) throws -> AnimalInstance {
        let previous = state
        var committed = false
        defer { if !committed { state = previous } }
        guard !state.settings.onboardingCompleted else {
            throw OnboardingStoreError.alreadyCompleted
        }
        let name = companionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw OnboardingStoreError.emptyName }

        let instance = AnimalInstance(
            definitionID: starterID,
            name: name,
            createdAt: startedAt,
            isCurrent: true,
            natureID: natureID,
            rarity: .common
        )
        state.animalInstances[instance.id.uuidString] = instance
        state.settings.currentAnimalInstanceID = instance.id
        state.settings.starterGrantID = starterID.rawValue
        state.settings.onboardingCompleted = true
        state.settings.trackingStartedAt = startedAt
        try persist()
        committed = true
        return instance
    }

    @discardableResult
    public func graduateCurrentAndStart(
        definitionID: AnimalDefinitionID,
        name: String,
        natureID: String,
        rarity: AnimalRarity,
        isShiny: Bool,
        finalStageIndex: Int,
        consumingItemID: String? = nil,
        at date: Date = Date()
    ) throws -> AnimalInstance {
        let previous = state
        var committed = false
        defer { if !committed { state = previous } }
        guard let currentID = state.settings.currentAnimalInstanceID,
              var current = state.animalInstances[currentID.uuidString] else {
            throw GraduationStoreError.noCurrentAnimal
        }
        guard current.acknowledgedStageIndex == finalStageIndex else {
            throw GraduationStoreError.currentAnimalNotFinal
        }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw GraduationStoreError.emptyName }
        if let consumingItemID {
            let count = state.settings.itemInventory[consumingItemID] ?? 0
            guard count > 0 else { throw GraduationStoreError.requiredItemUnavailable }
            if count == 1 {
                state.settings.itemInventory[consumingItemID] = nil
            } else {
                state.settings.itemInventory[consumingItemID] = count - 1
            }
        }

        current.isCurrent = false
        current.graduatedAt = date
        state.animalInstances[currentID.uuidString] = current

        let next = AnimalInstance(
            definitionID: definitionID,
            name: trimmedName,
            createdAt: date,
            isCurrent: true,
            isShiny: isShiny,
            natureID: natureID,
            rarity: rarity
        )
        state.animalInstances[next.id.uuidString] = next
        state.settings.currentAnimalInstanceID = next.id
        try persist()
        committed = true
        return next
    }

    public func updateActiveProductIDs(_ productIDs: Set<ProductID>) throws {
        state.settings.activeProductIDs = productIDs
        try persist()
    }

    /// Applies entitlements from a trusted purchase verifier and repairs any current-companion
    /// reference that is no longer authorized. Historical animal records are never deleted.
    /// Catalog retirement preserves historical companions and purchase records.
    /// Only a removed current companion is replaced, using the original free starter.
    public func reconcileCatalogRetirement(
        availableAnimalIDs: Set<AnimalDefinitionID>,
        starterIDs: Set<AnimalDefinitionID>
    ) throws {
        if let pinnedID = state.settings.appSettings.pinnedAnimalDefinitionID,
           !availableAnimalIDs.contains(AnimalDefinitionID(rawValue: pinnedID)) {
            let previous = state
            state.settings.appSettings.pinnedAnimalDefinitionID = nil
            do { try persist() }
            catch { state = previous; throw error }
        }
        guard let currentID = state.settings.currentAnimalInstanceID,
              let current = state.animalInstances[currentID.uuidString],
              !availableAnimalIDs.contains(current.definitionID) else { return }
        guard let rawStarter = state.settings.starterGrantID,
              starterIDs.contains(AnimalDefinitionID(rawValue: rawStarter)),
              availableAnimalIDs.contains(AnimalDefinitionID(rawValue: rawStarter)) else {
            throw EvolutionStoreError.noCurrentAnimal
        }
        let previous = state
        do {
            try reconcileVerifiedOwnership(
                activeProductIDs: state.settings.activeProductIDs,
                ownedAnimalIDs: [AnimalDefinitionID(rawValue: rawStarter)],
                validStarterGrantID: AnimalDefinitionID(rawValue: rawStarter)
            )
        } catch {
            state = previous
            throw error
        }
    }

    public func reconcileVerifiedOwnership(
        activeProductIDs: Set<ProductID>,
        ownedAnimalIDs: Set<AnimalDefinitionID>,
        validStarterGrantID: AnimalDefinitionID?,
        at date: Date = Date()
    ) throws {
        state.settings.activeProductIDs = activeProductIDs
        state.settings.starterGrantID = validStarterGrantID?.rawValue

        if let pinnedID = state.settings.appSettings.pinnedAnimalDefinitionID,
           !ownedAnimalIDs.contains(AnimalDefinitionID(rawValue: pinnedID)) {
            state.settings.appSettings.pinnedAnimalDefinitionID = nil
        }

        guard state.settings.onboardingCompleted else {
            try persist()
            return
        }

        let currentID = state.settings.currentAnimalInstanceID
        let current = currentID.flatMap { state.animalInstances[$0.uuidString] }
        if let current, ownedAnimalIDs.contains(current.definitionID) {
            normalizeCurrentInstance(current.id)
            try persist()
            return
        }

        normalizeCurrentInstance(nil)
        let ownedInstances = state.animalInstances.values
            .filter { ownedAnimalIDs.contains($0.definitionID) }
            .sorted(by: Self.isOlderInstance)

        if var existing = ownedInstances.last(where: { $0.graduatedAt == nil }) {
            existing.isCurrent = true
            state.animalInstances[existing.id.uuidString] = existing
            state.settings.currentAnimalInstanceID = existing.id
        } else if let historical = ownedInstances.last {
            let replacement = AnimalInstance(
                definitionID: historical.definitionID,
                name: historical.name,
                createdAt: date,
                isCurrent: true,
                isShiny: historical.isShiny,
                natureID: historical.natureID,
                rarity: historical.rarity
            )
            state.animalInstances[replacement.id.uuidString] = replacement
            state.settings.currentAnimalInstanceID = replacement.id
        } else {
            state.settings.onboardingCompleted = false
            state.settings.currentAnimalInstanceID = nil
            state.settings.starterGrantID = nil
        }
        try persist()
    }

    public func updateAppSettings(_ appSettings: AppSettings) throws {
        state.settings.appSettings = appSettings
        try persist()
    }

    public func purchaseGameItem(
        _ item: GameItemDefinition,
        replacementNatureID: String? = nil,
        chargeCoins: Bool = true,
        candyRoll: Double? = nil
    ) throws {
        let previous = state
        var committed = false
        defer { if !committed { state = previous } }
        guard !chargeCoins || state.settings.tokenCoins >= item.tokenCoinPrice else {
            throw GameShopStoreError.insufficientCoins
        }
        guard let instanceID = state.settings.currentAnimalInstanceID,
              var instance = state.animalInstances[instanceID.uuidString] else {
            throw GameShopStoreError.noCurrentAnimal
        }

        switch item.kind {
        case .rareCandy:
            guard let xpGrant = item.xpGrant, xpGrant > 0 else {
                throw GameShopStoreError.invalidItem
            }
            // Worth about its listed XP, a little more or less, and it arrives
            // with the rest of the growth the next time Home is open.
            let grant = GrowthBonusEngine.candyGrant(
                mean: xpGrant, roll: candyRoll ?? Double.random(in: 0..<1))
            instance.pendingXP = saturatingAdd(instance.pendingXP, grant)
            state.animalInstances[instanceID.uuidString] = instance
        case .mint:
            guard let replacementNatureID, replacementNatureID != instance.natureID else {
                throw GameShopStoreError.unchangedNature
            }
            instance.natureID = replacementNatureID
            state.animalInstances[instanceID.uuidString] = instance
        case .shinyCharm:
            guard (state.settings.itemInventory[item.id] ?? 0) == 0 else {
                throw GameShopStoreError.alreadyOwned
            }
            state.settings.itemInventory[item.id] = 1
        case .randomEgg:
            state.settings.itemInventory[item.id, default: 0] += 1
        case .sceneTheme:
            guard (state.settings.itemInventory[item.id] ?? 0) == 0 else {
                throw GameShopStoreError.alreadyOwned
            }
            state.settings.itemInventory[item.id] = 1
            // Bought is worn; a backdrop nobody put on is a backdrop nobody sees.
            state.settings.appSettings.sceneThemeID = item.id
        case .treat:
            let today = dayKey(for: Date(), timeZoneID: state.settings.growthTimeZoneID)
            var care = resetCareCountsIfNeeded(instance, dayKey: today)
            guard care.treatsOnCareDay < AffectionEngine.maxTreatsPerDay else {
                throw GameShopStoreError.dailyLimitReached
            }
            care.treatsOnCareDay += 1
            care.careCount += 1
            care.affectionPoints = AffectionEngine.afterTreat(points:
                AffectionEngine.currentPoints(
                    stored: care.affectionPoints,
                    updatedAt: care.affectionUpdatedAt
                )
            )
            care.affectionUpdatedAt = Date()
            state.animalInstances[instanceID.uuidString] = notingAdoration(care, now: Date())
        }
        if chargeCoins { state.settings.tokenCoins -= item.tokenCoinPrice }
        try persist()
        committed = true
    }

    /// Takes in every XP point that has arrived since the last time, rolls the
    /// growth bonus on it, and counts the first arrival of a growth day as care.
    /// Nothing here can lower what the work earned: the roll only ever adds.
    @discardableResult
    public func absorbPendingXP(
        now: Date = Date(),
        bonusRoll: Double? = nil,
        giftCoinRoll: Double? = nil,
        giftItemRoll: Double? = nil,
        giftCandyXP: Int64 = 60
    ) throws -> GrowthAbsorption {
        let previous = state
        var committed = false
        defer { if !committed { state = previous } }
        guard let instanceID = state.settings.currentAnimalInstanceID,
              let instance = state.animalInstances[instanceID.uuidString] else {
            throw GameShopStoreError.noCurrentAnimal
        }
        guard instance.pendingXP > 0 else { throw GameShopStoreError.nothingToAbsorb }
        var absorbed = GrowthBonusEngine.absorption(
            of: instance.pendingXP, roll: bonusRoll ?? Double.random(in: 0..<1))
        let today = dayKey(for: now, timeZoneID: state.settings.growthTimeZoneID)
        var updated = resetCareCountsIfNeeded(instance, dayKey: today)
        if state.settings.lastGiftDayKey != today {
            // One draw a day, for the day and not for the companion, so
            // swapping who grows cannot collect it twice.
            state.settings.lastGiftDayKey = today
            absorbed = absorbed.with(gift: DailyGiftEngine.gift(
                coinRoll: giftCoinRoll ?? Double.random(in: 0..<1),
                itemRoll: giftItemRoll ?? Double.random(in: 0..<1),
                candyXP: giftCandyXP
            ))
        }
        updated.pendingXP = 0
        updated.currentXP = saturatingAdd(updated.currentXP, absorbed.total)
        if updated.firstGrowthAt == nil { updated.firstGrowthAt = now }
        if absorbed.tier == .golden, updated.firstGoldenAt == nil { updated.firstGoldenAt = now }
        if let gift = absorbed.gift, gift.eggs > 0 {
            state.settings.itemInventory["random-egg", default: 0] += gift.eggs
        }
        if !updated.absorbedOnCareDay {
            // Growing together is care too, once a day, the way a meal used to be.
            updated.absorbedOnCareDay = true
            updated.careCount += 1
            updated.affectionPoints = AffectionEngine.afterPetting(
                points: AffectionEngine.currentPoints(
                    stored: updated.affectionPoints,
                    updatedAt: updated.affectionUpdatedAt,
                    now: now
                )
            )
            updated.affectionUpdatedAt = now
        }
        state.animalInstances[instanceID.uuidString] = notingAdoration(updated, now: now)
        state.settings.tokenCoins = saturatingAdd(
            state.settings.tokenCoins, absorbed.coins + (absorbed.gift?.coins ?? 0))
        try persist()
        committed = true
        return absorbed
    }

    /// Puts one Random Egg into the incubator, where it warms on working days.
    @discardableResult
    public func placeEggInIncubator(at date: Date = Date()) throws -> IncubatingEgg {
        guard state.settings.incubator.count < IncubatingEgg.capacity else {
            throw IncubatorStoreError.full
        }
        let held = state.settings.itemInventory["random-egg"] ?? 0
        guard held > 0 else { throw IncubatorStoreError.noEggToPlace }
        let previous = state
        if held == 1 {
            state.settings.itemInventory["random-egg"] = nil
        } else {
            state.settings.itemInventory["random-egg"] = held - 1
        }
        let egg = IncubatingEgg(placedAt: date)
        state.settings.incubator.append(egg)
        do { try persist() } catch { state = previous; throw error }
        return egg
    }

    /// Opens a ready egg into a companion that waits to be raised. The draw
    /// happens above this, where the catalog lives; this only records it.
    public func hatchEgg(
        id: UUID,
        definitionID: AnimalDefinitionID,
        name: String,
        natureID: String,
        rarity: AnimalRarity,
        isShiny: Bool,
        at date: Date = Date()
    ) throws -> AnimalInstance {
        guard let index = state.settings.incubator.firstIndex(where: { $0.id == id }) else {
            throw IncubatorStoreError.noSuchEgg
        }
        guard state.settings.incubator[index].isReady else { throw IncubatorStoreError.notReady }
        let previous = state
        state.settings.incubator.remove(at: index)
        let hatched = AnimalInstance(
            definitionID: definitionID,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: date,
            isCurrent: false,
            isShiny: isShiny,
            natureID: natureID,
            rarity: rarity
        )
        state.animalInstances[hatched.id.uuidString] = hatched
        do { try persist() } catch { state = previous; throw error }
        return hatched
    }

    /// A hatch can be named before it is raised. This changes only that
    /// individual's record; the current companion and its growth stay put.
    @discardableResult
    public func renameWaitingCompanion(id: UUID, name: String) throws -> AnimalInstance {
        guard var companion = state.animalInstances[id.uuidString] else {
            throw CompanionRenameError.noSuchCompanion
        }
        guard companion.isWaitingToBeRaised else { throw CompanionRenameError.notWaiting }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CompanionRenameError.emptyName }
        let previous = state
        companion.name = String(trimmed.prefix(24))
        state.animalInstances[id.uuidString] = companion
        do { try persist() } catch { state = previous; throw error }
        return companion
    }

    /// Puts the companion that is growing to one side and raises another in its
    /// place. Nothing is spent and nothing is lost: the one set aside keeps its
    /// stage, its XP, its bond and its journal, and can be picked up again.
    /// Graduation stays what it was, the retirement of a companion that
    /// finished; this is only which one grows today.
    @discardableResult
    public func switchCurrentCompanion(
        to instanceID: UUID,
        name: String? = nil,
        at date: Date = Date()
    ) throws -> AnimalInstance {
        let previous = state
        var committed = false
        defer { if !committed { state = previous } }
        guard var next = state.animalInstances[instanceID.uuidString] else {
            throw CompanionSwitchError.noSuchCompanion
        }
        guard !next.isCurrent else { throw CompanionSwitchError.alreadyGrowing }
        guard next.graduatedAt == nil else { throw CompanionSwitchError.graduated }
        if let name {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { throw CompanionSwitchError.emptyName }
            next.name = trimmed
        }
        // The one stepping aside keeps everything, including any growth it
        // earned and has not taken in; that waits for it to come back.
        if let currentID = state.settings.currentAnimalInstanceID,
           var current = state.animalInstances[currentID.uuidString] {
            current.isCurrent = false
            state.animalInstances[currentID.uuidString] = current
        }
        next.isCurrent = true
        next.lastActivityAt = next.lastActivityAt ?? date
        state.animalInstances[instanceID.uuidString] = next
        state.settings.currentAnimalInstanceID = next.id
        try persist()
        committed = true
        return next
    }

    /// Graduates the companion that finished and raises one that was waiting.
    @discardableResult
    public func graduateCurrentAndAdopt(
        instanceID: UUID,
        name: String,
        finalStageIndex: Int,
        at date: Date = Date()
    ) throws -> AnimalInstance {
        let previous = state
        var committed = false
        defer { if !committed { state = previous } }
        guard let currentID = state.settings.currentAnimalInstanceID,
              var current = state.animalInstances[currentID.uuidString] else {
            throw GraduationStoreError.noCurrentAnimal
        }
        guard current.acknowledgedStageIndex == finalStageIndex else {
            throw GraduationStoreError.currentAnimalNotFinal
        }
        guard var adopted = state.animalInstances[instanceID.uuidString],
              adopted.isWaitingToBeRaised else {
            throw GraduationStoreError.noCurrentAnimal
        }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw GraduationStoreError.emptyName }

        current.isCurrent = false
        current.graduatedAt = date
        state.animalInstances[currentID.uuidString] = current

        adopted.name = trimmedName
        adopted.isCurrent = true
        state.animalInstances[instanceID.uuidString] = adopted
        state.settings.currentAnimalInstanceID = adopted.id
        try persist()
        committed = true
        return adopted
    }

    /// Petting is free and capped per growth day.
    public func petCurrentAnimal(now: Date = Date()) throws {
        let previous = state
        var committed = false
        defer { if !committed { state = previous } }
        guard let instanceID = state.settings.currentAnimalInstanceID,
              let instance = state.animalInstances[instanceID.uuidString] else {
            throw GameShopStoreError.noCurrentAnimal
        }
        let today = dayKey(for: now, timeZoneID: state.settings.growthTimeZoneID)
        var care = resetCareCountsIfNeeded(instance, dayKey: today)
        guard care.petsOnCareDay < AffectionEngine.maxPetsPerDay else {
            throw GameShopStoreError.dailyLimitReached
        }
        care.petsOnCareDay += 1
        care.careCount += 1
        care.affectionPoints = AffectionEngine.afterPetting(points:
            AffectionEngine.currentPoints(
                stored: care.affectionPoints,
                updatedAt: care.affectionUpdatedAt,
                now: now
            )
        )
        care.affectionUpdatedAt = now
        state.animalInstances[instanceID.uuidString] = notingAdoration(care, now: now)
        try persist()
        committed = true
    }

    /// Notes the first time affection reaches its top band, for the journal.
    private func notingAdoration(_ instance: AnimalInstance, now: Date) -> AnimalInstance {
        guard instance.adoringAt == nil,
              AffectionEngine.mood(for: instance.affectionPoints) == .adoring else { return instance }
        var noted = instance
        noted.adoringAt = now
        return noted
    }

    /// Zeroes the per-day counters when the growth day rolled over.
    private func resetCareCountsIfNeeded(_ instance: AnimalInstance, dayKey: String) -> AnimalInstance {
        guard instance.careDayKey != dayKey else { return instance }
        var updated = instance
        updated.careDayKey = dayKey
        updated.petsOnCareDay = 0
        updated.treatsOnCareDay = 0
        updated.absorbedOnCareDay = false
        return updated
    }

    public func exportData(at date: Date = Date()) throws -> Data {
        let export = EvoBarDataExport(
            formatVersion: 1,
            exportedAt: date,
            animals: orderedAnimalInstances,
            dailyUsage: state.dailyAggregates.map { key, value in
                ExportedDailyUsage(
                    dayKey: key,
                    rawTokens: value.rawTokens,
                    effectiveTokens: value.effectiveTokens,
                    awardedXP: value.awardedXP,
                    awardedTokenCoins: value.awardedTokenCoins
                )
            }.sorted { $0.dayKey < $1.dayKey },
            tokenCoins: state.settings.tokenCoins,
            itemInventory: state.settings.itemInventory,
            appSettings: ExportedAppPreferences(state.settings.appSettings)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(export)
    }

    public func acknowledgeEvolution(
        to stageIndex: Int,
        finalStageIndex: Int,
        evolvedAt: Date = Date()
    ) throws {
        let previous = state
        var committed = false
        defer { if !committed { state = previous } }
        guard let instanceID = state.settings.currentAnimalInstanceID,
              var instance = state.animalInstances[instanceID.uuidString] else {
            throw EvolutionStoreError.noCurrentAnimal
        }
        guard stageIndex == instance.acknowledgedStageIndex + 1,
              stageIndex <= finalStageIndex else {
            throw EvolutionStoreError.invalidStage
        }
        instance.acknowledgedStageIndex = stageIndex
        instance.evolutionDates[stageIndex] = evolvedAt
        if stageIndex == finalStageIndex, instance.finalEvolutionAt == nil {
            instance.finalEvolutionAt = evolvedAt
        }
        state.animalInstances[instanceID.uuidString] = instance
        try persist()
        committed = true
    }

    public func resetAllData() throws {
        state = PersistenceState()
        try persist(preservePreviousState: false)
    }

    @discardableResult
    public func ingest(
        batch: ScanBatch,
        sourceKey: String,
        providerID: ProviderID,
        effectiveTokensPerCoin: Int64,
        eventCutoff: Date? = nil
    ) throws -> Int {
        // A failed disk write must not advance the in-memory ledger/checkpoint.
        // Otherwise a retry could skip usage that was never durably saved.
        let previous = state
        var committed = false
        defer { if !committed { state = previous } }
        var insertedCount = 0
        for event in batch.events where eventCutoff.map({ event.timestamp >= $0 }) ?? true {
            guard state.events[event.stableID.rawValue] == nil else { continue }
            let key = dayKey(for: event.timestamp, timeZoneID: state.settings.growthTimeZoneID)
            var aggregate: PersistedDailyAggregate
            if let existing = state.dailyAggregates[key] {
                aggregate = existing
            } else {
                aggregate = PersistedDailyAggregate()
                aggregate.growthCacheReadTokens = 0
                aggregate.xpCurve = .balanced
            }
            aggregate.rawTokens = saturatingAdd(aggregate.rawTokens, event.usage.totalTokens)
            if let previousCache = aggregate.growthCacheReadTokens {
                let cacheRead = min(event.usage.totalTokens, event.usage.cacheReadTokens)
                aggregate.growthCacheReadTokens = saturatingAdd(previousCache, cacheRead)
            }
            var ledger = DailyGrowthLedger(
                rawTokens: aggregate.rawTokens,
                effectiveTokens: aggregate.effectiveTokens,
                awardedXP: aggregate.awardedXP,
                awardedTokenCoins: aggregate.awardedTokenCoins
            )
            let award = ledger.recompute(
                rawTokens: aggregate.rawTokens,
                cacheReadTokens: aggregate.growthCacheReadTokens,
                effectiveTokensPerCoin: effectiveTokensPerCoin,
                xpCurve: aggregate.xpCurve ?? .legacy
            )
            aggregate.effectiveTokens = ledger.effectiveTokens
            aggregate.awardedXP = ledger.awardedXP
            aggregate.awardedTokenCoins = ledger.awardedTokenCoins
            if let currentID = state.settings.currentAnimalInstanceID {
                aggregate.awardedXPByAnimal[currentID.uuidString] = saturatingAdd(
                    aggregate.awardedXPByAnimal[currentID.uuidString] ?? 0,
                    award.xpDelta
                )
                aggregate.tokensByAnimal[currentID.uuidString] = saturatingAdd(
                    aggregate.tokensByAnimal[currentID.uuidString] ?? 0,
                    event.usage.totalTokens
                )
            }
            state.dailyAggregates[key] = aggregate
            state.settings.tokenCoins = saturatingAdd(state.settings.tokenCoins, award.tokenCoinDelta)
            creditCurrentAnimal(event: event, xpDelta: award.xpDelta)
            state.events[event.stableID.rawValue] = PersistedUsageEvent(event: event, dayKey: key)
            // An egg warms on a day its owner worked, whatever hour it was.
            for index in state.settings.incubator.indices {
                if event.timestamp >= state.settings.incubator[index].placedAt,
                   event.usage.totalTokens > 0 {
                    state.settings.incubator[index].count(dayKey: key)
                }
            }
            insertedCount += 1
        }

        state.checkpoints[sourceKey] = PersistedCheckpoint(
            providerID: providerID,
            byteOffset: batch.checkpoint.byteOffset,
            fileSize: batch.checkpoint.fileSize,
            generation: batch.checkpoint.generation,
            sessionID: batch.checkpoint.sessionID,
            modelID: batch.checkpoint.modelID,
            updatedAt: Date()
        )
        try persist()
        committed = true
        return insertedCount
    }

    private var orderedAnimalInstances: [AnimalInstance] {
        state.animalInstances.values.sorted(by: Self.isOlderInstance)
    }

    public func snapshot(now: Date = Date()) -> PersistedAppSnapshot {
        let settings = state.settings
        let key = dayKey(for: now, timeZoneID: settings.growthTimeZoneID)
        let today = state.dailyAggregates[key] ?? PersistedDailyAggregate()
        let current = settings.currentAnimalInstanceID.flatMap {
            state.animalInstances[$0.uuidString]
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: settings.growthTimeZoneID) ?? .current
        var busiestDays: [UUID: UsageRecordDay] = [:]
        for (aggregateKey, aggregate) in state.dailyAggregates {
            guard let date = date(fromDayKey: aggregateKey, timeZoneID: settings.growthTimeZoneID) else { continue }
            for (instanceKey, tokens) in aggregate.tokensByAnimal {
                guard let id = UUID(uuidString: instanceKey), tokens > (busiestDays[id]?.tokens ?? 0) else { continue }
                busiestDays[id] = UsageRecordDay(date: date, tokens: tokens)
            }
        }
        return PersistedAppSnapshot(
            onboardingCompleted: settings.onboardingCompleted,
            currentAnimalInstanceID: current?.id,
            companionName: current?.name ?? "",
            currentAnimalID: current?.definitionID ?? "cat",
            currentXP: current?.currentXP ?? 0,
            animalInstances: orderedAnimalInstances,
            starterGrantID: settings.starterGrantID.map(AnimalDefinitionID.init(rawValue:)),
            activeProductIDs: settings.activeProductIDs,
            tokenCoins: settings.tokenCoins,
            todayTokens: today.rawTokens,
            todayXP: current.map { today.awardedXPByAnimal[$0.id.uuidString] ?? 0 } ?? 0,
            dailyRawTokens: state.dailyAggregates
                .filter { $0.key != key }
                .sorted { $0.key > $1.key }
                .prefix(30)
                .map(\.value.rawTokens),
            weekRawTokens: (0..<7).reversed().map { daysAgo in
                let day = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
                return state.dailyAggregates[dayKey(for: day, timeZoneID: settings.growthTimeZoneID)]?.rawTokens ?? 0
            },
            pendingXP: current?.pendingXP ?? 0,
            affectionPoints: current.map {
                AffectionEngine.currentPoints(
                    stored: $0.affectionPoints,
                    updatedAt: $0.affectionUpdatedAt,
                    now: now
                )
            } ?? AffectionEngine.starting,
            careCount: current?.careCount ?? 0,
            petsRemainingToday: current.map {
                $0.careDayKey == key
                    ? max(0, AffectionEngine.maxPetsPerDay - $0.petsOnCareDay)
                    : AffectionEngine.maxPetsPerDay
            } ?? AffectionEngine.maxPetsPerDay,
            treatsRemainingToday: current.map {
                $0.careDayKey == key
                    ? max(0, AffectionEngine.maxTreatsPerDay - $0.treatsOnCareDay)
                    : AffectionEngine.maxTreatsPerDay
            } ?? AffectionEngine.maxTreatsPerDay,
            growthTimeZoneID: settings.growthTimeZoneID,
            trackingStartedAt: settings.trackingStartedAt,
            appSettings: settings.appSettings,
            itemInventory: settings.itemInventory,
            busiestDays: busiestDays,
            incubator: settings.incubator.sorted { $0.placedAt < $1.placedAt }
        )
    }


    public func usageDashboard(
        now: Date = Date(),
        pricing: ModelPricingManifest? = nil
    ) -> UsageDashboardSnapshot {
        let timeZoneID = state.settings.growthTimeZoneID
        let timeZone = TimeZone(identifier: timeZoneID) ?? .current
        let intervals = usageIntervals(now: now, timeZoneID: timeZoneID)
        let windows = UsageWindowKind.allCases.compactMap { kind -> UsageWindowSnapshot? in
            guard let interval = intervals[kind] else { return nil }
            var total = TokenAccumulator()
            var allSessions = Set<String>()
            var providerBuckets: [ProviderID: TokenAccumulator] = [:]
            var providerSessions: [ProviderID: Set<String>] = [:]
            var modelBuckets: [ProviderID: [String: TokenAccumulator]] = [:]
            var totalCost = CostAccumulator()
            var providerCosts: [ProviderID: CostAccumulator] = [:]
            var modelCosts: [ProviderID: [String: CostAccumulator]] = [:]
            var samples: [UsageStoryEngine.Sample] = []

            for event in state.events.values
            where event.timestamp >= interval.start && event.timestamp <= interval.end {
                total.add(event.usage)
                let sessionKey = "\(event.providerID.rawValue)|\(event.sessionID)"
                allSessions.insert(sessionKey)
                samples.append(UsageStoryEngine.Sample(
                    session: sessionKey, timestamp: event.timestamp, tokens: event.usage.totalTokens))
                providerBuckets[event.providerID, default: TokenAccumulator()].add(event.usage)
                providerSessions[event.providerID, default: []].insert(event.sessionID)
                let modelID = event.modelID?.trimmingCharacters(in: .whitespacesAndNewlines)
                let normalizedModelID = modelID?.isEmpty == false ? modelID! : "Unknown model"
                modelBuckets[event.providerID, default: [:]][normalizedModelID, default: TokenAccumulator()]
                    .add(event.usage)
                let estimate = pricing.map {
                    UsageCostEngine.estimate(
                        usage: event.usage,
                        providerID: event.providerID,
                        modelID: event.modelID,
                        manifest: $0
                    )
                } ?? UsageCostEstimate(
                    amountUSD: 0,
                    pricedTokens: 0,
                    unpricedTokens: event.usage.totalTokens
                )
                totalCost.add(estimate)
                providerCosts[event.providerID, default: CostAccumulator()].add(estimate)
                modelCosts[event.providerID, default: [:]][normalizedModelID, default: CostAccumulator()]
                    .add(estimate)
            }

            let providers = providerBuckets.map { providerID, accumulator in
                ProviderUsageBreakdown(
                    providerID: providerID,
                    usage: accumulator.value,
                    sessionCount: providerSessions[providerID]?.count ?? 0,
                    estimatedAPICostUSD: providerCosts[providerID]?.amountOrNil,
                    costCoverage: providerCosts[providerID]?.coverage ?? 0
                )
            }.sorted { $0.providerID.rawValue < $1.providerID.rawValue }

            let models = modelBuckets.flatMap { providerID, buckets in
                buckets.map { modelID, accumulator in
                    ModelUsageBreakdown(
                        providerID: providerID,
                        modelID: modelID,
                        usage: accumulator.value,
                        estimatedAPICostUSD: modelCosts[providerID]?[modelID]?.amountOrNil,
                        costCoverage: modelCosts[providerID]?[modelID]?.coverage ?? 0
                    )
                }
            }.sorted {
                if $0.usage.totalTokens != $1.usage.totalTokens {
                    return $0.usage.totalTokens > $1.usage.totalTokens
                }
                if $0.providerID != $1.providerID {
                    return $0.providerID.rawValue < $1.providerID.rawValue
                }
                return $0.modelID < $1.modelID
            }

            return UsageWindowSnapshot(
                kind: kind,
                interval: interval,
                usage: total.value,
                sessionCount: allSessions.count,
                providers: providers,
                models: models,
                estimatedAPICostUSD: totalCost.amountOrNil,
                costCoverage: totalCost.coverage,
                story: UsageStoryEngine.story(samples, timeZone: timeZone)
            )
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        func tokens(on day: Date) -> Int64 {
            state.dailyAggregates[dayKey(for: day, timeZoneID: timeZoneID)]?.rawTokens ?? 0
        }
        func dayBefore(_ day: Date) -> Date { calendar.date(byAdding: .day, value: -1, to: day) ?? day }
        // Days in a row with usage, counted back from today, or from yesterday
        // while today is still empty, so a streak is not broken by a morning.
        var streak = 0
        var day = tokens(on: now) > 0 ? now : dayBefore(now)
        while tokens(on: day) > 0 {
            streak += 1
            let earlier = dayBefore(day)
            guard earlier < day else { break }
            day = earlier
        }
        let best = state.dailyAggregates
            .filter { $0.value.rawTokens > 0 }
            .max { lhs, rhs in
                lhs.value.rawTokens != rhs.value.rawTokens
                    ? lhs.value.rawTokens < rhs.value.rawTokens
                    : lhs.key < rhs.key
            }
            .flatMap { entry in
                date(fromDayKey: entry.key, timeZoneID: timeZoneID)
                    .map { UsageRecordDay(date: $0, tokens: entry.value.rawTokens) }
            }
        return UsageDashboardSnapshot(
            generatedAt: now,
            windows: windows,
            streakDays: streak,
            bestDay: best,
            yesterdayTokens: tokens(on: dayBefore(now))
        )
    }

    private func creditCurrentAnimal(event: UsageEvent, xpDelta: Int64) {
        guard state.settings.onboardingCompleted,
              let instanceID = state.settings.currentAnimalInstanceID,
              var instance = state.animalInstances[instanceID.uuidString] else { return }
        // XP waits here until the Home tab is on screen, so its arrival is always seen.
        instance.pendingXP = saturatingAdd(instance.pendingXP, xpDelta)
        instance.cumulativeTokens = saturatingAdd(instance.cumulativeTokens, event.usage.totalTokens)
        instance.providerTokens[event.provider] = saturatingAdd(
            instance.providerTokens[event.provider] ?? 0,
            event.usage.totalTokens
        )
        instance.lastActivityAt = max(instance.lastActivityAt ?? .distantPast, event.timestamp)
        state.animalInstances[instanceID.uuidString] = instance
    }

    private func normalizeCurrentInstance(_ currentID: UUID?) {
        for key in Array(state.animalInstances.keys) {
            guard var instance = state.animalInstances[key] else { continue }
            let shouldBeCurrent = instance.id == currentID
            guard instance.isCurrent != shouldBeCurrent else { continue }
            instance.isCurrent = shouldBeCurrent
            state.animalInstances[key] = instance
        }
        state.settings.currentAnimalInstanceID = currentID
    }

    private static func isOlderInstance(_ lhs: AnimalInstance, _ rhs: AnimalInstance) -> Bool {
        if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    private func persist(preservePreviousState: Bool = true) throws {
        guard let fileURL else { return }
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encodedState = try encoder.encode(state)
        let backupURL = Self.backupURL(for: fileURL)

        if preservePreviousState,
           FileManager.default.fileExists(atPath: fileURL.path) {
            let previousState = try Data(contentsOf: fileURL)
            if (try? JSONDecoder().decode(PersistenceState.self, from: previousState)) != nil {
                try previousState.write(to: backupURL, options: .atomic)
                try Self.hardenPermissions(for: backupURL)
            }
        }

        try encodedState.write(to: fileURL, options: .atomic)
        try Self.hardenPermissions(for: fileURL)
        if !preservePreviousState {
            try encodedState.write(to: backupURL, options: .atomic)
            try Self.hardenPermissions(for: backupURL)
        }
    }

    private static func backupURL(for fileURL: URL) -> URL {
        fileURL.appendingPathExtension("backup")
    }

    private static func hardenPermissions(for fileURL: URL) throws {
        let fileManager = FileManager.default
        try fileManager.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o700))],
            ofItemAtPath: fileURL.deletingLastPathComponent().path
        )
        try fileManager.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o600))],
            ofItemAtPath: fileURL.path
        )
    }

    private func dayKey(for date: Date, timeZoneID: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: timeZoneID) ?? .current
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(timeZoneID)|\(formatter.string(from: date))"
    }

    /// The start of the day a key names, in the zone given; a key written in
    /// another zone still resolves to the right calendar day.
    private func date(fromDayKey key: String, timeZoneID: String) -> Date? {
        guard let dayPart = key.split(separator: "|").last else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: timeZoneID) ?? .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: String(dayPart))
    }

    private func usageIntervals(
        now: Date,
        timeZoneID: String
    ) -> [UsageWindowKind: DateInterval] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneID) ?? .current
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        let today = calendar.startOfDay(for: now)
        let week = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? today
        let month = calendar.dateInterval(of: .month, for: now)?.start ?? today
        return [
            .today: DateInterval(start: today, end: now),
            .rollingFiveHours: DateInterval(start: now.addingTimeInterval(-5 * 60 * 60), end: now),
            .week: DateInterval(start: week, end: now),
            .month: DateInterval(start: month, end: now),
        ]
    }

    private func saturatingAdd(_ lhs: Int64, _ rhs: Int64) -> Int64 {
        let (result, overflow) = lhs.addingReportingOverflow(rhs)
        return overflow ? Int64.max : result
    }
}

public struct ExportedDailyUsage: Codable, Equatable, Sendable {
    public let dayKey: String
    public let rawTokens: Int64
    public let effectiveTokens: Int64
    public let awardedXP: Int64
    public let awardedTokenCoins: Int64
}

public struct EvoBarDataExport: Codable, Equatable, Sendable {
    public let formatVersion: Int
    public let exportedAt: Date
    public let animals: [AnimalInstance]
    public let dailyUsage: [ExportedDailyUsage]
    public let tokenCoins: Int64
    public let itemInventory: [String: Int]
    public let appSettings: ExportedAppPreferences
}

public struct ExportedAppPreferences: Codable, Equatable, Sendable {
    public let claudeTrackingEnabled: Bool
    public let codexTrackingEnabled: Bool
    public let refreshIntervalMinutes: Int
    public let animationQuality: String
    public let showTokenInMenuBar: Bool
    public let showTokenBreakdown: Bool
    public let quotaNotificationsEnabled: Bool
    public let launchAtLoginEnabled: Bool
    public let desktopPetEnabled: Bool
    public let desktopPetSize: Double
    public let pinnedAnimalDefinitionID: String?

    init(_ settings: AppSettings) {
        claudeTrackingEnabled = settings.claudeTrackingEnabled
        codexTrackingEnabled = settings.codexTrackingEnabled
        refreshIntervalMinutes = settings.refreshIntervalMinutes
        animationQuality = settings.animationQuality
        showTokenInMenuBar = settings.showTokenInMenuBar
        showTokenBreakdown = settings.showTokenBreakdown
        quotaNotificationsEnabled = settings.quotaNotificationsEnabled
        launchAtLoginEnabled = settings.launchAtLoginEnabled
        desktopPetEnabled = settings.desktopPetEnabled
        desktopPetSize = settings.desktopPetSize
        pinnedAnimalDefinitionID = settings.pinnedAnimalDefinitionID
    }
}

private struct TokenAccumulator {
    private var inputTokens: Int64 = 0
    private var outputTokens: Int64 = 0
    private var cacheReadTokens: Int64 = 0
    private var cacheWriteTokens: Int64 = 0
    private var reasoningTokens: Int64 = 0
    private var totalTokens: Int64 = 0

    mutating func add(_ usage: TokenUsage) {
        inputTokens = Self.add(inputTokens, usage.inputTokens)
        outputTokens = Self.add(outputTokens, usage.outputTokens)
        cacheReadTokens = Self.add(cacheReadTokens, usage.cacheReadTokens)
        cacheWriteTokens = Self.add(cacheWriteTokens, usage.cacheWriteTokens)
        reasoningTokens = Self.add(reasoningTokens, usage.reasoningTokens)
        totalTokens = Self.add(totalTokens, usage.totalTokens)
    }

    var value: TokenUsage {
        TokenUsage(
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            cacheReadTokens: cacheReadTokens,
            cacheWriteTokens: cacheWriteTokens,
            reasoningTokens: reasoningTokens,
            totalTokens: totalTokens
        )
    }

    private static func add(_ lhs: Int64, _ rhs: Int64) -> Int64 {
        let (result, overflow) = lhs.addingReportingOverflow(rhs)
        return overflow ? Int64.max : result
    }
}

private struct CostAccumulator {
    private var amountUSD: Decimal = 0
    private var pricedTokens: Int64 = 0
    private var unpricedTokens: Int64 = 0

    mutating func add(_ estimate: UsageCostEstimate) {
        amountUSD += estimate.amountUSD
        pricedTokens = Self.add(pricedTokens, estimate.pricedTokens)
        unpricedTokens = Self.add(unpricedTokens, estimate.unpricedTokens)
    }

    var amountOrNil: Decimal? { pricedTokens > 0 ? amountUSD : nil }

    var coverage: Double {
        let total = pricedTokens + unpricedTokens
        return total > 0 ? Double(pricedTokens) / Double(total) : 1
    }

    private static func add(_ lhs: Int64, _ rhs: Int64) -> Int64 {
        let (result, overflow) = lhs.addingReportingOverflow(rhs)
        return overflow ? Int64.max : result
    }
}

private struct PersistenceState: Codable {
    var schemaVersion = 10
    var events: [String: PersistedUsageEvent] = [:]
    var dailyAggregates: [String: PersistedDailyAggregate] = [:]
    var checkpoints: [String: PersistedCheckpoint] = [:]
    var animalInstances: [String: AnimalInstance] = [:]
    var settings = PersistedSettings()

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case events
        case dailyAggregates
        case checkpoints
        case animalInstances
        case settings
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        events = try container.decodeIfPresent(
            [String: PersistedUsageEvent].self,
            forKey: .events
        ) ?? [:]
        dailyAggregates = try container.decodeIfPresent(
            [String: PersistedDailyAggregate].self,
            forKey: .dailyAggregates
        ) ?? [:]
        checkpoints = try container.decodeIfPresent(
            [String: PersistedCheckpoint].self,
            forKey: .checkpoints
        ) ?? [:]
        animalInstances = try container.decodeIfPresent(
            [String: AnimalInstance].self,
            forKey: .animalInstances
        ) ?? [:]
        settings = try container.decodeIfPresent(
            PersistedSettings.self,
            forKey: .settings
        ) ?? PersistedSettings()

        // Additive, backward-compatible egg ledger. No history leaves the device.
        for index in settings.incubator.indices where settings.incubator[index].countedDayKeys == nil {
            let placedAt = settings.incubator[index].placedAt
            let days = Set(events.values.lazy.filter {
                $0.timestamp >= placedAt && $0.usage.totalTokens > 0
            }.map(\.dayKey))
            settings.incubator[index].restoreCountedDays(days)
        }

        if decodedVersion < 2, animalInstances.isEmpty {
            let instanceID = settings.currentAnimalInstanceID ?? UUID()
            var providerTokens: [ProviderID: Int64] = [:]
            var cumulativeTokens: Int64 = 0
            var lastActivityAt: Date?
            for event in events.values {
                cumulativeTokens = Self.saturatingAdd(cumulativeTokens, event.usage.totalTokens)
                providerTokens[event.providerID] = Self.saturatingAdd(
                    providerTokens[event.providerID] ?? 0,
                    event.usage.totalTokens
                )
                lastActivityAt = max(lastActivityAt ?? .distantPast, event.timestamp)
            }
            let migrated = AnimalInstance(
                id: instanceID,
                definitionID: AnimalDefinitionID(rawValue: settings.currentAnimalID),
                name: settings.companionName,
                createdAt: settings.trackingStartedAt,
                currentXP: settings.currentXP,
                isCurrent: true,
                natureID: "curious",
                rarity: .common,
                cumulativeTokens: cumulativeTokens,
                providerTokens: providerTokens,
                lastActivityAt: lastActivityAt
            )
            animalInstances[instanceID.uuidString] = migrated
            settings.currentAnimalInstanceID = instanceID
            settings.onboardingCompleted = true
        }
        if decodedVersion < 3, settings.starterGrantID == nil {
            settings.starterGrantID = settings.currentAnimalInstanceID.flatMap {
                animalInstances[$0.uuidString]?.definitionID.rawValue
            }
        }
        if decodedVersion < 3, let currentID = settings.currentAnimalInstanceID {
            for key in dailyAggregates.keys {
                guard var aggregate = dailyAggregates[key] else { continue }
                aggregate.awardedXPByAnimal[currentID.uuidString] = aggregate.awardedXP
                dailyAggregates[key] = aggregate
            }
        }
        if decodedVersion < 4 {
            settings.appSettings.claudeTrackingEnabled = settings.claudeTrackingEnabled
            settings.appSettings.codexTrackingEnabled = settings.codexTrackingEnabled
        }
        schemaVersion = 10
    }

    private static func saturatingAdd(_ lhs: Int64, _ rhs: Int64) -> Int64 {
        let (result, overflow) = lhs.addingReportingOverflow(rhs)
        return overflow ? Int64.max : result
    }
}

private struct PersistedUsageEvent: Codable {
    let providerID: ProviderID
    let sessionID: String
    let timestamp: Date
    let modelID: String?
    let usage: TokenUsage
    let sourceFingerprint: String
    let dayKey: String

    init(event: UsageEvent, dayKey: String) {
        providerID = event.provider
        sessionID = event.sessionID
        timestamp = event.timestamp
        modelID = event.modelID
        usage = event.usage
        sourceFingerprint = event.sourceFingerprint
        self.dayKey = dayKey
    }
}

private struct PersistedDailyAggregate: Codable {
    var rawTokens: Int64 = 0
    /// Nil means a day credited under the original rule; it keeps that rule
    /// when rescanned so an update never rewrites or suspends earned progress.
    var growthCacheReadTokens: Int64?
    /// Nil belongs to an existing day that earned XP under the original
    /// curve. Later appends to that day must keep its original rule.
    var xpCurve: DailyXPCurve?
    var effectiveTokens: Int64 = 0
    var awardedXP: Int64 = 0
    var awardedTokenCoins: Int64 = 0
    var awardedXPByAnimal: [String: Int64] = [:]
    /// Raw tokens each individual saw that day, for its journal's busiest day.
    var tokensByAnimal: [String: Int64] = [:]

    enum CodingKeys: String, CodingKey {
        case rawTokens
        case growthCacheReadTokens
        case xpCurve
        case effectiveTokens
        case awardedXP
        case awardedTokenCoins
        case awardedXPByAnimal
        case tokensByAnimal
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rawTokens = try container.decodeIfPresent(Int64.self, forKey: .rawTokens) ?? 0
        growthCacheReadTokens = try container.decodeIfPresent(Int64.self, forKey: .growthCacheReadTokens)
        xpCurve = try container.decodeIfPresent(DailyXPCurve.self, forKey: .xpCurve)
        effectiveTokens = try container.decodeIfPresent(Int64.self, forKey: .effectiveTokens) ?? 0
        awardedXP = try container.decodeIfPresent(Int64.self, forKey: .awardedXP) ?? 0
        awardedTokenCoins = try container.decodeIfPresent(
            Int64.self,
            forKey: .awardedTokenCoins
        ) ?? 0
        awardedXPByAnimal = try container.decodeIfPresent(
            [String: Int64].self,
            forKey: .awardedXPByAnimal
        ) ?? [:]
        tokensByAnimal = try container.decodeIfPresent(
            [String: Int64].self,
            forKey: .tokensByAnimal
        ) ?? [:]
    }
}

private struct PersistedCheckpoint: Codable {
    let providerID: ProviderID
    var byteOffset: UInt64
    var fileSize: UInt64
    var generation: Int
    var sessionID: String?
    var modelID: String?
    var updatedAt: Date
}

private struct PersistedSettings: Codable {
    var companionName = "Mochi"
    var currentAnimalID = "cat"
    var currentXP: Int64 = 0
    var tokenCoins: Int64 = 0
    var growthTimeZoneID = TimeZone.current.identifier
    var trackingStartedAt = Date()
    var claudeTrackingEnabled = true
    var codexTrackingEnabled = true
    var onboardingCompleted = false
    var currentAnimalInstanceID: UUID?
    var starterGrantID: String?
    var activeProductIDs: Set<ProductID> = []
    var appSettings = AppSettings()
    var itemInventory: [String: Int] = [:]
    var incubator: [IncubatingEgg] = []
    /// The growth day the daily gift was last given on.
    var lastGiftDayKey: String?

    enum CodingKeys: String, CodingKey {
        case companionName
        case currentAnimalID
        case currentXP
        case tokenCoins
        case growthTimeZoneID
        case trackingStartedAt
        case claudeTrackingEnabled
        case codexTrackingEnabled
        case onboardingCompleted
        case currentAnimalInstanceID
        case starterGrantID
        case activeProductIDs
        case appSettings
        case itemInventory
        case incubator
        case lastGiftDayKey
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        companionName = try container.decodeIfPresent(String.self, forKey: .companionName) ?? "Mochi"
        currentAnimalID = try container.decodeIfPresent(String.self, forKey: .currentAnimalID) ?? "cat"
        currentXP = try container.decodeIfPresent(Int64.self, forKey: .currentXP) ?? 0
        tokenCoins = try container.decodeIfPresent(Int64.self, forKey: .tokenCoins) ?? 0
        growthTimeZoneID = try container.decodeIfPresent(
            String.self,
            forKey: .growthTimeZoneID
        ) ?? TimeZone.current.identifier
        trackingStartedAt = try container.decodeIfPresent(
            Date.self,
            forKey: .trackingStartedAt
        ) ?? Date()
        claudeTrackingEnabled = try container.decodeIfPresent(
            Bool.self,
            forKey: .claudeTrackingEnabled
        ) ?? true
        codexTrackingEnabled = try container.decodeIfPresent(
            Bool.self,
            forKey: .codexTrackingEnabled
        ) ?? true
        onboardingCompleted = try container.decodeIfPresent(
            Bool.self,
            forKey: .onboardingCompleted
        ) ?? false
        currentAnimalInstanceID = try container.decodeIfPresent(
            UUID.self,
            forKey: .currentAnimalInstanceID
        )
        starterGrantID = try container.decodeIfPresent(String.self, forKey: .starterGrantID)
        activeProductIDs = try container.decodeIfPresent(
            Set<ProductID>.self,
            forKey: .activeProductIDs
        ) ?? []
        appSettings = try container.decodeIfPresent(
            AppSettings.self,
            forKey: .appSettings
        ) ?? AppSettings(
            claudeTrackingEnabled: claudeTrackingEnabled,
            codexTrackingEnabled: codexTrackingEnabled
        )
        itemInventory = try container.decodeIfPresent(
            [String: Int].self,
            forKey: .itemInventory
        ) ?? [:]
        incubator = try container.decodeIfPresent(
            [IncubatingEgg].self,
            forKey: .incubator
        ) ?? []
        lastGiftDayKey = try container.decodeIfPresent(String.self, forKey: .lastGiftDayKey)
    }
}
