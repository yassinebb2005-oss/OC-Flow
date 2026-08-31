import SwiftUI

/// Settings — hotkey and model, per the brief. Opens on ⌘, via the standard `Settings` scene,
/// so the system wires up the menu item and the shortcut.
struct SettingsWindow: View {
    @Bindable var controller: DictationController
    @State private var settings = Settings.shared

    var body: some View {
        ZStack {
            DS.Color.chassis.ignoresSafeArea()

            VStack(alignment: .leading, spacing: DS.Space.wide) {
                panel(label: "Sprechtaste") {
                    HStack(spacing: DS.Space.snug) {
                        ForEach(PushToTalkKey.allCases, id: \.self) { key in
                            TransportKey(
                                title: key.displayName,
                                isEngaged: settings.pushToTalkKey == key,
                                engagedColor: DS.Color.ink
                            ) {
                                settings.pushToTalkKey = key
                                controller.reloadHotkey()
                            }
                            .background {
                                if settings.pushToTalkKey == key {
                                    RoundedRectangle(cornerRadius: DS.Radius.control)
                                        .fill(DS.Color.selection)
                                }
                            }
                        }
                    }
                    note("Diese Taste überall gedrückt halten und sprechen. Der Aufnehmen-Knopf im Fenster "
                        + "funktioniert unabhängig davon, was gerade im Vordergrund ist.")
                }

                panel(label: "Erkennung") {
                    HStack(spacing: DS.Space.snug) {
                        ForEach(SpeechEngineChoice.allCases, id: \.self) { choice in
                            TransportKey(
                                title: choice == .apple ? "Apple" : "Parakeet",
                                isEngaged: settings.engine == choice,
                                engagedColor: DS.Color.ink
                            ) {
                                settings.engine = choice
                            }
                            .background {
                                if settings.engine == choice {
                                    RoundedRectangle(cornerRadius: DS.Radius.control)
                                        .fill(DS.Color.selection)
                                }
                            }
                        }
                    }
                    note(settings.engine == .apple
                        ? "Apples Erkennung auf dem Gerät. Schreibt mit, während du sprichst. Kein Download."
                        : "Parakeet auf der Neural Engine. Erkennt beim Loslassen. Modell rund 470 MB.")
                }

                panel(label: "Aufräumen") {
                    Toggle(isOn: $settings.cleanupEnabled) {
                        Silkscreen(text: "Aufnahmen aufräumen")
                    }
                    .toggleStyle(.switch)
                    note("Wirft Füllwörter raus, setzt Satzzeichen. Die Korrekturen aus dem Wörterbuch "
                        + "laufen so oder so.")
                }

            }
            .padding(DS.Space.panel)
        }
        // Width fixed, height intrinsic: the Settings scene sizes the window to fit, so
        // the content can never be taller than the window and get clipped under the
        // title bar again.
        .frame(width: 520)
    }

    private func panel<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.base) {
            Silkscreen(text: label, large: true)
            content()
        }
        .padding(DS.Space.roomy)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BrushedPanel())
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(DS.Font.label)
            .foregroundStyle(DS.Color.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
