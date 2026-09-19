import Foundation

/// Serializes refresh triggers, retaining one follow-up when changes arrive
/// during a scan. Cancelling keeps the slot occupied until the old work drains.
@MainActor
public final class RefreshWorker {
    private var task: Task<Void, Never>?
    private var pendingForce: Bool?
    private let operation: @MainActor (Bool) async -> Void

    public init(operation: @escaping @MainActor (Bool) async -> Void) {
        self.operation = operation
    }

    public func request(force: Bool = false) {
        guard task == nil else {
            pendingForce = (pendingForce ?? false) || force
            return
        }
        task = Task { [weak self] in
            guard let self else { return }
            await operation(force)
            task = nil
            if let force = pendingForce {
                pendingForce = nil
                request(force: force)
            }
        }
    }

    public func cancel() {
        pendingForce = nil
        task?.cancel()
    }

    public func waitUntilIdle() async {
        while let task { await task.value }
    }
}
