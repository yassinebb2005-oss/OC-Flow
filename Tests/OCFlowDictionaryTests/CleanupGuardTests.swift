import Foundation
import Testing

@testable import OCFlowDictionary

/// The two jobs of the guard pull against each other: let a real cleanup through, and stop a
/// model that answered the transcript instead of cleaning it. Every case here is one or the
/// other, so a change that loosens the guard shows up as an answered question getting
/// through rather than as a green run.
struct CleanupGuardTests {

    // MARK: - Cleanups that must pass

    @Test func passesFillerRemoval() {
        let verdict = CleanupGuard.check(
            original: "ähm also ich wollte sagen dass der Termin halt am Mittwoch ist",
            cleaned: "Ich wollte sagen, dass der Termin am Mittwoch ist."
        )
        #expect(verdict == .plausible)
    }

    /// The case that was silently failing: the instructions ask for split compounds to be
    /// rejoined, and the token-set test then read the joined word as invented.
    @Test func passesRejoinedCompound() {
        let verdict = CleanupGuard.check(
            original: "ich schick dir den Kosten Voranschlag für das Zweit Haar noch heute",
            cleaned: "Ich schick dir den Kostenvoranschlag für das Zweithaar noch heute."
        )
        #expect(verdict == .plausible)
    }

    @Test func passesThreePartCompound() {
        let verdict = CleanupGuard.check(
            original: "die Kunden Termin Bestätigung ist raus",
            cleaned: "Die Kundenterminbestätigung ist raus."
        )
        #expect(verdict == .plausible)
    }

    /// The other direction: the engine glued a compound together and the model split it.
    @Test func passesSplitCompound() {
        let verdict = CleanupGuard.check(
            original: "der Haarsystemtermin steht",
            cleaned: "Der Haarsystem Termin steht."
        )
        #expect(verdict == .plausible)
    }

    // MARK: - Responses that must be rejected

    /// The development case. "Paris" cannot be assembled from anything the speaker said.
    @Test func rejectsAnsweredQuestion() {
        let verdict = CleanupGuard.check(
            original: "what is the capital of france",
            cleaned: "The capital of France is Paris."
        )
        #expect(verdict == .invented(["paris"]))
    }

    /// A welded word only counts when the parts were adjacent in the input, otherwise any
    /// two spoken words could license a third.
    @Test func rejectsWeldOfNonAdjacentWords() {
        let verdict = CleanupGuard.check(
            original: "Haar bitte kurz System",
            cleaned: "Haarsystem bitte."
        )
        #expect(verdict == .invented(["haarsystem"]))
    }

    @Test func rejectsTruncation() {
        let verdict = CleanupGuard.check(
            original: "bitte schick den Vertrag heute noch an die Krankenkasse in Hamburg",
            cleaned: "Vertrag."
        )
        guard case .lengthRatio(let ratio) = verdict else {
            Issue.record("expected a length verdict, got \(verdict)")
            return
        }
        #expect(ratio < 0.35)
    }

    /// An English preamble in front of German text trips the invented-words check before the
    /// prefix list is ever consulted. Both verdicts reject, so what matters here is that the
    /// response does not get through.
    @Test func rejectsPreamble() {
        let verdict = CleanupGuard.check(
            original: "der Termin ist am Mittwoch",
            cleaned: "Here's the cleaned transcript: Der Termin ist am Mittwoch."
        )
        #expect(verdict == .invented(["here", "cleaned", "transcript"]))
    }

    /// The prefix list earns its place when the preamble uses only words the speaker said,
    /// which is the one shape the invented-words check waves through.
    @Test func rejectsCommentary() {
        let verdict = CleanupGuard.check(
            original: "sure certainly here is the cleaned transcript of the meeting",
            cleaned: "Here is the cleaned transcript of the meeting."
        )
        #expect(verdict == .commentary)
    }

    /// Known limitation, written down rather than discovered later: the guard polices the
    /// word list, so a cleanup that re-conjugates a verb ("schick" to "schicke") reads as
    /// invented content and falls back to the rule-based formatter. Tightening this would
    /// mean stemming German, which is a much larger promise than the guard makes.
    @Test func rejectsReconjugation() {
        let verdict = CleanupGuard.check(
            original: "ich schick dir das heute noch",
            cleaned: "Ich schicke dir das heute noch."
        )
        #expect(verdict == .invented(["schicke"]))
    }

    // MARK: - Hinzugefügte Auszeichnung

    /// Der Fall aus dem Feld: „Das ist jetzt mit KI" kam als „Das ist jetzt mit **KI**"
    /// zurück und landete mit Sternchen im Textfeld.
    @Test func stripsBoldTheModelAdded() {
        let plain = CleanupGuard.strippingAddedEmphasis(
            from: "Das ist jetzt mit **KI**.",
            original: "das ist jetzt mit ki"
        )
        #expect(plain == "Das ist jetzt mit KI.")
    }

    @Test func stripsSingleAsterisks() {
        let plain = CleanupGuard.strippingAddedEmphasis(
            from: "Der Termin ist *heute*.",
            original: "der Termin ist heute"
        )
        #expect(plain == "Der Termin ist heute.")
    }

    /// Ein gesprochenes Sternchen bleibt stehen, sonst würde das Aufräumen Inhalt löschen.
    @Test func keepsAsterisksTheSpeakerDictated() {
        let text = "Der Preis steht in Zeile *2*."
        #expect(CleanupGuard.strippingAddedEmphasis(from: text, original: "Preis in Zeile *2*") == text)
    }

    @Test func leavesTextWithoutAsterisksAlone() {
        let text = "Der Termin ist am Mittwoch."
        #expect(CleanupGuard.strippingAddedEmphasis(from: text, original: "termin am mittwoch") == text)
    }

    /// Unterstriche sind gewöhnliche Zeichen in Dateinamen, die fasst der Filter nicht an.
    @Test func leavesUnderscoresAlone() {
        let text = "Die Datei heißt kunden_liste_final."
        #expect(CleanupGuard.strippingAddedEmphasis(from: text, original: "datei kunden_liste_final") == text)
    }

    @Test func rejectsEmptyResponse() {
        #expect(CleanupGuard.check(original: "der Termin ist am Mittwoch", cleaned: "") == .unusable)
    }

    @Test func rejectsEmptyInput() {
        #expect(CleanupGuard.check(original: "   ", cleaned: "Der Termin.") == .unusable)
    }
}
