import EvoBarInfrastructure
import Foundation
import Testing

@Suite struct AppUpdateServiceTests {
    @Test func semanticVersionOrderingHandlesReleaseAndPrerelease() throws {
        let alpha = try #require(SemanticVersion("v1.2.3-alpha.2"))
        let beta = try #require(SemanticVersion("1.2.3-beta.1+build.9"))
        let release = try #require(SemanticVersion("1.2.3"))
        let next = try #require(SemanticVersion("1.2.4"))

        #expect(alpha < beta)
        #expect(beta < release)
        #expect(release < next)
        #expect(release.description == "1.2.3")
        #expect(SemanticVersion("1.2") == nil)
        #expect(SemanticVersion("01.2.3") == nil)
        #expect(SemanticVersion("1.2.3-alpha.01") == nil)
        #expect(SemanticVersion("1.2.3-한글") == nil)
    }

    @Test func serviceReportsNewPublicReleaseAndSendsVersionedHeaders() async throws {
        let data = Data(#"""
        {
          "tag_name":"v0.2.0",
          "name":"EvoBar 0.2",
          "html_url":"https://github.com/kitesik/EvoBar/releases/tag/v0.2.0",
          "draft":false,
          "prerelease":false,
          "published_at":"2026-09-04T01:02:03Z"
        }
        """#.utf8)
        let fetcher = StubHTTPDataFetcher(response: HTTPDataResponse(data: data, statusCode: 200))
        let service = GitHubReleaseUpdateService(
            owner: "kitesik",
            repository: "EvoBar",
            fetcher: fetcher
        )

        let state = await service.check(currentVersion: "0.1.0")
        guard case .available(let current, let release) = state else {
            Issue.record("Expected an available update, got \(state)")
            return
        }
        #expect(current == SemanticVersion("0.1.0"))
        #expect(release.version == SemanticVersion("0.2.0"))
        #expect(release.displayName == "EvoBar 0.2")

        let request = try #require(await fetcher.capturedRequest())
        #expect(request.url?.absoluteString == "https://api.github.com/repos/kitesik/EvoBar/releases/latest")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/vnd.github+json")
        #expect(request.value(forHTTPHeaderField: "X-GitHub-Api-Version") == "2022-11-28")
        #expect(request.value(forHTTPHeaderField: "User-Agent") == "EvoBar/0.1.0")
    }

    @Test func serviceHandlesCurrentVersionAndMissingPublicRelease() async {
        let releaseData = Data(#"""
        {
          "tag_name":"v0.1.0",
          "name":null,
          "html_url":"https://github.com/kitesik/EvoBar/releases/tag/v0.1.0",
          "draft":false,
          "prerelease":false,
          "published_at":null
        }
        """#.utf8)
        let currentService = GitHubReleaseUpdateService(
            owner: "kitesik",
            repository: "EvoBar",
            fetcher: StubHTTPDataFetcher(response: HTTPDataResponse(data: releaseData, statusCode: 200))
        )
        #expect(await currentService.check(currentVersion: "0.1.0") == .upToDate(
            current: SemanticVersion("0.1.0")!,
            latest: SemanticVersion("0.1.0")!
        ))

        let missingService = GitHubReleaseUpdateService(
            owner: "kitesik",
            repository: "EvoBar",
            fetcher: StubHTTPDataFetcher(response: HTTPDataResponse(data: Data(), statusCode: 404))
        )
        #expect(await missingService.check(currentVersion: "0.1.0") == .unavailable(
            message: "No public GitHub release is available yet."
        ))
    }

    @Test func parserRejectsUnsafeReleaseURLAndPrerelease() {
        let unsafe = Data(#"""
        {
          "tag_name":"v9.0.0",
          "name":"Not EvoBar",
          "html_url":"https://example.com/download",
          "draft":false,
          "prerelease":false,
          "published_at":null
        }
        """#.utf8)
        #expect(throws: AppUpdateServiceError.invalidResponse) {
            try GitHubReleaseParser.parse(unsafe)
        }

        let prerelease = Data(#"""
        {
          "tag_name":"v0.2.0-beta.1",
          "name":"Beta",
          "html_url":"https://github.com/kitesik/EvoBar/releases/tag/v0.2.0-beta.1",
          "draft":false,
          "prerelease":true,
          "published_at":null
        }
        """#.utf8)
        #expect(throws: AppUpdateServiceError.invalidResponse) {
            try GitHubReleaseParser.parse(prerelease)
        }
    }
}

private actor StubHTTPDataFetcher: HTTPDataFetching {
    private let stubbedResponse: HTTPDataResponse
    private var request: URLRequest?

    init(response: HTTPDataResponse) {
        self.stubbedResponse = response
    }

    func response(for request: URLRequest) -> HTTPDataResponse {
        self.request = request
        return stubbedResponse
    }

    func capturedRequest() -> URLRequest? { request }
}
