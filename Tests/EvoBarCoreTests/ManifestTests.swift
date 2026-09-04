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

        #expect(powerSaver.frameInterval == nil)
        #expect(sleeping.frameInterval == nil)
        #expect(balanced.frameInterval == 0.55)
        #expect(smooth.frameInterval == 0.28)
        #expect(smooth.verticalOffset(for: 0) == 0)
        #expect(smooth.verticalOffset(for: 1) == 1)
        #expect(smooth.scaleFactor(for: -1) == 0.96)
    }

    @Test func bundledCompanionSpritesCoverEveryStageAndVisualState() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let provider = ManifestAnimalAssetProvider()

        for animalID in [AnimalDefinitionID(rawValue: "cat"), "dog", "fox"] {
            let animal = try #require(catalog.animals.first { $0.id == animalID })
            for stage in animal.stages {
                for state in [
                    CompanionVisualState.idle,
                    .working,
                    .evolutionReady,
                    .sleeping,
                ] {
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
                    let normalData = try #require(BundledAnimalSpriteStore.imageData(for: normal))
                    let shinyFallbackData = try #require(BundledAnimalSpriteStore.imageData(for: shiny))
                    #expect(normalData.starts(with: [0x89, 0x50, 0x4E, 0x47]))
                    #expect(shinyFallbackData == normalData)
                }
            }
        }
    }

    @Test func bundledManifestsAreValid() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let storefront = try ManifestLoader.bundledStorefront()
        let economy = try ManifestLoader.bundledEconomy()
        let pricing = try ManifestLoader.bundledPricing()
        try ManifestLoader.validate(catalog: catalog, storefront: storefront, economy: economy)
        try ManifestLoader.validate(pricing: pricing)
        #expect(catalog.animals.count == 10)
        #expect(catalog.animals.filter(\.isStarter).map(\.id) == ["cat", "dog"])
        #expect(catalog.animals.allSatisfy { $0.stages.count == 5 })
        #expect(catalog.animals.allSatisfy { $0.stages.map(\.xpThreshold) == [0, 50, 300, 900, 2_000] })
        #expect(pricing.models.contains { $0.canonicalModelID == "gpt-5.6-terra" })
        #expect(pricing.models.contains { $0.canonicalModelID == "claude-sonnet-5" })
    }

    @Test func allAnimalProductsExist() throws {
        let catalog = try ManifestLoader.bundledCatalog()
        let storefront = try ManifestLoader.bundledStorefront()
        let productIDs = Set(storefront.products.map(\.id))
        #expect(catalog.animals.allSatisfy { productIDs.contains($0.purchaseProductID) })
        #expect(storefront.products.first(where: { $0.kind == .allAnimals })?.grantsAnimalIDs.count == 10)
    }
}
