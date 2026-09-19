import EvoBarInfrastructure
import Testing

@Suite @MainActor struct RefreshWorkerTests {
    @Test func overlappingTriggersProduceOneSerialFollowUp() async {
        let entered = Gate()
        let release = Gate()
        var calls: [Bool] = []
        var active = 0
        var peak = 0
        let worker = RefreshWorker { force in
            active += 1
            peak = max(peak, active)
            calls.append(force)
            if calls.count == 1 {
                await entered.open()
                await release.wait()
            }
            active -= 1
        }
        worker.request()
        await entered.wait()
        for _ in 0..<25 { worker.request() }
        worker.request(force: true)
        worker.request()
        await release.open()
        await worker.waitUntilIdle()
        #expect(calls == [false, true])
        #expect(peak == 1)
    }

    @Test func restartWaitsForCancelledWorkToDrain() async {
        let entered = Gate()
        let release = Gate()
        var cancellations: [Bool] = []
        var calls = 0
        let worker = RefreshWorker { _ in
            calls += 1
            if calls == 1 {
                await entered.open()
                await release.wait()
            }
            cancellations.append(Task.isCancelled)
        }
        worker.request()
        await entered.wait()
        worker.cancel()
        worker.request()
        #expect(calls == 1)
        await release.open()
        await worker.waitUntilIdle()
        #expect(cancellations == [true, false])
    }

    @Test func stopDropsQueuedRefreshesBeforeReset() async {
        let entered = Gate()
        let release = Gate()
        var calls = 0
        let worker = RefreshWorker { _ in
            calls += 1
            await entered.open()
            await release.wait()
        }
        worker.request()
        await entered.wait()
        worker.request(force: true)
        worker.cancel()
        await release.open()
        await worker.waitUntilIdle()
        #expect(calls == 1)
    }
}

private actor Gate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { waiters.append($0) }
    }
    func open() {
        isOpen = true
        for waiter in waiters { waiter.resume() }
        waiters.removeAll()
    }
}
