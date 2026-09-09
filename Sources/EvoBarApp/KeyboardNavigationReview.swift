#if DEBUG
import AppKit
import SwiftUI

/// Sends AppKit key equivalents directly to an isolated, hidden dashboard.
/// This verifies SwiftUI shortcut routing, not physical input or VoiceOver.
@MainActor
enum KeyboardNavigationReview {
    static func verify(model: AppModel) async throws {
        guard model.isIsolatedRun else { return }
        model.prepareVisualReview()
        model.selectedSection = .settings
        let individuals = model.animalInstances
        let entitlements = model.activeProductIDs
        let xp = model.currentXP
        let coins = model.tokenCoins
        let controller = NSHostingController(rootView: RootPopoverView(model: model))
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 420, height: 700),
            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentViewController = controller
        defer {
            window.contentViewController = nil
            window.close()
            model.prepareVisualReview()
            model.selectedSection = .home
        }
        controller.view.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(100))

        let shortcuts: [(String, UInt16, AppSection)] = [
            ("2", 19, .usage), ("3", 20, .collection), ("4", 21, .shop),
            ("1", 18, .home), (",", 43, .settings)
        ]
        for (characters, keyCode, section) in shortcuts {
            let handled = window.performKeyEquivalent(with: try event(
                characters, keyCode: keyCode, modifiers: .command, window: window))
            try await Task.sleep(for: .milliseconds(100))
            guard handled, model.selectedSection == section else {
                // Fixed test labels only; no input or model records are logged.
                FileHandle.standardError.write(Data("Shortcut review failed: Command-\(characters).\n".utf8))
                throw Failure.shortcutNotRouted
            }
            if section == .collection {
                let searchHandled = window.performKeyEquivalent(with: try event(
                    "f", keyCode: 3, modifiers: .command, window: window))
                try await Task.sleep(for: .milliseconds(100))
                guard searchHandled, let editor = window.firstResponder as? NSTextView,
                      editor.isFieldEditor else {
                    FileHandle.standardError.write(Data("Shortcut review failed: Collection search focus.\n".utf8))
                    throw Failure.searchNotFocused
                }
                editor.insertText("evobar-fixture-search-no-match", replacementRange: NSRange(location: NSNotFound, length: 0))
                try await Task.sleep(for: .milliseconds(50))
                guard editor.string == "evobar-fixture-search-no-match" else { throw Failure.searchNotEdited }
                window.sendEvent(try event("\u{1b}", keyCode: 53, modifiers: [], window: window))
                try await Task.sleep(for: .milliseconds(100))
                guard editor.string.isEmpty else {
                    FileHandle.standardError.write(Data("Shortcut review failed: Escape clears Collection search.\n".utf8))
                    throw Failure.searchNotCleared
                }
            }
        }
        _ = window.performKeyEquivalent(with: try event("2", keyCode: 19, modifiers: [], window: window))
        try await Task.sleep(for: .milliseconds(50))
        guard model.selectedSection == .settings, !window.isVisible else { throw Failure.unexpectedNavigation }
        guard model.animalInstances == individuals, model.activeProductIDs == entitlements,
              model.currentXP == xp, model.tokenCoins == coins else { throw Failure.companionChanged }
    }

    private static func event(
        _ characters: String, keyCode: UInt16, modifiers: NSEvent.ModifierFlags, window: NSWindow
    ) throws -> NSEvent {
        guard let event = NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: modifiers,
            timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
            context: nil, characters: characters, charactersIgnoringModifiers: characters,
            isARepeat: false, keyCode: keyCode
        ) else { throw Failure.eventUnavailable }
        return event
    }

    private enum Failure: Error {
        case eventUnavailable, shortcutNotRouted, searchNotFocused, searchNotEdited, searchNotCleared
        case unexpectedNavigation, companionChanged
    }
}
#endif
