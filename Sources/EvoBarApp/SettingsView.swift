import EvoBarCore
import SwiftUI

enum SettingsPage: String, CaseIterable, Identifiable {
  case general, companion, tracking, data
  var id: String { rawValue }
  var title: String {
    switch self {
    case .general: L10n.text("ui.general", fallback: "General")
    case .companion: L10n.text("ui.companion", fallback: "Companion")
    case .tracking: L10n.text("Tracking")
    case .data: L10n.text("ui.dataPrivacy", fallback: "Data")
    }
  }
}

struct SettingsView: View {
  @ObservedObject var model: AppModel
  @State private var isShowingResetConfirmation = false
  @State private var isShowingPrivacyDetails = false
  @State private var claudeLogPattern = ""
  @State private var codexLogPattern = ""

  private var page: SettingsPage { model.selectedSettingsPage }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 3) {
        Text(L10n.text("Settings")).font(.system(size: 21, weight: .bold, design: .rounded))
        Text(L10n.text("ui.settingsSubtitle", fallback: "Make a little space for your companion."))
          .font(.system(size: 11)).foregroundStyle(.secondary)
      }
      .padding(.horizontal, EvoStyle.inset)
      Picker(L10n.text("Settings"), selection: $model.selectedSettingsPage) {
        ForEach(SettingsPage.allCases) { Text($0.title).tag($0) }
      }
      .pickerStyle(.segmented).labelsHidden()
      .padding(.horizontal, EvoStyle.inset)

      ScrollView {
        VStack(spacing: 12) {
          switch page {
          case .general: generalSettings
          case .companion: companionSettings
          case .tracking: trackingSettings
          case .data: dataSettings
          }
          if let message = model.settingsMessage {
            Text(message).font(.caption).foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
        .padding(.horizontal, EvoStyle.inset)
        .padding(.bottom, EvoStyle.inset)
      }
      .scrollIndicators(.hidden)
      .id(page)
    }
    .toggleStyle(EvoSettingsToggleStyle())
    .controlSize(.small)
    .alert("Reset all EvoBar data?", isPresented: $isShowingResetConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Reset permanently", role: .destructive) {
        model.resetLocalData()
      }
    } message: {
      Text(
        "This cannot be undone. EvoBar will return to Welcome and rescan only usage created after the new companion is born."
      )
    }
    .sheet(isPresented: $isShowingPrivacyDetails) {
      PrivacyDetailsView()
    }
  }

  private var generalSettings: some View {
    VStack(spacing: 12) {
      EvoSettingsSection(
        title: L10n.text("ui.appearance", fallback: "Appearance"), icon: "menubar.rectangle"
      ) {
        Toggle(
          "Show token, cost, and quota in menu bar",
          isOn: Binding(
            get: { model.showTokenInMenuBar },
            set: { model.setShowTokenInMenuBar($0) }
          ))
        Toggle(
          "Show token and model breakdown",
          isOn: Binding(
            get: { model.showTokenBreakdown },
            set: { model.setShowTokenBreakdown($0) }
          ))
        Picker(
          "Animation quality",
          selection: Binding(
            get: { model.animationQuality },
            set: { model.setAnimationQuality($0) }
          )
        ) {
          ForEach(AnimationQuality.allCases) { quality in
            Text(quality.displayName).tag(quality)
          }
        }
      }
      EvoSettingsSection(title: L10n.text("System"), icon: "power") {
        Toggle(
          "Launch EvoBar at login",
          isOn: Binding(
            get: { model.launchAtLoginEnabled },
            set: { model.setLaunchAtLoginEnabled($0) }
          ))
      }
      EvoSettingsSection(title: L10n.text("Updates"), icon: "arrow.down.circle") {
        Toggle(
          "Automatically check GitHub Releases",
          isOn: Binding(
            get: { model.automaticUpdateChecksEnabled },
            set: { model.setAutomaticUpdateChecksEnabled($0) }
          ))
        HStack {
          Text("Installed \(model.installedVersion)")
          Spacer()
          Button(model.isCheckingForUpdates ? "Checking…" : "Check now") {
            model.checkForUpdates()
          }
          .disabled(model.isCheckingForUpdates)
        }
        Text(model.updateStatusText)
          .font(.caption)
          .foregroundStyle(.secondary)
        if let updateURL = model.availableUpdateURL {
          Link("Open latest release", destination: updateURL)
        }
        Text(
          "Uses the public GitHub Releases API. EvoBar opens the release page and never installs an update silently."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
  }

  private var companionSettings: some View {
    VStack(spacing: 12) {
      EvoSettingsSection(title: L10n.text("Desktop companion"), icon: "pawprint") {
        Toggle(
          "Show floating desktop pet",
          isOn: Binding(
            get: { model.desktopPetEnabled },
            set: { model.setDesktopPetEnabled($0) }
          ))
        Picker(
          "Pinned animal",
          selection: Binding(
            get: { model.pinnedAnimalDefinitionID },
            set: { model.setPinnedAnimalDefinitionID($0) }
          )
        ) {
          Text("Growing companion").tag(nil as AnimalDefinitionID?)
          ForEach(ownedAnimals) { animal in
            Text("\(animal.menuBarEmoji) \(L10n.animal(animal))")
              .tag(animal.id as AnimalDefinitionID?)
          }
        }
        HStack {
          Text("Size")
          Slider(
            value: Binding(
              get: { model.desktopPetSize },
              set: { model.setDesktopPetSize($0) }
            ), in: 48...192, step: 8)
          Text("\(Int(model.desktopPetSize)) px")
            .font(.caption.monospacedDigit())
            .frame(width: 48, alignment: .trailing)
        }
        Text("Drag the pet anywhere. Hover for today's usage and right-click for actions.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      EvoSettingsSection(title: L10n.text("Notifications"), icon: "bell") {
        Toggle(
          "Companion evolution events",
          isOn: Binding(
            get: { model.companionNotificationsEnabled },
            set: { model.setCompanionNotificationsEnabled($0) }
          ))
        Toggle(
          "Warning and critical notifications",
          isOn: Binding(
            get: { model.quotaNotificationsEnabled },
            set: { model.setQuotaNotificationsEnabled($0) }
          ))
        Text(
          "Permission is requested only when enabled. Companion alerts cover evolution readiness, completed evolutions, final form, new and shiny companions, and coin milestones, each announced once. Quota warnings are sent at 80% and 95% once per reset window."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
  }
  private var trackingSettings: some View {
    VStack(spacing: 12) {
      EvoSettingsSection(title: L10n.text("Tracking"), icon: "waveform.path") {
        Toggle(
          "Claude Code",
          isOn: Binding(
            get: { model.claudeTrackingEnabled },
            set: { model.setTrackingEnabled($0, providerID: .claudeCode) }
          ))
        Toggle(
          "Codex",
          isOn: Binding(
            get: { model.codexTrackingEnabled },
            set: { model.setTrackingEnabled($0, providerID: .codex) }
          ))
        Picker(
          "Refresh",
          selection: Binding(
            get: { model.refreshIntervalMinutes },
            set: { model.setRefreshIntervalMinutes($0) }
          )
        ) {
          Text("Manual").tag(0)
          ForEach(1...15, id: \.self) { minutes in
            Text("\(minutes) min").tag(minutes)
          }
        }
        Button(model.isRefreshing ? "Refreshing…" : "Refresh now") {
          model.refreshNow()
        }
        .disabled(model.isRefreshing)
      }
      EvoSettingsSection(title: L10n.text("Provider status"), icon: "checkmark.shield") {
        Toggle(
          "Check official Claude and OpenAI status",
          isOn: Binding(
            get: { model.providerStatusChecksEnabled },
            set: { model.setProviderStatusChecksEnabled($0) }
          ))
        Text(
          "When enabled, EvoBar checks the providers' public status JSON at most once every five minutes. No local usage data is attached."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
      EvoSettingsSection(title: L10n.text("Additional log locations"), icon: "folder") {
        logPatternEditor(
          title: "Claude Code",
          placeholder: "~/archive/*/.claude/projects",
          value: $claudeLogPattern,
          patterns: model.claudeAdditionalLogPatterns,
          providerID: .claudeCode
        )
        logPatternEditor(
          title: "Codex",
          placeholder: "/Volumes/Work/**/.codex/sessions",
          value: $codexLogPattern,
          patterns: model.codexAdditionalLogPatterns,
          providerID: .codex
        )
        Text(
          "Supports * and **. EvoBar scans matching folders for JSONL files; wildcard traversal from / is blocked."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
      EvoSettingsSection(title: L10n.text("Usage bands"), icon: "chart.bar") {
        bandStepper("Steady from", index: 0, step: 0.5)
        bandStepper("Heavy from", index: 1, step: 1)
        bandStepper("Extreme from", index: 2, step: 5)
        Text("Values are millions of tokens per day. Higher bands heat up the Today tile.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
  private var dataSettings: some View {
    VStack(spacing: 12) {
      EvoSettingsSection(title: L10n.text("About"), icon: "info.circle") {
        Text("EvoBar \(model.installedVersion), a local-first AI companion")
        Text("No account. No analytics backend.").foregroundStyle(.secondary)
        Button("Privacy details…") {
          isShowingPrivacyDetails = true
        }
      }
      EvoSettingsSection(title: L10n.text("Local data"), icon: "externaldrive") {
        Button("Export aggregate data…") {
          model.exportLocalData()
        }
        Button("Reset all local data…", role: .destructive) {
          isShowingResetConfirmation = true
        }
        .disabled(model.isResettingData)
        Text("Deletes companions, growth, usage aggregates, and scan history from this Mac.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }

  private func bandStepper(_ title: LocalizedStringKey, index: Int, step: Double) -> some View {
    let millions = Double(model.usageBandThresholds[index]) / 1_000_000
    return Stepper(
      value: Binding(
        get: { millions },
        set: { model.setUsageBandThreshold(index: index, millions: $0) }
      ),
      in: 0.5...5_000,
      step: step
    ) {
      HStack {
        Text(title)
        Spacer()
        Text("\(millions.formatted()) M")
          .monospacedDigit()
          .foregroundStyle(.secondary)
      }
    }
  }

  private func logPatternEditor(
    title: String,
    placeholder: String,
    value: Binding<String>,
    patterns: [String],
    providerID: ProviderID
  ) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title).font(.caption.bold())
      HStack {
        TextField(placeholder, text: value)
          .textFieldStyle(.roundedBorder)
        Button("Add") {
          model.addLogPattern(value.wrappedValue, providerID: providerID)
          value.wrappedValue = ""
        }
        .disabled(value.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      ForEach(patterns, id: \.self) { pattern in
        HStack {
          Text(pattern).font(.caption.monospaced()).lineLimit(1)
          Spacer()
          Button {
            model.removeLogPattern(pattern, providerID: providerID)
          } label: {
            Image(systemName: "xmark.circle.fill")
          }
          .buttonStyle(.borderless)
          .help(L10n.text("ui.removePath", fallback: "Remove log location"))
          .accessibilityLabel(L10n.text("ui.removePath", fallback: "Remove log location"))
        }
      }
    }
  }

  private var ownedAnimals: [AnimalDefinition] {
    (model.catalog?.animals ?? [])
      .filter { model.ownedAnimalIDs.contains($0.id) }
      .sorted { $0.sortOrder < $1.sortOrder }
  }
}

struct PrivacyDetailsView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.companionPanelSize) private var panelSize

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Label("Privacy", systemImage: "lock.shield.fill")
          .font(.title2.bold())
        Spacer()
        Button("Done") { dismiss() }
          .keyboardShortcut(.cancelAction)
      }
      .padding()

      Divider()

      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          privacySection(
            title: "Local-first by design",
            body:
              "Animal history, settings, usage aggregates, and scan checkpoints stay on this Mac. EvoBar has no account or analytics backend."
          )
          privacySection(
            title: "Usage metadata only",
            body:
              "EvoBar uses token counts, timestamps, provider, model, and a session identifier needed for accurate deduplication."
          )
          privacySection(
            title: "Content is never collected",
            body:
              "Prompts, responses, code, project contents, and raw JSONL lines are never stored, exported, logged, or transmitted."
          )
          privacySection(
            title: "Limited network access",
            body:
              "Optional network requests check official provider status and public GitHub Releases. Local usage data is never attached."
          )
          privacySection(
            title: "You control your data",
            body:
              "Settings can export privacy-filtered aggregates or permanently reset all local EvoBar data at any time."
          )
        }
        .padding(20)
      }
    }
    .frame(width: min(480, panelSize.width), height: min(500, panelSize.height))
    .background(EvoStyle.background)
  }

  private func privacySection(title: String, body: String) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(L10n.text(title)).font(.headline)
      Text(L10n.text(body))
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct EvoSettingsToggleStyle: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 12) {
      configuration.label
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityHidden(true)
      Toggle(isOn: configuration.$isOn) { configuration.label }
        .labelsHidden()
        .toggleStyle(.switch)
    }
    .frame(minHeight: 24)
  }
}

private struct EvoSettingsSection<Content: View>: View {
  let title: String
  let icon: String
  @ViewBuilder let content: Content

  var body: some View {
    EvoCard {
      VStack(alignment: .leading, spacing: 12) {
        Label(title, systemImage: icon)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(EvoStyle.accent)
        Divider()
        content
          .font(.system(size: 12))
      }
    }
  }
}
