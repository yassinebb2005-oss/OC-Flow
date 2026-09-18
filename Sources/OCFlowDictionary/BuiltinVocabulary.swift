import Foundation

/// Vocabulary the app ships with: the trade's own words, plus office and engineering terms
/// the German recognizer reliably mangles.
///
/// Deliberately not part of the user's dictionary file. The dictionary UI stays personal —
/// what the user put there, nothing else — while this layer works underneath. It is not
/// hidden in effect: every fired correction still shows up as a "Korrigiert" badge on the
/// transcript, and a user entry with the same trigger or word replaces the built-in one
/// (`DictionaryStore` filters on collision), so any rule here can be overridden by hand.
///
/// **The two kinds cost different things, so they have different budgets.**
///
/// A `.correction` runs after transcription, as a regex over the finished text. It is
/// effectively free: a few hundred of them cost single-digit milliseconds, and they cannot
/// influence what the engine hears. The list below can grow as long as it is useful. The
/// only real risk is a badly chosen trigger, so every trigger here is either a phonetic
/// mangling that is not a German word, or a multi-word phrase — never a bare word someone
/// might legitimately dictate.
///
/// A `.term` competes for the engine's context list, which is capped at
/// `DictionaryCorrector.biasLimit` because these models start inventing text from a long
/// priming list on quiet audio. Terms are therefore rationed, and spent on words the engine
/// would otherwise never consider: trade vocabulary and product names. A word that a
/// correction already repairs does not need a term as well.
public enum BuiltinVocabulary {
    public static let entries: [DictionaryEntry] = terms + corrections

    // MARK: - Terms (bias budget)

    /// Words the engine gets primed with so it hears them at all. Ordered by how unlikely
    /// the engine is to produce them unaided — the trade's own vocabulary first, because
    /// nothing downstream can recover a word that was never in the running.
    private static let terms: [DictionaryEntry] = [
        // Zweithaar — das Kerngeschäft. Kein Erkenner kennt diese Wörter von Haus aus.
        "Zweithaar", "Haarsystem", "Haarersatz", "Haarintegration", "Haarverdichtung",
        "Echthaar", "Kunsthaar", "Remy-Haar", "Eigenhaar", "Haarteil", "Toupet",
        "Monofilament", "Tresse", "Bonding", "Haaransatz", "Haarlinie", "Knotung",
        // Firma und Produkt
        "O.C. Hairsystems", "OC Flow",
        // Entwicklung — nur was keine Korrektur ohnehin repariert
        "Repo", "Branch", "Commit", "Pull Request", "Merge Request",
        "committen", "pushen", "mergen", "deployen", "rebasen",
        "Staging", "Endpoint", "Webhook", "Deployment",
    ].map { .term($0) }

    // MARK: - Corrections (unbounded)

    /// When you hear X, write Y. Casing fixes and phonetic repairs, applied after
    /// transcription. Triggers are mishearings or multi-word phrases, never bare German
    /// words — word-boundary matching protects "Zoom" from "zoomen", but nothing protects
    /// a trigger that is itself a word someone might mean.
    private static let corrections: [DictionaryEntry] =
        hairIndustry + engineering + officeAndTools + socialAndMarketing + abbreviations

    /// Zweithaar. The phonetic manglings here are what the engine actually produces for
    /// German trade words — the reason this layer exists at all.
    private static let hairIndustry: [DictionaryEntry] = [
        .correction(hear: "zweit haar", write: "Zweithaar"),
        .correction(hear: "zweiter haar", write: "Zweithaar"),
        .correction(hear: "haar system", write: "Haarsystem"),
        .correction(hear: "haar systeme", write: "Haarsysteme"),
        .correction(hear: "haar ersatz", write: "Haarersatz"),
        .correction(hear: "haar integration", write: "Haarintegration"),
        .correction(hear: "haar verdichtung", write: "Haarverdichtung"),
        .correction(hear: "echt haar", write: "Echthaar"),
        .correction(hear: "kunst haar", write: "Kunsthaar"),
        .correction(hear: "remy haar", write: "Remy-Haar"),
        .correction(hear: "eigen haar", write: "Eigenhaar"),
        .correction(hear: "haar teil", write: "Haarteil"),
        .correction(hear: "haar ansatz", write: "Haaransatz"),
        .correction(hear: "haar linie", write: "Haarlinie"),
        .correction(hear: "haar ausfall", write: "Haarausfall"),
        .correction(hear: "haar wurzel", write: "Haarwurzel"),
        .correction(hear: "kopf haut", write: "Kopfhaut"),
        .correction(hear: "geheimrats ecken", write: "Geheimratsecken"),
        .correction(hear: "hair piece", write: "Hairpiece"),
        .correction(hear: "hair system", write: "Hair System"),
        .correction(hear: "hair replacement", write: "Hair Replacement"),
        .correction(hear: "lace front", write: "Lace Front"),
        .correction(hear: "skin base", write: "Skin Base"),
        .correction(hear: "mono filament", write: "Monofilament"),
        .correction(hear: "farb ring", write: "Farbring"),
        .correction(hear: "beratungs termin", write: "Beratungstermin"),
        .correction(hear: "erst termin", write: "Ersttermin"),
        .correction(hear: "nach termin", write: "Nachtermin"),
    ]

    /// Entwicklung. The verbs matter most: German conjugations of English verbs are what
    /// the recognizer mangles hardest, because they exist in neither language's model.
    private static let engineering: [DictionaryEntry] = [
        // Plattformen und Artefakte
        .correction(hear: "git hub", write: "GitHub"),
        .correction(hear: "git lab", write: "GitLab"),
        .correction(hear: "ripo", write: "Repo"),
        .correction(hear: "repo", write: "Repo"),
        .correction(hear: "repositorium", write: "Repository"),
        .correction(hear: "pull request", write: "Pull Request"),
        .correction(hear: "merge request", write: "Merge Request"),
        .correction(hear: "pull rikwest", write: "Pull Request"),
        .correction(hear: "code review", write: "Code Review"),
        .correction(hear: "readme", write: "README"),
        .correction(hear: "changelog", write: "Changelog"),
        .correction(hear: "branch", write: "Branch"),
        .correction(hear: "brantsch", write: "Branch"),
        .correction(hear: "main branch", write: "Main-Branch"),
        .correction(hear: "feature branch", write: "Feature-Branch"),
        // Eingedeutschte Verben — der häufigste Fehlerfall
        .correction(hear: "puschen", write: "pushen"),
        .correction(hear: "gepuscht", write: "gepusht"),
        .correction(hear: "puschst", write: "pushst"),
        .correction(hear: "kommitten", write: "committen"),
        .correction(hear: "kommittet", write: "committet"),
        .correction(hear: "kommitte", write: "committe"),
        .correction(hear: "commited", write: "committet"),
        .correction(hear: "mörgen", write: "mergen"),
        .correction(hear: "gemerged", write: "gemergt"),
        .correction(hear: "deployen", write: "deployen"),
        .correction(hear: "deployt", write: "deployt"),
        .correction(hear: "ri base", write: "Rebase"),
        .correction(hear: "ri basen", write: "rebasen"),
        .correction(hear: "pullen", write: "pullen"),
        .correction(hear: "klonen", write: "klonen"),
        // Technik
        .correction(hear: "api", write: "API"),
        .correction(hear: "end point", write: "Endpoint"),
        .correction(hear: "web hook", write: "Webhook"),
        .correction(hear: "json", write: "JSON"),
        .correction(hear: "url", write: "URL"),
        .correction(hear: "qr code", write: "QR-Code"),
        .correction(hear: "local host", write: "localhost"),
        .correction(hear: "front end", write: "Frontend"),
        .correction(hear: "back end", write: "Backend"),
        .correction(hear: "daten bank", write: "Datenbank"),
        .correction(hear: "type script", write: "TypeScript"),
        .correction(hear: "java script", write: "JavaScript"),
        .correction(hear: "next js", write: "Next.js"),
        .correction(hear: "node js", write: "Node.js"),
        .correction(hear: "react", write: "React"),
        .correction(hear: "tailwind", write: "Tailwind"),
        .correction(hear: "docker", write: "Docker"),
        .correction(hear: "xcode", write: "Xcode"),
        .correction(hear: "vs code", write: "VS Code"),
        .correction(hear: "word press", write: "WordPress"),
        .correction(hear: "open source", write: "Open Source"),
        .correction(hear: "pair programming", write: "Pair Programming"),
        .correction(hear: "unit test", write: "Unit-Test"),
        .correction(hear: "bug fix", write: "Bugfix"),
        .correction(hear: "hot fix", write: "Hotfix"),
        .correction(hear: "roll out", write: "Rollout"),
        .correction(hear: "staging", write: "Staging"),
        .correction(hear: "deployment", write: "Deployment"),
    ]

    /// Apple, Google, Microsoft und der Werkzeugkasten drumherum.
    private static let officeAndTools: [DictionaryEntry] = [
        .correction(hear: "mac os", write: "macOS"),
        .correction(hear: "i phone", write: "iPhone"),
        .correction(hear: "i pad", write: "iPad"),
        .correction(hear: "i cloud", write: "iCloud"),
        .correction(hear: "air drop", write: "AirDrop"),
        .correction(hear: "face time", write: "FaceTime"),
        .correction(hear: "app store", write: "App Store"),
        .correction(hear: "chat gpt", write: "ChatGPT"),
        .correction(hear: "open ai", write: "OpenAI"),
        .correction(hear: "anthropic", write: "Anthropic"),
        .correction(hear: "claude", write: "Claude"),
        .correction(hear: "cloud code", write: "Claude Code"),
        .correction(hear: "g mail", write: "Gmail"),
        .correction(hear: "google drive", write: "Google Drive"),
        .correction(hear: "google docs", write: "Google Docs"),
        .correction(hear: "google sheets", write: "Google Sheets"),
        .correction(hear: "google kalender", write: "Google Kalender"),
        .correction(hear: "power point", write: "PowerPoint"),
        .correction(hear: "one drive", write: "OneDrive"),
        .correction(hear: "share point", write: "SharePoint"),
        .correction(hear: "drop box", write: "Dropbox"),
        .correction(hear: "outlook", write: "Outlook"),
        .correction(hear: "hub spot", write: "HubSpot"),
        .correction(hear: "shopify", write: "Shopify"),
        .correction(hear: "canva", write: "Canva"),
        .correction(hear: "figma", write: "Figma"),
        .correction(hear: "notion", write: "Notion"),
        .correction(hear: "slack", write: "Slack"),
        .correction(hear: "zoom", write: "Zoom"),
        .correction(hear: "teams", write: "Teams"),
        .correction(hear: "oc flow", write: "OC Flow"),
        .correction(hear: "screen shot", write: "Screenshot"),
        .correction(hear: "home office", write: "Homeoffice"),
        .correction(hear: "back up", write: "Backup"),
    ]

    private static let socialAndMarketing: [DictionaryEntry] = [
        .correction(hear: "linked in", write: "LinkedIn"),
        .correction(hear: "whats app", write: "WhatsApp"),
        .correction(hear: "you tube", write: "YouTube"),
        .correction(hear: "tik tok", write: "TikTok"),
        .correction(hear: "instagram", write: "Instagram"),
        .correction(hear: "face book", write: "Facebook"),
        .correction(hear: "landing page", write: "Landingpage"),
        .correction(hear: "e commerce", write: "E-Commerce"),
        .correction(hear: "news letter", write: "Newsletter"),
        .correction(hear: "online shop", write: "Onlineshop"),
        .correction(hear: "google ads", write: "Google Ads"),
        .correction(hear: "meta ads", write: "Meta Ads"),
        .correction(hear: "call to action", write: "Call-to-Action"),
        .correction(hear: "lead magnet", write: "Leadmagnet"),
        .correction(hear: "funnel", write: "Funnel"),
    ]

    /// Abkürzungen, die kleingeschrieben ankommen. Each is checked against German words:
    /// "ki" is safe because word boundaries stop it inside "Kino" or "kicken".
    private static let abbreviations: [DictionaryEntry] = [
        .correction(hear: "seo", write: "SEO"),
        .correction(hear: "sea", write: "SEA"),
        .correction(hear: "crm", write: "CRM"),
        .correction(hear: "ceo", write: "CEO"),
        .correction(hear: "cto", write: "CTO"),
        .correction(hear: "ki", write: "KI"),
        .correction(hear: "ui", write: "UI"),
        .correction(hear: "ux", write: "UX"),
        .correction(hear: "sdk", write: "SDK"),
        .correction(hear: "cli", write: "CLI"),
        .correction(hear: "ide", write: "IDE"),
        .correction(hear: "pdf", write: "PDF"),
        .correction(hear: "csv", write: "CSV"),
        .correction(hear: "kpi", write: "KPI"),
        .correction(hear: "roi", write: "ROI"),
        .correction(hear: "b2b", write: "B2B"),
        .correction(hear: "b2c", write: "B2C"),
    ]
}
