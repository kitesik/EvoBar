import EvoBarCore
import EvoBarUsage
import Foundation
import Testing

@Suite struct ProviderStatusServiceTests {
    @Test(arguments: [
        ("none", ProviderServiceCondition.operational),
        ("minor", ProviderServiceCondition.degraded),
        ("major", ProviderServiceCondition.outage),
        ("critical", ProviderServiceCondition.outage),
        ("future-value", ProviderServiceCondition.unknown),
    ])
    func mapsStatuspageIndicators(
        indicator: String,
        expected: ProviderServiceCondition
    ) {
        #expect(StatuspageStatusParser.condition(for: indicator) == expected)
    }

    @Test func parsesStatuspagePayloadWithoutIncidentContent() throws {
        let checkedAt = Date(timeIntervalSinceReferenceDate: 42)
        let data = Data(#"{"status":{"description":"Partial System Degradation","indicator":"minor"}}"#.utf8)
        let result = try StatuspageStatusParser.parse(
            data: data,
            providerID: .codex,
            statusPageURL: URL(string: "https://status.openai.com/")!,
            checkedAt: checkedAt
        )

        #expect(result.condition == .degraded)
        #expect(result.summary == "Partial System Degradation")
        #expect(result.checkedAt == checkedAt)
        #expect(result.freshness == .fresh)
    }

    @Test func rejectsMalformedOrEmptyStatuspagePayload() {
        let url = URL(string: "https://status.example.com/")!
        #expect(throws: ProviderStatusServiceError.invalidResponse) {
            try StatuspageStatusParser.parse(
                data: Data("not-json".utf8),
                providerID: .codex,
                statusPageURL: url,
                checkedAt: Date()
            )
        }
        #expect(throws: ProviderStatusServiceError.invalidResponse) {
            try StatuspageStatusParser.parse(
                data: Data(#"{"status":{"description":"  ","indicator":"none"}}"#.utf8),
                providerID: .codex,
                statusPageURL: url,
                checkedAt: Date()
            )
        }
    }

    @Test func monitorKeepsLastGoodStatusAsStaleAfterFailure() async {
        let service = ToggleProviderStatusService()
        let monitor = ProviderStatusMonitor(services: [service], minimumRefreshInterval: 0)

        let first = await monitor.refresh()
        #expect(first.providers.first?.condition == .degraded)
        #expect(first.providers.first?.freshness == .fresh)

        await service.failNext()
        let second = await monitor.refresh(force: true)
        #expect(second.providers.first?.condition == .degraded)
        #expect(second.providers.first?.freshness == .stale)
    }
}

private actor ToggleProviderStatusService: ProviderStatusService {
    nonisolated let providerID = ProviderID.codex
    nonisolated let statusPageURL = URL(string: "https://status.openai.com/")!
    private var shouldFail = false

    func failNext() { shouldFail = true }

    func fetchStatus() throws -> ProviderOperationalStatus {
        if shouldFail {
            shouldFail = false
            throw ProviderStatusServiceError.transport
        }
        return ProviderOperationalStatus(
            providerID: providerID,
            condition: .degraded,
            summary: "Partial System Degradation",
            statusPageURL: statusPageURL,
            checkedAt: Date(),
            freshness: .fresh
        )
    }
}
