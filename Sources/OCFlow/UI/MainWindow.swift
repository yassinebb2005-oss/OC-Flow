import OCFlowDictionary
import AppKit
import SwiftUI

/// The app's main window.
///
/// Three bands: the mark and the push-to-talk hint at the top, the record strip below it,
/// then the selected section filling the rest. Nothing competes with the transcript list —
/// it is the only thing anyone opens this window to read.
struct MainWindow: View {
    @Bindable var controller: DictationController

    @State private var section: Section = .transcriptions
    @State private var settings = Settings.shared

    enum Section: String, CaseIterable, Identifiable {
        case transcriptions
        case dictionary

        var id: String { rawValue }
        var title: String { self == .transcriptions ? "Aufnahmen" : "Wörterbuch" }
    }

    var body: some View {
        ZStack {
            DS.Color.chassis.ignoresSafeArea()

            VStack(spacing: DS.Space.roomy) {
                masthead

                TransportPanel(controller: controller)

                sectionSwitcher

                Well(radius: DS.Radius.panel) {
                    Group {
                        switch section {
                        case .transcriptions: TranscriptionList()
                        case .dictionary: DictionaryPanel()
                        }
                    }
                    .padding(DS.Space.hair)
                }
                .frame(maxHeight: .infinity)
            }
            .padding(DS.Space.wide)
            .padding(.top, -DS.Space.roomy)
        }
        .frame(minWidth: 720, minHeight: 520)
    }

    /// The mark, the wordmark, and the one instruction that matters.
    ///
    /// No leading inset: the traffic lights live in the strip above this row, so the mark
    /// aligns with the content edge like every other element.
    private var masthead: some View {
        HStack(alignment: .center, spacing: DS.Space.snug) {
            OCMark()
                .fill(DS.Color.ink)
                .frame(width: 44, height: 18)

            Text("Flow")
                .font(DS.Font.title)
                .foregroundStyle(DS.Color.ink)

            Spacer()

            HStack(spacing: DS.Space.snug) {
                KeycapHint(label: settings.pushToTalkKey.displayName)
                Text("halten und sprechen")
                    .font(DS.Font.label)
                    .foregroundStyle(DS.Color.inkSecondary)
            }

            SettingsLink {
                Image(systemName: "gearshape")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.Color.inkSecondary)
                    .frame(width: 28, height: 28)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .help("Einstellungen")
        }
        .padding(.horizontal, DS.Space.hair)
    }

    /// A single capsule with a sliding thumb — one control, not a row of buttons.
    private var sectionSwitcher: some View {
        HStack {
            SegmentedPill(selection: $section)
            Spacer()
        }
    }
}

/// The section toggle, shaped like the one on the Wispr Flow site: a capsule track with a
/// raised thumb that slides between segments.
private struct SegmentedPill: View {
    @Binding var selection: MainWindow.Section
    @Namespace private var thumb

    var body: some View {
        HStack(spacing: DS.Space.hair) {
            ForEach(MainWindow.Section.allCases) { candidate in
                let isSelected = selection == candidate
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        selection = candidate
                    }
                } label: {
                    Text(candidate.title)
                        .font(DS.Font.bodyEmphasis)
                        .foregroundStyle(isSelected ? DS.Color.ink : DS.Color.inkSecondary)
                        .padding(.horizontal, DS.Space.roomy)
                        .frame(height: 30)
                        .background {
                            if isSelected {
                                Capsule(style: .continuous)
                                    .fill(DS.Color.cap)
                                    .overlay {
                                        Capsule(style: .continuous)
                                            .strokeBorder(DS.Color.seam, lineWidth: DS.Border.hairline)
                                    }
                                    .shadow(color: .black.opacity(0.10), radius: 3, y: 1)
                                    .matchedGeometryEffect(id: "thumb", in: thumb)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DS.Space.tight)
        .background {
            Capsule(style: .continuous)
                .fill(DS.Color.well)
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(DS.Color.seam, lineWidth: DS.Border.hairline)
                }
        }
    }
}

// MARK: - Transport

/// The record strip: the round record control, the same flowing line the HUD draws, and a
/// counter that only speaks up while something is being recorded.
private struct TransportPanel: View {
    @Bindable var controller: DictationController

    @State private var elapsed: TimeInterval = 0
    @State private var startedAt: Date?

    private var isRecording: Bool { controller.state.isActive }

    var body: some View {
        HStack(spacing: DS.Space.wide) {
            RecordButton(isRecording: isRecording) {
                if isRecording {
                    controller.stopButtonRecording()
                } else {
                    controller.startButtonRecording()
                }
            }

            // The same line as the HUD. One listening signal across the whole product —
            // whoever has seen the pill already knows how to read this.
            FlowLine(
                level: controller.level,
                phase: phase,
                ink: DS.Color.ink,
                inkDim: DS.Color.recordIdle
            )
            .frame(maxWidth: .infinity)

            Text(counterText)
                .font(DS.Font.counterLarge)
                .foregroundStyle(isRecording ? DS.Color.ink : DS.Color.recordIdle)
                .animation(DS.Motion.hover, value: isRecording)
        }
        .padding(.horizontal, DS.Space.wide)
        .padding(.vertical, DS.Space.roomy)
        .background(BrushedPanel())
        .onChange(of: controller.state.isActive) { _, active in
            startedAt = active ? Date() : nil
            if !active { elapsed = 0 }
        }
        .task(id: startedAt) {
            guard let startedAt else { return }
            while !Task.isCancelled {
                elapsed = Date().timeIntervalSince(startedAt)
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    private var phase: FlowPhase {
        switch controller.state {
        case .listening, .starting: .live
        case .finishing: .settling
        case .idle, .error: .rest
        }
    }

    /// Minutes and seconds, zero-padded.
    private var counterText: String {
        let total = Int(elapsed)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

// MARK: - Transcriptions

/// Past transcriptions, searchable, each copyable.
private struct TranscriptionList: View {
    @State private var store = RunStore.shared
    @State private var query = ""
    @State private var isConfirmingClear = false

    private var runs: [DictationRun] {
        let all = store.runs.reversed().map { $0 }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return all }
        return all.filter { $0.text.localizedStandardContains(trimmed) }
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchField(text: $query, placeholder: "Aufnahmen durchsuchen")
                .padding(.horizontal, DS.Space.base)
                .padding(.top, DS.Space.base)

            if runs.isEmpty {
                EmptyPanel(
                    label: store.runs.isEmpty ? "Keine Aufnahmen" : "Nichts gefunden",
                    detail: store.runs.isEmpty
                        ? "Halte die Sprechtaste in irgendeiner App — oder drück oben auf Aufnehmen."
                        : "Such nach etwas anderem."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: DS.Space.snug) {
                        ForEach(runs) { run in
                            TranscriptionRow(run: run) {
                                withAnimation(DS.Motion.panel) { RunLog.delete(run) }
                            }
                        }
                    }
                    .padding(DS.Space.base)
                }
                footer
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("\(store.runs.count) \(store.runs.count == 1 ? "Aufnahme" : "Aufnahmen")")
                .font(DS.Font.caption)
                .foregroundStyle(DS.Color.inkSecondary)
            Spacer()
            Button("Alle löschen") { isConfirmingClear = true }
                .buttonStyle(.plain)
                .font(DS.Font.caption)
                .foregroundStyle(DS.Color.inkSecondary)
        }
        .padding(.horizontal, DS.Space.roomy)
        .padding(.vertical, DS.Space.snug)
        // Confirmed, unlike a single row: one row is trivially re-recorded, the whole
        // history is not, and there's no undo.
        .confirmationDialog(
            "Alle \(store.runs.count) Aufnahmen löschen?",
            isPresented: $isConfirmingClear,
            titleVisibility: .visible
        ) {
            Button("Alle löschen", role: .destructive) { RunLog.clear() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Das lässt sich nicht rückgängig machen.")
        }
    }
}

private struct TranscriptionRow: View {
    let run: DictationRun
    let onDelete: () -> Void

    @State private var didCopy = false
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.snug) {
            // The text leads. It's the thing being scanned for; engine and timing are
            // bookkeeping and sit underneath in the quiet row.
            Text(run.text)
                .font(DS.Font.body)
                .foregroundStyle(DS.Color.ink)
                .lineSpacing(2)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: DS.Space.snug) {
                Kicker(text: run.engine)
                Text(String(format: "%.2fs", run.processSeconds))
                    .font(DS.Font.counter)
                    .foregroundStyle(DS.Color.inkSecondary)
                Text(run.date, format: .relative(presentation: .named))
                    .font(DS.Font.caption)
                    .foregroundStyle(DS.Color.inkSecondary)
                Spacer()
            }

            if let corrections = run.corrections, !corrections.isEmpty {
                CorrectionBadges(corrections: corrections)
            }
        }
        .padding(DS.Space.roomy)
        .background {
            RoundedRectangle(cornerRadius: DS.Radius.panel, style: .continuous)
                .fill(isHovering ? DS.Color.panelHighlight : DS.Color.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: DS.Radius.panel, style: .continuous)
                        .strokeBorder(DS.Color.seam, lineWidth: DS.Border.hairline)
                }
                .shadow(color: .black.opacity(isHovering ? 0.08 : 0.03), radius: isHovering ? 8 : 3, y: 2)
        }
        // Actions live in the top-right corner and only exist while the pointer is here.
        // A hundred rows of always-visible buttons is a control panel, not a history.
        .overlay(alignment: .topTrailing) {
            if isHovering {
                HStack(spacing: DS.Space.hair) {
                    IconButton(
                        systemImage: didCopy ? "checkmark" : "doc.on.doc",
                        help: "Kopieren"
                    ) {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(run.text, forType: .string)
                        didCopy = true
                        Task {
                            try? await Task.sleep(for: .seconds(1.4))
                            didCopy = false
                        }
                    }
                    IconButton(systemImage: "trash", help: "Diese Aufnahme löschen", action: onDelete)
                }
                .padding(DS.Space.snug)
                .transition(.opacity)
            }
        }
        .onHover { hovering in
            withAnimation(DS.Motion.hover) { isHovering = hovering }
        }
    }
}

/// Shows that the dictionary fired, and on what. Without this the dictionary is invisible
/// and you can't tell a rule that works from one that never matches.
private struct CorrectionBadges: View {
    let corrections: [AppliedCorrection]

    var body: some View {
        HStack(spacing: DS.Space.snug) {
            Kicker(text: "Korrigiert")
            ForEach(corrections, id: \.self) { correction in
                HStack(spacing: DS.Space.tight) {
                    Text(correction.from)
                        .strikethrough()
                        .foregroundStyle(DS.Color.inkSecondary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(DS.Color.inkSecondary)
                    Text(correction.to)
                        .foregroundStyle(DS.Color.ink)
                    if correction.count > 1 {
                        Text("×\(correction.count)")
                            .foregroundStyle(DS.Color.inkSecondary)
                    }
                }
                .font(DS.Font.caption)
                .padding(.horizontal, DS.Space.snug)
                .padding(.vertical, DS.Space.tight)
                .background {
                    Capsule(style: .continuous)
                        .fill(DS.Color.well)
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(DS.Color.seam, lineWidth: DS.Border.hairline)
                        }
                }
            }
            Spacer()
        }
    }
}

// MARK: - Shared

struct SearchField: View {
    @Binding var text: String
    let placeholder: String

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: DS.Space.snug) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DS.Color.inkSecondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(DS.Font.body)
                .foregroundStyle(DS.Color.ink)
                .focused($isFocused)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.inkSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DS.Space.base)
        .frame(height: 32)
        .background {
            Capsule(style: .continuous)
                .fill(DS.Color.panel)
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(
                            isFocused ? DS.Color.focusRing.opacity(0.6) : DS.Color.seam,
                            lineWidth: isFocused ? 1 : DS.Border.hairline
                        )
                }
        }
        .animation(DS.Motion.hover, value: isFocused)
    }
}

struct EmptyPanel: View {
    let label: String
    let detail: String

    var body: some View {
        VStack(spacing: DS.Space.base) {
            OCMark()
                .fill(DS.Color.recordIdle)
                .frame(width: 56, height: 22)
            VStack(spacing: DS.Space.tight) {
                Text(label)
                    .font(DS.Font.bodyEmphasis)
                    .foregroundStyle(DS.Color.ink)
                Text(detail)
                    .font(DS.Font.label)
                    .foregroundStyle(DS.Color.inkSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
