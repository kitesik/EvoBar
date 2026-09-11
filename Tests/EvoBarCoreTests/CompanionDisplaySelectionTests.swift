import EvoBarCore
import Foundation
import Testing

struct CompanionDisplaySelectionTests {
    private let available: Set<AnimalDefinitionID> = ["cat", "dog", "fox"]
    private let owned: Set<AnimalDefinitionID> = ["cat", "dog", "fox", "dragon"]
    private let birthday = Date(timeIntervalSince1970: 1_700_000_000)

    private func animal(_ id: AnimalDefinitionID, stage: Int, current: Bool = false, age: Double = 0) -> AnimalInstance {
        AnimalInstance(definitionID: id, name: id.rawValue, createdAt: birthday.addingTimeInterval(age),
                       currentXP: 300, acknowledgedStageIndex: stage, isCurrent: current,
                       natureID: "curious", rarity: .common, cumulativeTokens: 5_000_000)
    }

    @Test func unpinnedUsesTheGrowingIndividualNotItsOlderGraduate() {
        let current = animal("cat", stage: 2, current: true)
        let graduate = animal("cat", stage: 5, age: -100)
        let selection = CompanionDisplaySelection.resolve(
            currentDefinitionID: "cat", pinnedDefinitionID: nil, ownedDefinitionIDs: owned,
            availableDefinitionIDs: available, instances: [graduate, current])
        #expect(selection.definitionID == "cat")
        #expect(selection.instance?.id == current.id)
        #expect(selection.stageIndex == 2)
    }

    @Test func pinShowsHighestDiscoveredStageWithoutMutatingGrowth() {
        let current = animal("cat", stage: 2, current: true)
        let older = animal("dog", stage: 4, age: -100)
        var newer = animal("dog", stage: 4)
        newer.isShiny = true
        let instances = [current, older, newer, animal("dog", stage: 1, age: 100)]
        let selection = CompanionDisplaySelection.resolve(
            currentDefinitionID: "cat", pinnedDefinitionID: "dog", ownedDefinitionIDs: owned,
            availableDefinitionIDs: available, instances: instances)
        #expect(selection.instance?.id == newer.id)
        #expect(selection.stageIndex == 4)
        #expect(selection.isShiny)
        #expect(instances.first(where: \.isCurrent) == current)
        #expect(selection.instance?.isCurrent == false)
    }

    @Test func ownedUnhatchedLineShowsBabyWithoutCreatingAnIndividual() {
        let current = animal("cat", stage: 2, current: true)
        let selection = CompanionDisplaySelection.resolve(
            currentDefinitionID: "cat", pinnedDefinitionID: "fox", ownedDefinitionIDs: owned,
            availableDefinitionIDs: available, instances: [current])
        #expect(selection.definitionID == "fox")
        #expect(selection.instance == nil)
        #expect(selection.stageIndex == 1)
        #expect(!selection.isShiny)
    }

    @Test func lockedOrUnillustratedPinsFallBackToGrowingCompanion() {
        let current = animal("cat", stage: 2, current: true)
        for pin: AnimalDefinitionID in ["capybara", "dragon", "unknown"] {
            let selection = CompanionDisplaySelection.resolve(
                currentDefinitionID: "cat", pinnedDefinitionID: pin, ownedDefinitionIDs: owned,
                availableDefinitionIDs: available, instances: [current])
            #expect(selection.instance?.id == current.id)
            #expect(selection.definitionID == "cat")
        }
    }

    @Test func reduceMotionOverridesEveryAnimatedQualityAndState() {
        for quality in ["balanced", "smooth"] {
            for state: CompanionVisualState in [.idle, .working, .evolutionReady, .sleeping] {
                #expect(CompanionMotionProfile.resolve(
                    qualityID: quality, visualState: state, reduceMotion: true) == .still)
            }
        }
    }

    @Test func collectionRepresentativePreservesVariantWithoutRevealingLaterShinyForms() {
        let normalFinal = animal("cat", stage: 7, age: -100)
        var shinyBaby = animal("cat", stage: 1, age: 100)
        shinyBaby.isShiny = true
        let input = [shinyBaby, animal("dog", stage: 7), normalFinal]
        let selected = CompanionDisplaySelection.representativeInstance(for: "cat", in: input)
        #expect(selected == normalFinal)
        #expect(selected?.isShiny == false)
        #expect(input[0] == shinyBaby)
        #expect(CompanionDisplaySelection.representativeInstance(for: "fox", in: input) == nil)
    }

    @Test func collectionRepresentativeSharesPinnedTieBreakingIncludingShiny() {
        let earlier = animal("dog", stage: 4, age: -100)
        var later = animal("dog", stage: 4, age: 100)
        later.isShiny = true
        for input in [[earlier, later], [later, earlier]] {
            let representative = CompanionDisplaySelection.representativeInstance(for: "dog", in: input)
            let pin = CompanionDisplaySelection.resolve(
                currentDefinitionID: "cat", pinnedDefinitionID: "dog", ownedDefinitionIDs: owned,
                availableDefinitionIDs: available, instances: input)
            #expect(representative == later)
            #expect(representative == pin.instance)
            #expect(representative?.isShiny == true)
        }
    }
}
