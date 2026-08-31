import OCFlowDictionary
import Foundation
import Observation

/// The dictionary, persisted as a plain text file you can edit by hand.
///
/// A text file rather than JSON, because the spec asks for something editable outside the UI
/// and JSON is only nominally that — quoting, escaping and a trailing-comma trap for anyone
/// adding a line in a hurry. The format is one entry per line:
///
/// ```
/// Anthropic
/// Vercel
/// cloud code -> Claude Code
/// # off: whisper flow -> Wispr Flow
/// ```
///
/// A bare line is a term. `X -> Y` is a correction. `#` starts a comment, and a disabled
/// entry is written as a `# off:` comment so it survives a round trip through the file
/// without silently disappearing.
///
/// The file is watched, so editing it in a text editor updates the UI live and vice versa.
@MainActor
@Observable
final class DictionaryStore {
    static let shared = DictionaryStore()

    private(set) var entries: [DictionaryEntry] = []

    /// Bumped whenever entries change, so the engine can rebuild its bias list lazily
    /// instead of on every transcription.
    private(set) var revision = 0

    private var watcher: DispatchSourceFileSystemObject?
    /// Set while we're writing, so our own save doesn't read back as an external edit.
    private var isSaving = false

    static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("OCFlow", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("dictionary.txt")
    }

    private init() {
        load()
        seedStarterEntries()
        startWatching()
    }

    // MARK: - Starter entries

    /// Office and engineering vocabulary the recognizer reliably mangles in German
    /// dictation. Seeded once, additively: entries the user already has are left alone,
    /// and anything seeded can be edited or deleted like a hand-made entry. Terms bias
    /// the engine toward hearing the word at all; corrections catch what still slips
    /// through, and one multi-part trigger like "git hub" also matches "github" and
    /// "Git-Hub", so each line covers every spelling the engine produces.
    private static let starterEntries: [DictionaryEntry] = [
        // Tools und Dienste — Korrekturen normalisieren die Schreibweise.
        .correction(hear: "git hub", write: "GitHub"),
        .correction(hear: "git lab", write: "GitLab"),
        .correction(hear: "ripo", write: "Repo"),
        .correction(hear: "repo", write: "Repo"),
        .correction(hear: "pull request", write: "Pull Request"),
        .correction(hear: "readme", write: "README"),
        .correction(hear: "api", write: "API"),
        .correction(hear: "json", write: "JSON"),
        .correction(hear: "mac os", write: "macOS"),
        .correction(hear: "i phone", write: "iPhone"),
        .correction(hear: "i pad", write: "iPad"),
        .correction(hear: "chat gpt", write: "ChatGPT"),
        .correction(hear: "cloud code", write: "Claude Code"),
        .correction(hear: "g mail", write: "Gmail"),
        .correction(hear: "google drive", write: "Google Drive"),
        .correction(hear: "power point", write: "PowerPoint"),
        .correction(hear: "linked in", write: "LinkedIn"),
        .correction(hear: "whats app", write: "WhatsApp"),
        .correction(hear: "you tube", write: "YouTube"),
        .correction(hear: "xcode", write: "Xcode"),
        .correction(hear: "vs code", write: "VS Code"),
        .correction(hear: "type script", write: "TypeScript"),
        .correction(hear: "java script", write: "JavaScript"),
        .correction(hear: "oc flow", write: "OC Flow"),
        // Eingedeutschte Verben, die die Erkennung phonetisch verschreibt.
        .correction(hear: "puschen", write: "pushen"),
        .correction(hear: "gepuscht", write: "gepusht"),
        .correction(hear: "kommitten", write: "committen"),
        .correction(hear: "kommittet", write: "committet"),
        .correction(hear: "kommitte", write: "committe"),
        // "Jason" ist auch ein Vorname — deshalb aus, aber einschaltbar.
        DictionaryEntry(kind: .correction, write: "JSON", hear: "jason", isEnabled: false),
        // Begriffe: reine Engine-Vorprägung, damit richtig gehört wird.
        .term("GitHub"), .term("Repo"), .term("Pull Request"), .term("Branch"),
        .term("Commit"), .term("committen"), .term("pushen"), .term("mergen"),
        .term("deployen"), .term("Backend"), .term("Frontend"), .term("Terminal"),
        .term("Slack"), .term("Claude"), .term("OC Flow"), .term("O.C. Hairsystems"),
    ]

    /// Runs once per Mac. Additive and conservative: an entry whose trigger or word the
    /// user already has — in any spelling — is skipped, so a hand-tuned dictionary stays
    /// hand-tuned.
    private func seedStarterEntries() {
        let seededKey = "dictionarySeededV1"
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        defer { UserDefaults.standard.set(true, forKey: seededKey) }

        let existingWrites = Set(entries.map { $0.write.lowercased() })
        let existingHears = Set(entries.compactMap { $0.hear.isEmpty ? nil : $0.hear.lowercased() })

        let fresh = Self.starterEntries.filter { seed in
            !existingWrites.contains(seed.write.lowercased())
                && (seed.hear.isEmpty || !existingHears.contains(seed.hear.lowercased()))
        }
        guard !fresh.isEmpty else { return }
        entries.append(contentsOf: fresh)
        save()
    }

    // MARK: - Editing

    func add(_ entry: DictionaryEntry) {
        entries.append(entry)
        save()
    }

    func update(_ entry: DictionaryEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index] = entry
        save()
    }

    func delete(_ entry: DictionaryEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func delete(ids: Set<UUID>) {
        entries.removeAll { ids.contains($0.id) }
        save()
    }

    /// Case- and diacritic-insensitive search across both sides of an entry.
    func filtered(by query: String) -> [DictionaryEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return entries }
        return entries.filter {
            $0.write.localizedStandardContains(trimmed) || $0.hear.localizedStandardContains(trimmed)
        }
    }

    /// A corrector over the current entries. Rebuilt on demand — compiling a few dozen small
    /// regexes is cheap next to transcription, and caching it invites staleness.
    var corrector: DictionaryCorrector { DictionaryCorrector(entries: entries) }

    var biasPhrases: [String] { DictionaryCorrector.biasPhrases(from: entries) }

    // MARK: - Persistence

    private func load() {
        guard let text = try? String(contentsOf: Self.fileURL, encoding: .utf8) else {
            entries = []
            revision += 1
            return
        }
        entries = Self.parse(text)
        revision += 1
    }

    static func parse(_ text: String) -> [DictionaryEntry] {
        text.split(separator: "\n", omittingEmptySubsequences: false).compactMap { rawLine in
            var line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { return nil }

            // `# off:` is a disabled entry; any other comment is just a comment.
            var isEnabled = true
            if line.hasPrefix("#") {
                let stripped = line.dropFirst().trimmingCharacters(in: .whitespaces)
                guard stripped.lowercased().hasPrefix("off:") else { return nil }
                line = stripped.dropFirst(4).trimmingCharacters(in: .whitespaces)
                isEnabled = false
                guard !line.isEmpty else { return nil }
            }

            if let arrow = line.range(of: "->") {
                let hear = line[..<arrow.lowerBound].trimmingCharacters(in: .whitespaces)
                let write = line[arrow.upperBound...].trimmingCharacters(in: .whitespaces)
                guard !hear.isEmpty, !write.isEmpty else { return nil }
                return DictionaryEntry(kind: .correction, write: write, hear: hear, isEnabled: isEnabled)
            }

            return DictionaryEntry(kind: .term, write: line, isEnabled: isEnabled)
        }
    }

    private func save() {
        revision += 1
        isSaving = true
        defer { isSaving = false }

        let body = entries.map(\.fileLine).joined(separator: "\n")
        let text = Self.header + body + "\n"
        try? text.write(to: Self.fileURL, atomically: true, encoding: .utf8)
    }

    private static let header = """
        # OC Flow dictionary
        #
        #   Anthropic                 a term — the engine is told this word exists
        #   cloud code -> Claude Code a correction — when you hear X, write Y
        #   # off: some rule -> Rule  a disabled entry
        #
        # Edit this file directly if you like; the app picks up changes immediately.

        """

    // MARK: - External edits

    /// Watches the file so a hand edit shows up in the UI without a relaunch.
    ///
    /// Rearms after every event: an atomic write replaces the inode, so the descriptor we
    /// were watching is gone the moment the file changes — including when *we* save.
    private func startWatching() {
        watcher?.cancel()

        let descriptor = open(Self.fileURL.path, O_EVTONLY)
        guard descriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .delete, .rename, .extend],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }
            if !self.isSaving { self.load() }
            self.startWatching()
        }
        source.setCancelHandler { close(descriptor) }
        source.resume()

        watcher = source
    }
}
