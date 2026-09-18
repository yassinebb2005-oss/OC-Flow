import AppKit
import SwiftUI

/// The floating capsule that appears while you hold the key.
///
/// The single most important property here is that this panel **never becomes key**.
/// If it did, the user's text field would lose focus and `TextInjector` would have
/// nothing to insert into. Hence `.nonactivatingPanel` plus `canBecomeKey == false`.
@MainActor
final class HUDPanel: NSPanel {
    init(controller: DictationController) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 196, height: 44),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        // Above `.statusBar`: a full-screen window's own overlays sit at status-bar level,
        // and the HUD losing that tie is the difference between seeing it and not.
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        hidesOnDeactivate = false
        isMovableByWindowBackground = false
        ignoresMouseEvents = true

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false

        contentView = NSHostingView(rootView: HUDView(controller: controller))

        observeDisplayChanges()
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// Parks the panel just above the Dock, horizontally centered on the active screen.
    ///
    /// `NSScreen.main` is the screen with the *key window* — and an accessory app with a
    /// non-activating panel never has one, so it can be nil. Falling back to `screens.first`
    /// keeps the HUD on-screen instead of stranding it at the origin.
    func reposition() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            Log.app.error("no screen available to position HUD")
            return
        }
        let visible = screen.visibleFrame
        let size = frame.size
        setFrameOrigin(
            NSPoint(
                x: visible.midX - size.width / 2,
                y: visible.minY + 72
            )
        )
    }

    /// Rebuilds the panel's footing after the display configuration changes.
    ///
    /// Waking from sleep, plugging in a monitor, or the screen simply switching off and on
    /// all reshuffle `NSScreen`, and a panel positioned against the old layout can end up
    /// off-screen or orphaned on a display that no longer exists. Both notifications are
    /// cheap and fire rarely, so re-seating on either is simpler than working out which
    /// combinations actually break it.
    private func observeDisplayChanges() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.reseat() }
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.reseat() }
        }
    }

    /// Re-anchors a visible panel to the current screen layout. A hidden one needs nothing:
    /// `present()` repositions before it shows.
    private func reseat() {
        guard isVisible else { return }
        reposition()
        if alphaValue < 1 { alphaValue = 1 }
        orderFrontRegardless()
        Log.app.info("HUD re-seated after a display change")
    }

    /// Bumped by every present/dismiss so a finishing animation can tell whether it is
    /// still the current one. Without it, the fade-out's completion handler runs after a
    /// newly started fade-in and orders the panel out from under it.
    private var generation = 0

    func present() {
        generation += 1
        let mine = generation

        reposition()
        orderFrontRegardless()
        Log.app.info("HUD shown at \(NSStringFromRect(self.frame), privacy: .public)")

        alphaValue = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            animator().alphaValue = 1
        }

        // The fade is decoration; it must never decide whether the panel ends up visible.
        // Core Animation does not run normally while the display is asleep or the screen is
        // off, and a fade that never completes leaves the panel ordered in at alpha 0 —
        // present, logged, and invisible. This pins it open regardless.
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(260))
            guard let self, self.generation == mine else { return }
            if self.alphaValue < 1 {
                Log.app.info("HUD fade did not finish — forcing it visible")
                self.alphaValue = 1
            }
        }
    }

    func dismiss() {
        generation += 1
        let mine = generation

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            animator().alphaValue = 0
        } completionHandler: { [weak self] in
            // AppKit always calls this on the main thread.
            MainActor.assumeIsolated {
                guard let self, self.generation == mine else {
                    // A new dictation started while this was fading out. Leave it alone —
                    // ordering out here is exactly the bug this guards against.
                    Log.app.info("HUD fade-out superseded by a new dictation — kept visible")
                    return
                }
                Log.app.info("HUD hidden")
                self.orderOut(nil)
            }
        }
    }
}
