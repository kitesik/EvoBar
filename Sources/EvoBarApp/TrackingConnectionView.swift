import EvoBarCore
import EvoBarUsage
import SwiftUI

struct TrackingConnectionView: View {
    @ObservedObject var model: AppModel
    var allowsFolderSelection = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach([ProviderID.claudeCode, .codex], id: \.self) { provider in
                let report = model.trackingReports.first { $0.providerID == provider }
                let enabled = model.isTrackingEnabled(provider)
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: symbol(report, enabled: enabled))
                        .foregroundStyle(!enabled ? Color.secondary : report?.needsAttention == true ? .orange : EvoStyle.accent)
                        .frame(width: 16).padding(.top, 2)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(EvoStyle.providerName(provider)).font(.system(size: 12, weight: .semibold))
                        Text(detail(report, enabled: enabled))
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    if allowsFolderSelection {
                        Button { model.chooseLogFolder(providerID: provider) } label: {
                            Image(systemName: "folder.badge.plus")
                        }
                        .buttonStyle(.borderless)
                        .help(L10n.text("ui.tracking.chooseFolder", fallback: "Choose log folder"))
                        .accessibilityLabel(EvoStyle.providerName(provider) + ", " + L10n.text("ui.tracking.chooseFolder", fallback: "Choose log folder"))
                    }
                }
                .accessibilityElement(children: .contain)
            }
            if let checked = model.lastTrackingCheck {
                TimelineView(.periodic(from: .now, by: 30)) { _ in
                    (Text(L10n.text("ui.tracking.checked", fallback: "Last checked")) + Text(" ") + Text(checked, style: .relative))
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func symbol(_ report: ProviderTrackingReport?, enabled: Bool) -> String {
        if !enabled { return "pause.circle" }
        if report?.needsAttention == true { return "exclamationmark.circle" }
        return report?.isConnected == true ? "checkmark.circle.fill" : "clock"
    }

    private func detail(_ report: ProviderTrackingReport?, enabled: Bool) -> String {
        if !enabled { return L10n.text("ui.tracking.pausedDetail", fallback: "Paused. Your saved history is kept.") }
        guard let report else {
            return L10n.text("ui.tracking.checking", fallback: "Checking local usage logs…")
        }
        let state: String
        if report.issues.contains(.saveFailed) {
            state = L10n.text("ui.tracking.saveFailed", fallback: "Couldn't save new usage. Check available disk space, then retry.")
        } else if report.issues.contains(.permissionRequired) {
            state = L10n.text("ui.tracking.permission", fallback: "Some logs need access. Check folder permissions or choose another log folder.")
        } else if !report.issues.isEmpty {
            state = L10n.text("ui.tracking.readFailed", fallback: "Some logs couldn't be checked. Readable logs still count. Try refreshing.")
        } else if report.malformedLineCount > 0 {
            state = L10n.format("ui.tracking.skipped", fallback: "%lld unreadable lines skipped. Other usage was saved.", Int64(report.malformedLineCount))
        } else if report.sourceCount == 0 {
            return L10n.text("ui.tracking.noLogs", fallback: "No logs yet. Finish a session, then refresh.")
        } else {
            return L10n.format("ui.tracking.sources", fallback: "%lld log files connected", Int64(report.checkedSourceCount))
        }
        return state
    }
}

struct FirstSessionCard: View {
    @ObservedObject var model: AppModel

    var body: some View {
        EvoCard(tint: EvoStyle.accent) {
            VStack(alignment: .leading, spacing: 12) {
                Label(L10n.text("ui.tracking.firstTitle", fallback: "Your first chapter starts here"), systemImage: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                Text(L10n.text("ui.tracking.firstHint", fallback: "Use Claude Code or Codex for your usual work. When a response finishes, its usage helps your companion grow."))
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                TrackingConnectionView(model: model)
                HStack {
                    Button(L10n.text("Refresh now")) { model.refreshNow() }
                        .buttonStyle(EvoActionStyle()).disabled(model.isRefreshing)
                    Spacer(minLength: 4)
                    Button(L10n.text("ui.trackingSettings", fallback: "Tracking settings")) {
                        model.openSettings(page: .tracking)
                    }.buttonStyle(.plain).font(.system(size: 11))
                }
                if model.refreshIntervalMinutes == 0 {
                    Text(L10n.text("ui.tracking.manualHint", fallback: "Automatic refresh is off. Use Refresh now to collect new usage."))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}
