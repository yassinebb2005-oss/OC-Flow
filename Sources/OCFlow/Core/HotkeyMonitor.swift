import AppKit
import Carbon.HIToolbox
import Foundation

/// Which modifier key holds the mic open.
enum PushToTalkKey: String, CaseIterable, Sendable {
    case rightOption
    case fn
    case rightCommand

    var keyCode: Int64 {
        switch self {
        case .rightOption: Int64(kVK_RightOption)   // 61
        case .fn: Int64(kVK_Function)               // 63
        case .rightCommand: Int64(kVK_RightCommand) // 54
        }
    }

    /// Device-*dependent* bit for this specific physical key.
    ///
    /// `CGEventFlags.maskAlternate` is the union mask — it's set whenever *either* Option
    /// key is down. Using it means: hold Left ⌥, tap Right ⌥, and the release is invisible
    /// (the union bit is still set by the left key), so `onRelease` never fires. The mic
    /// stays open, the HUD stays up, and the next press is swallowed too.
    ///
    /// These raw values are the NX_DEVICE* masks from IOKit's event system; they carry the
    /// left/right distinction that the public `CGEventFlags` constants discard.
    var flag: CGEventFlags {
        switch self {
        case .rightOption: CGEventFlags(rawValue: 0x40)   // NX_DEVICERALTKEYMASK
        case .rightCommand: CGEventFlags(rawValue: 0x10)  // NX_DEVICERCMDKEYMASK
        case .fn: .maskSecondaryFn                        // no left/right variant exists
        }
    }

    var displayName: String {
        switch self {
        case .rightOption: "Rechte ⌥"
        case .fn: "fn"
        case .rightCommand: "Rechte ⌘"
        }
    }

    /// Swallowing `fn` would break fn+arrow, fn+delete and the emoji picker, so we let it
    /// through. Dedicated right-hand modifiers are safe to consume.
    var shouldConsumeEvent: Bool { self != .fn }

    /// Whether holding this key is only push-to-talk when nothing else is pressed with it.
    ///
    /// `fn` is a modifier people use constantly on a laptop: fn plus an arrow, fn plus
    /// delete, fn plus a function key. Every one of those raises and drops the same flag a
    /// held `fn` does, so without this a normal shortcut started a recording, and releasing
    /// it pasted whatever the microphone caught into the focused field. The dedicated
    /// right-hand modifiers are chords nobody presses by accident.
    var requiresSoloPress: Bool { self == .fn }
}

/// Watches for a held modifier key using a `CGEventTap`.
///
/// A tap is required rather than `NSEvent.addGlobalMonitor` because `fn` and left/right
/// modifier discrimination don't surface through the higher-level APIs. This needs
/// Accessibility permission; without it `CGEvent.tapCreate` returns nil.
@MainActor
final class HotkeyMonitor {
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isPressed = false

    /// Set while a hold is being ignored because another key joined it. Cleared on release,
    /// so the stray release doesn't end a dictation that never started.
    private var isAbandoned = false

    var key: PushToTalkKey = .rightOption
    var onPress: (() -> Void)?
    var onRelease: (() -> Void)?
    /// Called when a hold turns out to be part of a shortcut. The dictation must be dropped,
    /// not finished: nothing the microphone caught in those milliseconds was meant as text.
    var onAbandon: (() -> Void)?

    /// - Returns: `false` if the tap couldn't be created — almost always missing Accessibility permission.
    @discardableResult
    func start() -> Bool {
        stop()

        // keyDown as well as flagsChanged: it is the only way to notice that a held key is
        // part of a shortcut rather than a push-to-talk hold.
        let mask = (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.keyDown.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, refcon in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<HotkeyMonitor>.fromOpaque(refcon).takeUnretainedValue()

                // CGEvent isn't Sendable, so pull out the plain values before crossing into
                // actor-isolated code. The tap was added to the main run loop, so this
                // callback genuinely does run on the main thread.
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.flags
                let consume = MainActor.assumeIsolated {
                    monitor.handle(type: type, keyCode: keyCode, flags: flags)
                }
                return consume ? nil : Unmanaged.passUnretained(event)
            },
            userInfo: refcon
        ) else {
            Log.hotkey.error("tapCreate failed — Accessibility permission missing?")
            return false
        }

        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        Log.hotkey.info("listening for \(self.key.displayName)")
        return true
    }

    func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        tap = nil
        runLoopSource = nil
        isPressed = false
        isAbandoned = false
    }

    // MARK: - Tap callback

    /// - Returns: `true` if the event should be swallowed rather than passed along.
    private func handle(type: CGEventType, keyCode: Int64, flags: CGEventFlags) -> Bool {
        // The system disables a tap that runs too slowly or is interrupted; re-arm it.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            // While the tap was off, the release we were waiting for went past unseen. Left
            // alone, the recording runs forever with no key able to stop it — which is
            // exactly what a stuck timer in the window looks like.
            if isPressed {
                isPressed = false
                isAbandoned = false
                Log.hotkey.info("tap was disabled mid-hold — dropping the recording")
                onAbandon?()
            }
            return false
        }

        // A key pressed while the hold is running means this was a shortcut, not dictation.
        if type == .keyDown {
            if isPressed, key.requiresSoloPress, !isAbandoned {
                isAbandoned = true
                Log.hotkey.info("hold abandoned — \(self.key.displayName) was part of a shortcut")
                onAbandon?()
            }
            return false
        }

        guard type == .flagsChanged, keyCode == key.keyCode else { return false }

        let nowPressed = flags.contains(key.flag)
        guard nowPressed != isPressed else { return false }
        isPressed = nowPressed

        if nowPressed {
            isAbandoned = false
            onPress?()
        } else if isAbandoned {
            // Already dropped when the other key arrived; the release is just bookkeeping.
            isAbandoned = false
        } else {
            onRelease?()
        }

        return key.shouldConsumeEvent
    }
}
