import Foundation

public struct SemanticVersion: Equatable, Comparable, CustomStringConvertible, Sendable {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let prerelease: String?

    private let prereleaseIdentifiers: [Identifier]

    public init?(_ rawValue: String) {
        var value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.first == "v" || value.first == "V" {
            value.removeFirst()
        }
        let buildParts = value.split(
            separator: "+",
            maxSplits: 1,
            omittingEmptySubsequences: false
        )
        if buildParts.count == 2 {
            let identifiers = buildParts[1].split(separator: ".", omittingEmptySubsequences: false)
            guard identifiers.allSatisfy({
                !$0.isEmpty && $0.allSatisfy(Self.isSemVerCharacter)
            }) else { return nil }
        }
        let withoutBuild = String(buildParts[0])
        let versionParts = withoutBuild.split(
            separator: "-",
            maxSplits: 1,
            omittingEmptySubsequences: false
        )
        let core = versionParts[0].split(separator: ".", omittingEmptySubsequences: false)
        guard core.count == 3,
              let major = Self.parseCoreNumber(core[0]),
              let minor = Self.parseCoreNumber(core[1]),
              let patch = Self.parseCoreNumber(core[2]) else { return nil }

        let prerelease = versionParts.count == 2 ? String(versionParts[1]) : nil
        if let prerelease, prerelease.isEmpty { return nil }
        let identifiers = prerelease?.split(
            separator: ".",
            omittingEmptySubsequences: false
        ).map(String.init) ?? []
        guard identifiers.allSatisfy({ identifier in
            guard !identifier.isEmpty,
                  identifier.allSatisfy(Self.isSemVerCharacter) else { return false }
            let numeric = identifier.allSatisfy(\.isNumber)
            return !numeric || identifier == "0" || !identifier.hasPrefix("0")
        }) else {
            return nil
        }

        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
        self.prereleaseIdentifiers = identifiers.map(Identifier.init)
    }

    public var description: String {
        let core = "\(major).\(minor).\(patch)"
        return prerelease.map { "\(core)-\($0)" } ?? core
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }
        if lhs.prereleaseIdentifiers.isEmpty { return false }
        if rhs.prereleaseIdentifiers.isEmpty { return true }

        for index in 0..<min(lhs.prereleaseIdentifiers.count, rhs.prereleaseIdentifiers.count) {
            let left = lhs.prereleaseIdentifiers[index]
            let right = rhs.prereleaseIdentifiers[index]
            if left == right { continue }
            return left < right
        }
        return lhs.prereleaseIdentifiers.count < rhs.prereleaseIdentifiers.count
    }

    private static func isSemVerCharacter(_ character: Character) -> Bool {
        guard character.unicodeScalars.count == 1,
              let scalar = character.unicodeScalars.first else { return false }
        return (48...57).contains(scalar.value) ||
            (65...90).contains(scalar.value) ||
            (97...122).contains(scalar.value) ||
            scalar.value == 45
    }

    private static func parseCoreNumber(_ value: Substring) -> Int? {
        guard !value.isEmpty,
              value.allSatisfy({ $0.isASCII && $0.isNumber }),
              value == "0" || !value.hasPrefix("0") else { return nil }
        return Int(value)
    }

    private enum Identifier: Equatable, Comparable, Sendable {
        case numeric(Int)
        case text(String)

        init(_ value: String) {
            if let number = Int(value), !value.hasPrefix("0") || value == "0" {
                self = .numeric(number)
            } else {
                self = .text(value)
            }
        }

        static func < (lhs: Identifier, rhs: Identifier) -> Bool {
            switch (lhs, rhs) {
            case (.numeric(let left), .numeric(let right)): left < right
            case (.numeric, .text): true
            case (.text, .numeric): false
            case (.text(let left), .text(let right)): left < right
            }
        }
    }
}

public struct AppRelease: Equatable, Sendable {
    public let version: SemanticVersion
    public let displayName: String
    public let releasePageURL: URL
    public let publishedAt: Date?

    public init(
        version: SemanticVersion,
        displayName: String,
        releasePageURL: URL,
        publishedAt: Date?
    ) {
        self.version = version
        self.displayName = displayName
        self.releasePageURL = releasePageURL
        self.publishedAt = publishedAt
    }
}

public enum AppUpdateState: Equatable, Sendable {
    case idle
    case checking
    case available(current: SemanticVersion, release: AppRelease)
    case upToDate(current: SemanticVersion, latest: SemanticVersion)
    case unavailable(message: String)
}

public struct HTTPDataResponse: Sendable {
    public let data: Data
    public let statusCode: Int

    public init(data: Data, statusCode: Int) {
        self.data = data
        self.statusCode = statusCode
    }
}

public protocol HTTPDataFetching: Sendable {
    func response(for request: URLRequest) async throws -> HTTPDataResponse
}

public actor URLSessionHTTPDataFetcher: HTTPDataFetching {
    public init() {}

    public func response(for request: URLRequest) async throws -> HTTPDataResponse {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw AppUpdateServiceError.invalidResponse
        }
        return HTTPDataResponse(data: data, statusCode: response.statusCode)
    }
}

public protocol AppUpdateChecking: Sendable {
    func check(currentVersion: String) async -> AppUpdateState
}

public struct GitHubReleaseUpdateService: AppUpdateChecking {
    private let endpoint: URL
    private let fetcher: any HTTPDataFetching

    public init(
        owner: String,
        repository: String,
        fetcher: any HTTPDataFetching = URLSessionHTTPDataFetcher()
    ) {
        self.endpoint = URL(string: "https://api.github.com/")!
            .appendingPathComponent("repos")
            .appendingPathComponent(owner)
            .appendingPathComponent(repository)
            .appendingPathComponent("releases")
            .appendingPathComponent("latest")
        self.fetcher = fetcher
    }

    public func check(currentVersion: String) async -> AppUpdateState {
        guard let current = SemanticVersion(currentVersion) else {
            return .unavailable(message: "The installed app version is invalid.")
        }

        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 15
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("EvoBar/\(current)", forHTTPHeaderField: "User-Agent")

        let response: HTTPDataResponse
        do {
            response = try await fetcher.response(for: request)
        } catch {
            return .unavailable(message: "Update check failed. Try again later.")
        }

        if response.statusCode == 404 {
            return .unavailable(message: "No public GitHub release is available yet.")
        }
        guard (200..<300).contains(response.statusCode) else {
            return .unavailable(message: "GitHub returned HTTP \(response.statusCode).")
        }

        do {
            let release = try GitHubReleaseParser.parse(response.data)
            if release.version > current {
                return .available(current: current, release: release)
            }
            return .upToDate(current: current, latest: release.version)
        } catch {
            return .unavailable(message: "The latest release metadata is invalid.")
        }
    }
}

public enum AppUpdateServiceError: Error, Equatable {
    case invalidResponse
}

public enum GitHubReleaseParser {
    public static func parse(_ data: Data) throws -> AppRelease {
        let payload: ReleasePayload
        do {
            payload = try JSONDecoder().decode(ReleasePayload.self, from: data)
        } catch {
            throw AppUpdateServiceError.invalidResponse
        }
        guard !payload.draft,
              !payload.prerelease,
              let version = SemanticVersion(payload.tagName),
              let releaseURL = URL(string: payload.htmlURL),
              releaseURL.scheme == "https",
              releaseURL.host?.lowercased() == "github.com" else {
            throw AppUpdateServiceError.invalidResponse
        }
        let name = payload.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = name.flatMap { $0.isEmpty ? nil : $0 } ?? "EvoBar v\(version)"
        return AppRelease(
            version: version,
            displayName: displayName,
            releasePageURL: releaseURL,
            publishedAt: payload.publishedAt.flatMap(parseDate)
        )
    }

    private static func parseDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }

    private struct ReleasePayload: Decodable {
        let tagName: String
        let name: String?
        let htmlURL: String
        let draft: Bool
        let prerelease: Bool
        let publishedAt: String?

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case name
            case htmlURL = "html_url"
            case draft
            case prerelease
            case publishedAt = "published_at"
        }
    }
}
