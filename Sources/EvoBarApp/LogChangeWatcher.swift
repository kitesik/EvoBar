import CoreServices
import Foundation

/// Watches provider log roots with FSEvents so usage refreshes when a JSONL file
/// is appended instead of waiting for the next polling interval.
@MainActor
final class LogChangeWatcher {
    static var defaultRoots: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent(".claude/projects", isDirectory: true),
            home.appendingPathComponent(".codex/sessions", isDirectory: true),
        ].filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    // Released from the nonisolated deinit; the stream is only ever touched on main.
    nonisolated(unsafe) private var stream: FSEventStreamRef?
    private var pending: DispatchWorkItem?
    private let onChange: @MainActor () -> Void

    init?(roots: [URL], onChange: @escaping @MainActor () -> Void) {
        guard !roots.isEmpty else { return nil }
        self.onChange = onChange

        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()
        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            let watcher = Unmanaged<LogChangeWatcher>.fromOpaque(info).takeUnretainedValue()
            Task { @MainActor in watcher.scheduleChange() }
        }
        guard let stream = FSEventStreamCreate(
            nil,
            callback,
            &context,
            roots.map(\.path) as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagNoDefer | kFSEventStreamCreateFlagFileEvents)
        ) else { return nil }
        self.stream = stream
        FSEventStreamSetDispatchQueue(stream, .main)
        FSEventStreamStart(stream)
    }

    // ponytail: fixed 1.5 s debounce; a burst of appends collapses into one rescan.
    private func scheduleChange() {
        pending?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.onChange() }
        pending = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: item)
    }

    deinit {
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }
}
