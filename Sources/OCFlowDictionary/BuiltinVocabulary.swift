import Foundation

/// Vocabulary the app ships with: office and engineering terms the German recognizer
/// reliably mangles, plus the company's own domain words.
///
/// Deliberately not part of the user's dictionary file. The dictionary UI stays personal —
/// what the user put there, nothing else — while this layer works underneath. It is not
/// hidden in effect: every fired correction still shows up as a "Korrigiert" badge on the
/// transcript, and a user entry with the same trigger or word replaces the built-in one
/// (`DictionaryStore` filters on collision), so any rule here can be overridden by hand.
///
/// Rules for adding corrections: the trigger must not collide with a real German word
/// (word-boundary matching protects "Zoom" from "zoomen", but nothing protects a trigger
/// that *is* a word). Multi-part triggers match with any or no separator — "git hub"
/// catches "github", "Git Hub" and "Git-Hub" in one line.
public enum BuiltinVocabulary {
    public static let entries: [DictionaryEntry] = corrections + terms

    /// When you hear X, write Y. Casing fixes and phonetic repairs.
    private static let corrections: [DictionaryEntry] = [
        // Entwicklung
        .correction(hear: "git hub", write: "GitHub"),
        .correction(hear: "git lab", write: "GitLab"),
        .correction(hear: "ripo", write: "Repo"),
        .correction(hear: "repo", write: "Repo"),
        .correction(hear: "pull request", write: "Pull Request"),
        .correction(hear: "readme", write: "README"),
        .correction(hear: "api", write: "API"),
        .correction(hear: "json", write: "JSON"),
        .correction(hear: "url", write: "URL"),
        .correction(hear: "qr code", write: "QR-Code"),
        .correction(hear: "xcode", write: "Xcode"),
        .correction(hear: "vs code", write: "VS Code"),
        .correction(hear: "type script", write: "TypeScript"),
        .correction(hear: "java script", write: "JavaScript"),
        .correction(hear: "word press", write: "WordPress"),
        // Eingedeutschte Verben, phonetisch verschrieben
        .correction(hear: "puschen", write: "pushen"),
        .correction(hear: "gepuscht", write: "gepusht"),
        .correction(hear: "kommitten", write: "committen"),
        .correction(hear: "kommittet", write: "committet"),
        .correction(hear: "kommitte", write: "committe"),
        // Apple
        .correction(hear: "mac os", write: "macOS"),
        .correction(hear: "i phone", write: "iPhone"),
        .correction(hear: "i pad", write: "iPad"),
        .correction(hear: "i cloud", write: "iCloud"),
        .correction(hear: "air drop", write: "AirDrop"),
        .correction(hear: "face time", write: "FaceTime"),
        // Werkzeuge und Dienste
        .correction(hear: "chat gpt", write: "ChatGPT"),
        .correction(hear: "open ai", write: "OpenAI"),
        .correction(hear: "anthropic", write: "Anthropic"),
        .correction(hear: "claude", write: "Claude"),
        .correction(hear: "cloud code", write: "Claude Code"),
        .correction(hear: "g mail", write: "Gmail"),
        .correction(hear: "google drive", write: "Google Drive"),
        .correction(hear: "google docs", write: "Google Docs"),
        .correction(hear: "power point", write: "PowerPoint"),
        .correction(hear: "one drive", write: "OneDrive"),
        .correction(hear: "drop box", write: "Dropbox"),
        .correction(hear: "outlook", write: "Outlook"),
        .correction(hear: "hub spot", write: "HubSpot"),
        .correction(hear: "shopify", write: "Shopify"),
        .correction(hear: "canva", write: "Canva"),
        .correction(hear: "figma", write: "Figma"),
        .correction(hear: "notion", write: "Notion"),
        .correction(hear: "slack", write: "Slack"),
        .correction(hear: "zoom", write: "Zoom"),
        .correction(hear: "oc flow", write: "OC Flow"),
        // Social und Marketing
        .correction(hear: "linked in", write: "LinkedIn"),
        .correction(hear: "whats app", write: "WhatsApp"),
        .correction(hear: "you tube", write: "YouTube"),
        .correction(hear: "tik tok", write: "TikTok"),
        .correction(hear: "instagram", write: "Instagram"),
        .correction(hear: "face book", write: "Facebook"),
        .correction(hear: "landing page", write: "Landingpage"),
        .correction(hear: "e commerce", write: "E-Commerce"),
        .correction(hear: "home office", write: "Homeoffice"),
        .correction(hear: "screen shot", write: "Screenshot"),
        // Abkürzungen, die klein ankommen
        .correction(hear: "seo", write: "SEO"),
        .correction(hear: "crm", write: "CRM"),
        .correction(hear: "ceo", write: "CEO"),
        .correction(hear: "ki", write: "KI"),
    ]

    /// Words the engine gets biased toward so it hears them right in the first place —
    /// including the company's own domain vocabulary.
    private static let terms: [DictionaryEntry] = [
        "GitHub", "Repo", "Pull Request", "Branch", "Commit",
        "committen", "pushen", "mergen", "deployen",
        "Backend", "Frontend", "Terminal",
        "ChatGPT", "OpenAI", "Anthropic", "Claude",
        "Slack", "Notion", "Figma", "Canva", "HubSpot", "Shopify",
        "Newsletter", "Landingpage", "Onlineshop", "SEO",
        "Apple Intelligence", "OC Flow",
        "O.C. Hairsystems", "Haarsystem", "Haarsysteme", "Zweithaar",
    ].map { .term($0) }
}
