import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public var claudeTrackingEnabled: Bool
    public var codexTrackingEnabled: Bool
    public var refreshIntervalMinutes: Int
    public var animationQuality: String
    public var showTokenInMenuBar: Bool
    public var showTokenBreakdown: Bool
    public var quotaNotificationsEnabled: Bool
    public var companionNotificationsEnabled: Bool
    public var providerStatusChecksEnabled: Bool
    public var automaticUpdateChecksEnabled: Bool
    public var launchAtLoginEnabled: Bool
    public var claudeAdditionalLogPatterns: [String]
    public var codexAdditionalLogPatterns: [String]
    public var desktopPetEnabled: Bool
    public var desktopPetSize: Double
    public var pinnedAnimalDefinitionID: String?
    public var desktopPetX: Double?
    public var desktopPetY: Double?
    public var usageBandThresholds: [Int64]
    /// The scene backdrop the user is wearing, by manifest item id; nil takes
    /// the scene's colour from the companion's own artwork.
    public var sceneThemeID: String?

    public init(
        claudeTrackingEnabled: Bool = true,
        codexTrackingEnabled: Bool = true,
        refreshIntervalMinutes: Int = 1,
        animationQuality: String = "balanced",
        showTokenInMenuBar: Bool = true,
        showTokenBreakdown: Bool = true,
        quotaNotificationsEnabled: Bool = false,
        companionNotificationsEnabled: Bool = false,
        providerStatusChecksEnabled: Bool = true,
        automaticUpdateChecksEnabled: Bool = true,
        launchAtLoginEnabled: Bool = false,
        claudeAdditionalLogPatterns: [String] = [],
        codexAdditionalLogPatterns: [String] = [],
        desktopPetEnabled: Bool = false,
        desktopPetSize: Double = 96,
        pinnedAnimalDefinitionID: String? = nil,
        desktopPetX: Double? = nil,
        desktopPetY: Double? = nil,
        usageBandThresholds: [Int64] = AppSettings.defaultUsageBandThresholds,
        sceneThemeID: String? = nil
    ) {
        self.claudeTrackingEnabled = claudeTrackingEnabled
        self.codexTrackingEnabled = codexTrackingEnabled
        self.refreshIntervalMinutes = Self.validatedRefreshInterval(refreshIntervalMinutes)
        self.animationQuality = animationQuality
        self.showTokenInMenuBar = showTokenInMenuBar
        self.showTokenBreakdown = showTokenBreakdown
        self.quotaNotificationsEnabled = quotaNotificationsEnabled
        self.companionNotificationsEnabled = companionNotificationsEnabled
        self.providerStatusChecksEnabled = providerStatusChecksEnabled
        self.automaticUpdateChecksEnabled = automaticUpdateChecksEnabled
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.claudeAdditionalLogPatterns = claudeAdditionalLogPatterns
        self.codexAdditionalLogPatterns = codexAdditionalLogPatterns
        self.desktopPetEnabled = desktopPetEnabled
        self.desktopPetSize = min(192, max(48, desktopPetSize))
        self.pinnedAnimalDefinitionID = pinnedAnimalDefinitionID
        self.desktopPetX = desktopPetX
        self.desktopPetY = desktopPetY
        self.usageBandThresholds = Self.validatedUsageBandThresholds(usageBandThresholds)
        self.sceneThemeID = sceneThemeID
    }

    public static func validatedRefreshInterval(_ minutes: Int) -> Int {
        minutes == 0 ? 0 : min(15, max(1, minutes))
    }

    /// Daily raw-token boundaries between the light, steady, heavy and extreme bands.
    /// The defaults reuse the growth curve's diminishing-return breakpoints.
    public static let defaultUsageBandThresholds: [Int64] = [1_000_000, 5_000_000, 20_000_000]

    /// Three strictly ascending positive values; anything else falls back to the defaults.
    public static func validatedUsageBandThresholds(_ values: [Int64]) -> [Int64] {
        guard values.count == 3, values[0] > 0, values[0] < values[1], values[1] < values[2] else {
            return defaultUsageBandThresholds
        }
        return values
    }

    private enum CodingKeys: String, CodingKey {
        case claudeTrackingEnabled
        case codexTrackingEnabled
        case refreshIntervalMinutes
        case animationQuality
        case showTokenInMenuBar
        case showTokenBreakdown
        case quotaNotificationsEnabled
        case companionNotificationsEnabled
        case providerStatusChecksEnabled
        case automaticUpdateChecksEnabled
        case launchAtLoginEnabled
        case claudeAdditionalLogPatterns
        case codexAdditionalLogPatterns
        case desktopPetEnabled
        case desktopPetSize
        case pinnedAnimalDefinitionID
        case desktopPetX
        case desktopPetY
        case usageBandThresholds
        case sceneThemeID
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            claudeTrackingEnabled: try container.decodeIfPresent(Bool.self, forKey: .claudeTrackingEnabled) ?? true,
            codexTrackingEnabled: try container.decodeIfPresent(Bool.self, forKey: .codexTrackingEnabled) ?? true,
            refreshIntervalMinutes: try container.decodeIfPresent(Int.self, forKey: .refreshIntervalMinutes) ?? 1,
            animationQuality: try container.decodeIfPresent(String.self, forKey: .animationQuality) ?? "balanced",
            showTokenInMenuBar: try container.decodeIfPresent(Bool.self, forKey: .showTokenInMenuBar) ?? true,
            showTokenBreakdown: try container.decodeIfPresent(Bool.self, forKey: .showTokenBreakdown) ?? true,
            quotaNotificationsEnabled: try container.decodeIfPresent(Bool.self, forKey: .quotaNotificationsEnabled) ?? false,
            companionNotificationsEnabled: try container.decodeIfPresent(Bool.self, forKey: .companionNotificationsEnabled) ?? false,
            providerStatusChecksEnabled: try container.decodeIfPresent(Bool.self, forKey: .providerStatusChecksEnabled) ?? true,
            automaticUpdateChecksEnabled: try container.decodeIfPresent(Bool.self, forKey: .automaticUpdateChecksEnabled) ?? true,
            launchAtLoginEnabled: try container.decodeIfPresent(Bool.self, forKey: .launchAtLoginEnabled) ?? false,
            claudeAdditionalLogPatterns: try container.decodeIfPresent([String].self, forKey: .claudeAdditionalLogPatterns) ?? [],
            codexAdditionalLogPatterns: try container.decodeIfPresent([String].self, forKey: .codexAdditionalLogPatterns) ?? [],
            desktopPetEnabled: try container.decodeIfPresent(Bool.self, forKey: .desktopPetEnabled) ?? false,
            desktopPetSize: try container.decodeIfPresent(Double.self, forKey: .desktopPetSize) ?? 96,
            pinnedAnimalDefinitionID: try container.decodeIfPresent(String.self, forKey: .pinnedAnimalDefinitionID),
            desktopPetX: try container.decodeIfPresent(Double.self, forKey: .desktopPetX),
            desktopPetY: try container.decodeIfPresent(Double.self, forKey: .desktopPetY),
            usageBandThresholds: try container.decodeIfPresent([Int64].self, forKey: .usageBandThresholds)
                ?? AppSettings.defaultUsageBandThresholds,
            sceneThemeID: try container.decodeIfPresent(String.self, forKey: .sceneThemeID)
        )
    }
}
