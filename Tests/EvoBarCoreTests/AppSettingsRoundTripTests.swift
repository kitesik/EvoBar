import EvoBarCore
import Foundation
import Testing

struct AppSettingsRoundTripTests {
    @Test(arguments: SceneTheme.allCases)
    func chosenBackdropSurvivesRelaunch(theme: SceneTheme) throws {
        let settings = AppSettings(refreshIntervalMinutes: 0, desktopPetEnabled: true,
            pinnedAnimalDefinitionID: "cat", sceneThemeID: theme.itemID)
        let restored = try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(settings))
        #expect(restored == settings)
    }
}
