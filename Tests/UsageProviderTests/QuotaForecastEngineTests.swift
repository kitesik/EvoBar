import EvoBarCore
import EvoBarUsage
import Foundation
import Testing

@Suite struct QuotaForecastEngineTests {
    @Test func projectsExhaustionFromPositiveBurnRateBeforeReset() throws {
        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        let reset = start.addingTimeInterval(8 * 60 * 60)
        let previous = sample(utilization: 0.2, capturedAt: start, resetsAt: reset)
        let current = sample(
            utilization: 0.4,
            capturedAt: start.addingTimeInterval(60 * 60),
            resetsAt: reset
        )
        let projected = try #require(QuotaForecastEngine.projectedExhaustion(
            current: current,
            previous: previous
        ))
        #expect(abs(projected.timeIntervalSince(
            current.capturedAt.addingTimeInterval(3 * 60 * 60)
        )) < 0.001)
    }

    @Test func suppressesProjectionAfterResetOrAcrossResetEpoch() {
        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        let soonReset = start.addingTimeInterval(2 * 60 * 60)
        let previous = sample(utilization: 0.2, capturedAt: start, resetsAt: soonReset)
        let current = sample(
            utilization: 0.4,
            capturedAt: start.addingTimeInterval(60 * 60),
            resetsAt: soonReset
        )
        #expect(QuotaForecastEngine.projectedExhaustion(current: current, previous: previous) == nil)

        let newEpoch = sample(
            utilization: 0.1,
            capturedAt: start.addingTimeInterval(2 * 60 * 60),
            resetsAt: start.addingTimeInterval(10 * 60 * 60)
        )
        #expect(QuotaForecastEngine.projectedExhaustion(current: newEpoch, previous: current) == nil)
    }

    @Test func resetCountdownNeverBecomesNegative() {
        let now = Date(timeIntervalSinceReferenceDate: 10_000)
        let window = QuotaWindow(
            providerID: .codex,
            name: "5-hour",
            utilization: 0.5,
            resetsAt: now.addingTimeInterval(-1),
            projectedExhaustionAt: nil,
            freshness: .fresh
        )
        #expect(QuotaForecastEngine.resetCountdown(for: window, now: now) == 0)
    }

    @Test func monitorKeepsLastGoodSnapshotAsStaleAfterFailure() async throws {
        let service = ToggleQuotaService()
        let monitor = QuotaMonitor(services: [service])
        let first = await monitor.refresh()
        #expect(first.providers.first?.freshness == .fresh)
        #expect(first.providers.first?.windows.count == 1)

        await service.failNext()
        let second = await monitor.refresh()
        #expect(second.providers.first?.freshness == .stale)
        #expect(second.providers.first?.windows.count == 1)
    }

    @Test func alertEvaluatorDeduplicatesEachLevelWithinResetEpoch() {
        let reset = Date(timeIntervalSinceReferenceDate: 20_000)
        var evaluator = QuotaAlertEvaluator()
        let warning = dashboard(utilization: 0.81, resetsAt: reset)
        #expect(evaluator.newAlerts(for: warning).map(\.level) == [.warning])
        #expect(evaluator.newAlerts(for: warning).isEmpty)

        let critical = dashboard(utilization: 0.96, resetsAt: reset)
        #expect(evaluator.newAlerts(for: critical).map(\.level) == [.critical])
        #expect(evaluator.newAlerts(for: critical).isEmpty)
    }

    private func sample(
        utilization: Double,
        capturedAt: Date,
        resetsAt: Date
    ) -> QuotaWindowSample {
        QuotaWindowSample(
            providerID: .codex,
            windowID: "five-hour",
            name: "5-hour",
            utilization: utilization,
            resetsAt: resetsAt,
            capturedAt: capturedAt
        )
    }

    private func dashboard(utilization: Double, resetsAt: Date) -> QuotaDashboardSnapshot {
        QuotaDashboardSnapshot(
            generatedAt: Date(),
            providers: [
                ProviderQuotaStatus(
                    providerID: .codex,
                    windows: [
                        QuotaWindow(
                            providerID: .codex,
                            name: "5-hour",
                            utilization: utilization,
                            resetsAt: resetsAt,
                            projectedExhaustionAt: nil,
                            freshness: .fresh
                        ),
                    ],
                    freshness: .fresh
                ),
            ]
        )
    }
}

private actor ToggleQuotaService: QuotaService {
    nonisolated let providerID = ProviderID.codex
    private var shouldFail = false

    func failNext() { shouldFail = true }

    func fetchQuota() throws -> ProviderQuotaSnapshot {
        if shouldFail {
            shouldFail = false
            throw QuotaServiceError.transport(code: "fixture")
        }
        let now = Date()
        return ProviderQuotaSnapshot(
            providerID: providerID,
            windows: [
                QuotaWindowSample(
                    providerID: providerID,
                    windowID: "weekly",
                    name: "Weekly",
                    utilization: 0.5,
                    resetsAt: now.addingTimeInterval(3600),
                    capturedAt: now
                ),
            ],
            capturedAt: now,
            freshness: .fresh
        )
    }
}
