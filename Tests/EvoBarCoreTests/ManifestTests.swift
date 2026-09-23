import EvoBarCore
import Foundation
import Testing

@Suite struct ManifestTests {
    @Test func appSettingsDecodeOlderPayloadWithSafeDefaults() throws {
        let data = Data(#"{"refreshIntervalMinutes":5,"showTokenInMenuBar":false}"#.utf8)
        let settings = try JSONDecoder().decode(AppSettings.self, from: data)
        #expect(settings.refreshIntervalMinutes == 5)
        #expect(!settings.showTokenInMenuBar)
        #expect(settings.claudeAdditionalLogPatterns.isEmpty)
        #expect(settings.codexAdditionalLogPatterns.isEmpty)
        #expect(!settings.desktopPetEnabled)
        #expect(settings.desktopPetSize == 96)
        #expect(settings.providerStatusChecksEnabled)
        #expect(!settings.companionNotificationsEnabled)
        #expect(settings.automaticUpdateChecksEnabled)
    }

    @Test func assetProviderUsesManifestStageAndShinyIDs() throws {
        let animal = try #require(ManifestLoader.bundledCatalog().animals.first)
        let provider = ManifestAnimalAssetProvider()
        let normal = provider.asset(
            for: animal,
            stageIndex: 3,
            isShiny: false,
            visualState: .working
        )
        let shiny = provider.asset(
            for: animal,
            stageIndex: 3,
            isShiny: true,
            visualState: .evolutionReady
        )
        #expect(normal.assetID == animal.stages[2].normalAssetID)
        #expect(normal.visualState == .working)
        #expect(shiny.assetID == animal.stages[2].shinyAssetID)
        #expect(shiny.visualState == .evolutionReady)
    }

    @Test func companionMotionProfilesRespectStateAndPowerMode() {
        let powerSaver = CompanionMotionProfile.resolve(
            qualityID: "powerSaver",
            visualState: .working
        )
        let balanced = CompanionMotionProfile.resolve(
            qualityID: "balanced",
            visualState: .working
        )
        let smooth = CompanionMotionProfile.resolve(
            qualityID: "smooth",
            visualState: .working
        )
        let sleeping = CompanionMotionProfile.resolve(
            qualityID: "smooth",
            visualState: .sleeping
        )

        let flier = CompanionMotionProfile.resolve(
            qualityID: "smooth",
            visualState: .working,
            locomotion: .fly
        )
        let idle = CompanionMotionProfile.resolve(qualityID: "smooth", visualState: .idle)

        #expect(powerSaver == .still)
        #expect(sleeping == .still)
        #expect(flier == .still)
        #expect(balanced.gait == .trot)
        #expect(balanced.frameCount == 8)
        #expect(balanced.frameInterval == SpriteGait.trot.cycleDuration / 8)
        #expect(smooth.frameCount == 12)
        #expect(smooth.frameInterval == SpriteGait.trot.cycleDuration / 12)
        #expect(idle.gait == .walk)
        #expect(idle.frameInterval == SpriteGait.walk.cycleDuration / 12)
    }

    /// Artwork availability is what gates selling and hatching a line, so it must
    /// agree with what is actually bundled.
    @Test func artworkAvailabilityMatchesTheBundledSprites() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let illustrated = catalog.animals
            .filter { BundledAnimalSpriteStore.hasArtwork(for: $0) }
            .map(\.id.rawValue)
            .sorted()
        #expect(illustrated == catalog.animals.map(\.id.rawValue).sorted())
        // Starters must always be drawn, or a first run has no companion to show.
        for animal in catalog.animals where animal.isStarter {
            #expect(BundledAnimalSpriteStore.hasArtwork(for: animal), "starter \(animal.id.rawValue)")
        }
    }

    @Test func bundledCompanionSpritesAreCompletePerAnimal() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let provider = ManifestAnimalAssetProvider()
        let states: [CompanionVisualState] = [.idle, .working, .evolutionReady, .sleeping]
        var illustrated: [AnimalDefinitionID] = []

        for animal in catalog.animals {
            var present = 0
            for stage in animal.stages {
                for state in states {
                    let normal = provider.asset(
                        for: animal,
                        stageIndex: stage.index,
                        isShiny: false,
                        visualState: state
                    )
                    let shiny = provider.asset(
                        for: animal,
                        stageIndex: stage.index,
                        isShiny: true,
                        visualState: state
                    )
                    guard let normalData = BundledAnimalSpriteStore.imageData(for: normal) else { continue }
                    present += 1
                    #expect(normalData.starts(with: [0x89, 0x50, 0x4E, 0x47]))
                    let shinyData = try #require(BundledAnimalSpriteStore.imageData(for: shiny))
                    if animal.hasShinyArtwork == true {
                        #expect(shinyData != normalData, "\(shiny.assetID) must not fall back to normal")
                    } else {
                        #expect(shinyData == normalData)
                    }
                }
            }
            // A line either has no artwork yet (emoji fallback) or covers every stage and state.
            #expect(
                present == 0 || present == animal.stages.count * states.count,
                "\(animal.id.rawValue) has \(present) sprites"
            )
            if present > 0 { illustrated.append(animal.id) }
        }
        #expect(illustrated == catalog.animals.map(\.id))
        #expect(catalog.animals.flatMap(\.stages).allSatisfy { $0.artworkPending != true })
    }

    @Test func bundledManifestsAreValid() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let storefront = try ManifestLoader.bundledStorefront()
        let economy = try ManifestLoader.bundledEconomy()
        let pricing = try ManifestLoader.bundledPricing()
        try ManifestLoader.validate(catalog: catalog, storefront: storefront, economy: economy)
        try ManifestLoader.validate(pricing: pricing)
        #expect(catalog.animals.count == 7)
        #expect(Set(catalog.animals.map(\.id)) == ["cat", "dog", "fox", "capybara", "raptor", "mammoth", "pterosaur"])
        #expect(storefront.products.allSatisfy { product in
            product.grantsAnimalIDs.allSatisfy { id in catalog.animals.contains { $0.id == id } }
        })
        #expect(!storefront.products.contains { $0.id == "evobar.bundle.myth" })
        #expect(catalog.animals.filter(\.isStarter).map(\.id) == ["cat", "dog"])
        // Cat and dog run seven stages; the other lines seven or eight, as far as
        // each family plausibly goes. The first five thresholds are unchanged so
        // no existing companion moves.
        let ladders: [Int: [Int64]] = [
            7: [0, 15, 150, 900, 2_000, 4_000, 7_000],
            8: [0, 15, 150, 900, 2_000, 3_600, 6_000, 9_500],
        ]
        #expect(catalog.animals.allSatisfy { (7...8).contains($0.stages.count) })
        #expect(catalog.animals.first { $0.id == "cat" }?.stages.count == 7)
        #expect(catalog.animals.first { $0.id == "dog" }?.stages.count == 7)
        #expect(catalog.animals.allSatisfy { $0.stages.map(\.xpThreshold) == ladders[$0.stages.count] })
        // A stage still waiting for its sheet says so; it shows a placeholder recoloured
        // from a neighbour (see Scripts/derive-placeholder-sprites.swift), never a bare emoji.
        for animal in catalog.animals {
            for stage in animal.stages where stage.artworkPending == true {
                #expect(stage.normalAssetID == "\(animal.id.rawValue).\(stage.index)", "\(stage.nameKey)")
                #expect(BundledAnimalSpriteStore.hasArtwork(for: animal), "\(stage.nameKey)")
                #expect(!BundledAnimalSpriteStore.hasArtwork(for: animal, stageIndex: stage.index))
                let placeholder = AnimalAssetReference(
                    assetID: stage.normalAssetID, fallbackEmoji: animal.menuBarEmoji, visualState: .idle)
                #expect(BundledAnimalSpriteStore.imageData(for: placeholder) != nil, "\(stage.nameKey)")
            }
            for stage in animal.stages where stage.artworkPending != true && BundledAnimalSpriteStore.hasArtwork(for: animal) {
                #expect(BundledAnimalSpriteStore.hasArtwork(for: animal, stageIndex: stage.index), "\(stage.nameKey)")
            }
        }
        #expect(pricing.models.contains { $0.canonicalModelID == "gpt-5.6-terra" })
        #expect(pricing.models.contains { $0.canonicalModelID == "claude-sonnet-5" })
    }

    @Test func allAnimalProductsExist() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let storefront = try ManifestLoader.bundledStorefront()
        let productIDs = Set(storefront.products.map(\.id))
        #expect(catalog.animals.allSatisfy { productIDs.contains($0.purchaseProductID) })
        #expect(storefront.products.first(where: { $0.kind == .allAnimals })?.grantsAnimalIDs.count == 7)
    }
}
