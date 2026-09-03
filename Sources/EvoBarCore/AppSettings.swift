import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public var claudeTrackingEnabled: Bool
    public var codexTrackingEnabled: Bool
    public var refreshIntervalMinutes: Int
    public var animationQuality: String
    public var showTokenInMenuBar: Bool
    public var showTokenBreakdown: Bool
    public var quotaNotificationsEnabled: Bool
    public var providerStatusChecksEnabled: Bool
    public var launchAtLoginEnabled: Bool
    public var claudeAdditionalLogPatterns: [String]
    public var codexAdditionalLogPatterns: [String]
    public var desktopPetEnabled: Bool
    public var desktopPetSize: Double
    public var pinnedAnimalDefinitionID: String?
    public var desktopPetX: Double?
    public var desktopPetY: Double?

    public init(
        claudeTrackingEnabled: Bool = true,
        codexTrackingEnabled: Bool = true,
        refreshIntervalMinutes: Int = 1,
        animationQuality: String = "powerSaver",
        showTokenInMenuBar: Bool = true,
        showTokenBreakdown: Bool = true,
        quotaNotificationsEnabled: Bool = false,
        providerStatusChecksEnabled: Bool = true,
        launchAtLoginEnabled: Bool = false,
        claudeAdditionalLogPatterns: [String] = [],
        codexAdditionalLogPatterns: [String] = [],
        desktopPetEnabled: Bool = false,
        desktopPetSize: Double = 96,
        pinnedAnimalDefinitionID: String? = nil,
        desktopPetX: Double? = nil,
        desktopPetY: Double? = nil
    ) {
        self.claudeTrackingEnabled = claudeTrackingEnabled
        self.codexTrackingEnabled = codexTrackingEnabled
        self.refreshIntervalMinutes = Self.validatedRefreshInterval(refreshIntervalMinutes)
        self.animationQuality = animationQuality
        self.showTokenInMenuBar = showTokenInMenuBar
        self.showTokenBreakdown = showTokenBreakdown
        self.quotaNotificationsEnabled = quotaNotificationsEnabled
        self.providerStatusChecksEnabled = providerStatusChecksEnabled
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.claudeAdditionalLogPatterns = claudeAdditionalLogPatterns
        self.codexAdditionalLogPatterns = codexAdditionalLogPatterns
        self.desktopPetEnabled = desktopPetEnabled
        self.desktopPetSize = min(192, max(48, desktopPetSize))
        self.pinnedAnimalDefinitionID = pinnedAnimalDefinitionID
        self.desktopPetX = desktopPetX
        self.desktopPetY = desktopPetY
    }

    public static func validatedRefreshInterval(_ minutes: Int) -> Int {
        minutes == 0 ? 0 : min(15, max(1, minutes))
    }

    private enum CodingKeys: String, CodingKey {
        case claudeTrackingEnabled
        case codexTrackingEnabled
        case refreshIntervalMinutes
        case animationQuality
        case showTokenInMenuBar
        case showTokenBreakdown
        case quotaNotificationsEnabled
        case providerStatusChecksEnabled
        case launchAtLoginEnabled
        case claudeAdditionalLogPatterns
        case codexAdditionalLogPatterns
        case desktopPetEnabled
        case desktopPetSize
        case pinnedAnimalDefinitionID
        case desktopPetX
        case desktopPetY
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            claudeTrackingEnabled: try container.decodeIfPresent(Bool.self, forKey: .claudeTrackingEnabled) ?? true,
            codexTrackingEnabled: try container.decodeIfPresent(Bool.self, forKey: .codexTrackingEnabled) ?? true,
            refreshIntervalMinutes: try container.decodeIfPresent(Int.self, forKey: .refreshIntervalMinutes) ?? 1,
            animationQuality: try container.decodeIfPresent(String.self, forKey: .animationQuality) ?? "powerSaver",
            showTokenInMenuBar: try container.decodeIfPresent(Bool.self, forKey: .showTokenInMenuBar) ?? true,
            showTokenBreakdown: try container.decodeIfPresent(Bool.self, forKey: .showTokenBreakdown) ?? true,
            quotaNotificationsEnabled: try container.decodeIfPresent(Bool.self, forKey: .quotaNotificationsEnabled) ?? false,
            providerStatusChecksEnabled: try container.decodeIfPresent(Bool.self, forKey: .providerStatusChecksEnabled) ?? true,
            launchAtLoginEnabled: try container.decodeIfPresent(Bool.self, forKey: .launchAtLoginEnabled) ?? false,
            claudeAdditionalLogPatterns: try container.decodeIfPresent([String].self, forKey: .claudeAdditionalLogPatterns) ?? [],
            codexAdditionalLogPatterns: try container.decodeIfPresent([String].self, forKey: .codexAdditionalLogPatterns) ?? [],
            desktopPetEnabled: try container.decodeIfPresent(Bool.self, forKey: .desktopPetEnabled) ?? false,
            desktopPetSize: try container.decodeIfPresent(Double.self, forKey: .desktopPetSize) ?? 96,
            pinnedAnimalDefinitionID: try container.decodeIfPresent(String.self, forKey: .pinnedAnimalDefinitionID),
            desktopPetX: try container.decodeIfPresent(Double.self, forKey: .desktopPetX),
            desktopPetY: try container.decodeIfPresent(Double.self, forKey: .desktopPetY)
        )
    }
}
