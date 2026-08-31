import OSLog

enum Log {
    static let audio = Logger(subsystem: "com.oc-hairsystems.ocflow", category: "audio")
    static let speech = Logger(subsystem: "com.oc-hairsystems.ocflow", category: "speech")
    static let hotkey = Logger(subsystem: "com.oc-hairsystems.ocflow", category: "hotkey")
    static let inject = Logger(subsystem: "com.oc-hairsystems.ocflow", category: "inject")
    static let app = Logger(subsystem: "com.oc-hairsystems.ocflow", category: "app")
}
