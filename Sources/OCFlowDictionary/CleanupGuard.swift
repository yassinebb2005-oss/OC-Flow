import Foundation

/// Decides whether a cleanup response is recognizably a cleaned version of its input.
///
/// The failure this defends against is real and was reproduced during development: dictate
/// "what is the capital of france" and the model helpfully returns "The capital of France is
/// Paris.", which would then be typed into the user's document.
///
/// The load-bearing check is **novel content words**, not length. Cleanup is a subtractive
/// operation: it deletes fillers, fixes punctuation, and applies spoken corrections. It has
/// essentially no reason to introduce a content word that wasn't spoken. "Paris" never
/// appears in the input, so it's the tell.
///
/// The one thing cleanup legitimately does to the word list is **rewelding compounds**.
/// German speech-to-text splits them ("Kosten Voranschlag", "Zweit Haar") and the cleanup
/// instructions ask for them to be rejoined, which produces a word that is in no sense
/// novel but is not in the input's token set either. A plain set test rejected every such
/// response and silently fell back to the rule-based formatter, so compounds are checked
/// against the input rather than against nothing: a token counts as explained when it is the
/// concatenation of adjacent input tokens, or when adjacent cleaned tokens concatenate to an
/// input token. That leaves the Paris case exactly as rejected as before, because "Paris"
/// cannot be assembled from anything the speaker said.
///
/// Lives in the dictionary target purely so it can be tested; it has no dictionary state.
public enum CleanupGuard {
    /// How many input tokens may be welded into one, or split out of one.
    ///
    /// Two covers the common German compound and three covers the occasional
    /// "Kunden Termin Bestätigung". Beyond that the response is not re-punctuating a
    /// compound any more.
    private static let maxWeld = 3

    public enum Verdict: Equatable, Sendable {
        case plausible
        /// The response was empty, or the input had no content words to compare against.
        case unusable
        /// Words in the response that the input cannot account for.
        case invented([String])
        /// Response length against the filler-discounted input.
        case lengthRatio(Double)
        /// The model started talking about the task instead of doing it.
        case commentary
    }

    public static func check(original: String, cleaned: String) -> Verdict {
        guard !cleaned.isEmpty else { return .unusable }

        let originalTokens = contentWords(original)
        let cleanedTokens = contentWords(cleaned)
        guard !originalTokens.isEmpty else { return .unusable }

        // 1. No invented content. The single strongest signal that the model answered
        //    rather than transformed.
        let invented = unexplainedWords(originalTokens: originalTokens, cleanedTokens: cleanedTokens)
        guard invented.isEmpty else { return .invented(invented) }

        // 2. Length sanity, as a backstop for the case where the model obeys an injected
        //    instruction using only words from the input ("write the word banana" → "Banana").
        //
        //    Measured against the *filler-discounted* input, not the raw one. A raw ratio
        //    conflates "the model truncated my sentence" with "the input was 80% filler and
        //    was legitimately cut in half" — with a raw denominator those two land at 0.14
        //    and 0.21, too close to separate. Discounting fillers on both sides pushes the
        //    real cleanups to 0.6–1.0 and leaves the failures below 0.2.
        let ratio = Double(cleanedTokens.count) / Double(max(1, spokenWordCount(original)))
        guard ratio >= 0.35, ratio <= 1.5 else { return .lengthRatio(ratio) }

        // 3. A model that starts explaining itself has stopped being a text processor.
        let lowered = cleaned.lowercased()
        return tells.contains { lowered.hasPrefix($0) } ? .commentary : .plausible
    }

    /// Cleaned words the input cannot account for, in order of appearance.
    ///
    /// Walks the response rather than filtering it, because a split compound is only
    /// explained by looking at the tokens next to it.
    static func unexplainedWords(originalTokens: [String], cleanedTokens: [String]) -> [String] {
        let vocabulary = Set(originalTokens)
        let welds = weldedForms(of: originalTokens)

        var unexplained: [String] = []
        var index = cleanedTokens.startIndex

        while index < cleanedTokens.endIndex {
            let token = cleanedTokens[index]

            // Spoken as-is, or two adjacent input words welded into one compound.
            if vocabulary.contains(token) || welds.contains(token) {
                index += 1
                continue
            }

            // Or the other direction: the model split one input compound into pieces.
            if let width = splitWidth(of: cleanedTokens, from: index, matching: vocabulary) {
                index += width
                continue
            }

            unexplained.append(token)
            index += 1
        }

        return unexplained
    }

    /// Every concatenation of 2...`maxWeld` adjacent input tokens.
    private static func weldedForms(of tokens: [String]) -> Set<String> {
        var forms: Set<String> = []
        for start in tokens.indices {
            for width in 2...maxWeld where start + width <= tokens.count {
                forms.insert(tokens[start..<(start + width)].joined())
            }
        }
        return forms
    }

    /// How many cleaned tokens from `start` concatenate to a single input token, if any.
    private static func splitWidth(
        of cleanedTokens: [String],
        from start: Int,
        matching vocabulary: Set<String>
    ) -> Int? {
        for width in 2...maxWeld where start + width <= cleanedTokens.count {
            let joined = cleanedTokens[start..<(start + width)].joined()
            if vocabulary.contains(joined) { return width }
        }
        return nil
    }

    /// Lowercased alphanumeric words, minus the function words that punctuation-fixing
    /// legitimately shuffles. Contractions are split so "isn't" matches "isn t".
    private static func contentWords(_ text: String) -> [String] {
        text.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { !stopWords.contains($0) }
    }

    /// Content words minus conversational filler — an estimate of how much the speaker
    /// actually *said*, used as the denominator for the length check.
    private static func spokenWordCount(_ text: String) -> Int {
        contentWords(text).count { !fillerWords.contains($0) }
    }

    /// Deliberately small. Every word here is one the guard stops policing, so it only
    /// covers words a cleanup pass may genuinely insert or drop while re-punctuating.
    private static let stopWords: Set<String> = [
        "a", "an", "the", "and", "or", "but", "so", "then", "s", "t", "re", "ll", "ve", "d", "m",
    ]

    /// Broader than the rule-based formatter's strip list on purpose. This set only affects
    /// the length check's denominator — it never removes anything from the user's text — so
    /// it can afford to be aggressive about discourse markers that the LLM legitimately
    /// deletes.
    private static let fillerWords: Set<String> = [
        "um", "uh", "erm", "uhm", "hmm", "mhm", "like", "basically", "actually", "literally",
        "just", "really", "okay", "ok", "well", "right", "anyway", "i", "mean", "you", "know",
        "kind", "sort", "of", "stuff", "thing", "things",
    ]

    private static let tells = [
        "here's the cleaned", "here is the cleaned", "cleaned transcript",
        "sure,", "certainly,", "i cannot", "i can't", "as an ai",
    ]
}
