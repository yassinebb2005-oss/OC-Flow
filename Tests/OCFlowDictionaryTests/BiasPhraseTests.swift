import Foundation
import Testing

@testable import OCFlowDictionary

/// Biasing has 40 slots and no error message. If corrections eat them, the words that only
/// biasing can help — domain terms the engine has never heard of — are simply never offered
/// to the recognizer, and nothing anywhere says so. These tests are that error message.
struct BiasPhraseTests {

    @Test func termsComeBeforeCorrections() {
        let entries: [DictionaryEntry] = [
            .correction(hear: "git hub", write: "GitHub"),
            .term("Zweithaar"),
        ]
        #expect(DictionaryCorrector.biasPhrases(from: entries) == ["Zweithaar", "GitHub"])
    }

    /// The regression. The shipped vocabulary has more corrections than there are slots, so
    /// with corrections first every term fell off the end.
    @Test func shippedTermsReachTheEngine() {
        let phrases = DictionaryCorrector.biasPhrases(from: BuiltinVocabulary.entries)
        #expect(phrases.count == DictionaryCorrector.biasLimit)
        #expect(phrases.contains("Zweithaar"))
        #expect(phrases.contains("Haarsystem"))
        #expect(phrases.contains("O.C. Hairsystems"))
    }

    @Test func honoursTheLimit() {
        let entries = (1...80).map { DictionaryEntry.term("Wort\($0)") }
        #expect(DictionaryCorrector.biasPhrases(from: entries).count == DictionaryCorrector.biasLimit)
    }

    @Test func skipsDisabledAndDuplicateEntries() {
        let entries: [DictionaryEntry] = [
            .term("Zweithaar"),
            DictionaryEntry(kind: .term, write: "zweithaar"),
            DictionaryEntry(kind: .term, write: "Toupet", isEnabled: false),
        ]
        #expect(DictionaryCorrector.biasPhrases(from: entries) == ["Zweithaar"])
    }
}
