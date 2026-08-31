import SwiftUI

/// The design system for OC Flow.
///
/// Monochrome, following the O.C. Hairsystems mark: black, white, and the greys between
/// them. Every value a view needs lives here; components never declare their own colors,
/// sizes, radii or durations.
///
/// Two faces from one set of tokens — paper-white in light appearance, near-black in dark —
/// so a view is written once and both work.
///
/// The rules that keep it quiet:
/// - No hue. If a token needs to carry meaning, it does it with contrast, not color.
/// - Red appears only where something has actually failed.
/// - Depth comes from a single hairline and a soft shadow. No bevels, no glow.
/// - Radii are generous. Software, not hardware.
enum DS {

    // MARK: - Color

    /// Surfaces, from the outermost inward. `Face` resolves each to the light or dark
    /// variant based on the current appearance.
    enum Color {
        /// The window background. Frames everything else.
        static let chassis = face(light: 0xF4F4F5, dark: 0x0A0A0B)

        /// The main working surface — cards, panels, list rows.
        static let panel = face(light: 0xFFFFFF, dark: 0x161617)

        /// A raised or hovered variant of `panel`.
        static let panelHighlight = face(light: 0xFFFFFF, dark: 0x1F1F21)

        /// A recessed variant of `panel`.
        static let panelShade = face(light: 0xEDEDEF, dark: 0x101011)

        /// Inset areas: search fields, text wells, the transcript list background.
        static let well = face(light: 0xF0F0F2, dark: 0x0D0D0E)

        /// The strip behind primary controls.
        static let deck = face(light: 0xFAFAFB, dark: 0x141415)

        /// Control surfaces: buttons, toggles, segment backgrounds.
        static let cap = face(light: 0xFFFFFF, dark: 0x232325)

        /// Hairline dividers. The only edge treatment in the system.
        static let seam = face(light: 0xE2E2E5, dark: 0x2A2A2D)

        /// Primary text.
        static let ink = face(light: 0x111113, dark: 0xF5F5F6)
        /// Secondary text: timestamps, counts, help text.
        static let inkSecondary = face(light: 0x6E6E75, dark: 0x96969E)
        /// Labels above controls. Quietest text in the system.
        static let silkscreen = face(light: 0x8E8E96, dark: 0x76767E)
        /// Text on `deck`.
        static let inkOnDeck = face(light: 0x111113, dark: 0xF5F5F6)

        /// Recording. Monochrome like everything else — the waveform carries the signal,
        /// so the indicator does not need a hue to be read.
        static let record = face(light: 0x111113, dark: 0xF5F5F6)
        /// Not recording.
        static let recordIdle = face(light: 0xC4C4CA, dark: 0x3A3A3F)

        /// Selected rows.
        static let selection = face(light: 0xE8E8EB, dark: 0x27272A)
        static let selectionEdge = face(light: 0xD4D4D9, dark: 0x35353A)
        static let focusRing = face(light: 0x111113, dark: 0xF5F5F6)
        static let hover = face(light: 0xF2F2F4, dark: 0x1C1C1E)

        /// Level metering. Grey ramp, not a traffic light.
        static let meterFace = face(light: 0xF0F0F2, dark: 0x0D0D0E)
        static let meterLamp = face(light: 0x111113, dark: 0xF5F5F6)
        static let meterNeedle = face(light: 0x111113, dark: 0xF5F5F6)
        /// Nominal.
        static let meterGreen = face(light: 0x8E8E96, dark: 0x76767E)
        /// Hot.
        static let meterAmber = face(light: 0x4A4A52, dark: 0xB4B4BC)
        /// Over. The one place a hue survives, because clipping is a failure.
        static let meterRed = swatch(0xE05A52)


        // MARK: Face resolution

        private static func swatch(_ hex: UInt32) -> SwiftUI.Color { SwiftUI.Color(hex: hex) }

        /// Resolves to the silver-face or black-face value for the current appearance.
        private static func face(light: UInt32, dark: UInt32) -> SwiftUI.Color {
            SwiftUI.Color(nsColor: NSColor(name: nil) { appearance in
                let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                return NSColor(hex: isDark ? dark : light)
            })
        }
    }

    // MARK: - Material

    /// The physical detail that makes a panel read as a machined object rather than a filled
    /// rectangle: metal grain, fasteners, ventilation, lamps, segmented readouts.
    ///
    /// These are what "lean into it" means here — density of real hardware detail, not
    /// decoration laid on top. Every one of them exists on a TC-D5 or a PMD.
    enum Material {
        // Brushed aluminum grain. Anisotropic: fine horizontal striations across the panel.
        /// Opacity of the lighter striations.
        static let grainLight: Double = 0.055
        /// Opacity of the darker striations.
        static let grainDark: Double = 0.07
        /// Distance between striations.
        static let grainPitch: CGFloat = 2
        /// Grain runs horizontally across a face, as on a rolled sheet.
        static let grainAngle: Angle = .degrees(0)

        // Fasteners
        /// Diameter of a panel screw head.
        static let screwSize: CGFloat = 9
        /// Inset of a screw from the panel corner.
        static let screwInset: CGFloat = 10

        // Ventilation
        /// A single vent slot.
        static let ventSlotWidth: CGFloat = 3
        static let ventSlotHeight: CGFloat = 22
        static let ventSlotGap: CGFloat = 4
        static let ventRadius: CGFloat = 1.5

        // Indicator lamps — small, hard-edged, lit from behind a lens.
        static let lampSize: CGFloat = 7
        /// A lit lamp's lens highlight — a specular dot, not a bloom.
        static let lampSpecular: Double = 0.45
        /// How far an unlit lamp sits below the lit value.
        static let lampUnlitOpacity: Double = 0.22

        // Segmented readout — the tape counter and timings.
        /// Stroke width of a seven-segment bar.
        static let segmentThickness: CGFloat = 3
        /// Gap between segments within a digit.
        static let segmentGap: CGFloat = 1
        /// Unlit segments stay faintly visible, as on a real LCD.
        static let segmentGhostOpacity: Double = 0.12

        // Transport keys — rectangular, wide, with real travel.
        static let keyHeight: CGFloat = 32
        static let keyMinWidth: CGFloat = 60
        /// How far a key sinks when pressed.
        static let keyTravel: CGFloat = 1.5

        // VU meter
        /// Total sweep of the needle, centered on vertical.
        static let needleSweep: Angle = .degrees(96)
        static let needleWidth: CGFloat = 1.5
        /// Where 0 VU sits along the scale, 0...1 — the red zone begins here.
        static let meterZeroPoint: Double = 0.72
    }

    // MARK: - Type

    /// A neutral grotesque, the way equipment was labeled. Helvetica Neue is the honest
    /// choice on macOS — the system font is too humanist for a silkscreen look. Falls back
    /// to the system face if it's ever unavailable.
    enum Font {
        /// The system face. The house font is GT Walsheim, which cannot be redistributed
        /// inside an app bundle; SF is the closest geometric grotesque already on every Mac,
        /// and it carries the optical sizing and tabular figures a licensed webfont wouldn't.
        static let sectionLabel = system(size: 11, weight: .medium)
        static let sectionLabelLarge = system(size: 13, weight: .semibold)

        static let caption = system(size: 11, weight: .regular)
        static let label = system(size: 12, weight: .regular)
        static let body = system(size: 13, weight: .regular)
        static let bodyEmphasis = system(size: 13, weight: .medium)
        static let title = system(size: 20, weight: .semibold)

        /// Readouts and timings. Monospaced digits so numbers don't shift as they tick.
        static let counter = SwiftUI.Font.system(size: 12, weight: .medium).monospacedDigit()
        /// The transport counter.
        static let counterLarge = SwiftUI.Font.system(size: 22, weight: .medium).monospacedDigit()

        /// Kept at zero: section labels are sentence case now, and tracking on a
        /// non-uppercase label just looks like a rendering fault.
        static let sectionLabelTracking: CGFloat = 0

        /// Tiny uppercase chips and eyebrow labels — the one place tracking survives,
        /// in small doses. Pair with an uppercased string.
        static let kicker = SwiftUI.Font.system(size: 9.5, weight: .semibold)
        static let kickerTracking: CGFloat = 0.8

        private static func system(size: CGFloat, weight: SwiftUI.Font.Weight) -> SwiftUI.Font {
            .system(size: size, weight: weight)
        }
    }

    // MARK: - Spacing

    /// A 4pt grid. Panels are laid out on it; nothing sits between steps.
    enum Space {
        static let hair: CGFloat = 2
        static let tight: CGFloat = 4
        static let snug: CGFloat = 8
        static let base: CGFloat = 12
        static let roomy: CGFloat = 16
        static let wide: CGFloat = 24
        static let panel: CGFloat = 32
    }

    // MARK: - Radius

    /// Small by design. Equipment has hard edges; anything soft reads as software.
    enum Radius {
        /// Seams and dividers — square.
        static let none: CGFloat = 0
        /// Indicator chips.
        static let chip: CGFloat = 4
        /// Buttons and controls.
        static let control: CGFloat = 8
        /// Wells and grouped panels.
        static let panel: CGFloat = 12
        /// The window itself.
        static let window: CGFloat = 16
    }

    // MARK: - Border

    enum Border {
        /// A drawn hairline. Sub-point, so it stays a line rather than becoming a frame.
        static let hairline: CGFloat = 0.5
        /// The divider between two surfaces, drawn in `Color.seam`.
        static let seam: CGFloat = 0.5
        /// Kept for call sites that still ask for it; same hairline, no bevel left to draw.
        static let bevel: CGFloat = 0.5
    }

    // MARK: - Elevation

    /// Depth is physical: a raised cap casts a short hard shadow, a well is cut into the
    /// panel. No soft ambient glows.
    enum Shadow {
        /// A control lifted off its surface.
        static let raised = Spec(color: .black.opacity(0.10), radius: 6, x: 0, y: 2)
        /// The same control while pressed — settled back down.
        static let pressed = Spec(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
        /// A grouped panel above the window background.
        static let panel = Spec(color: .black.opacity(0.08), radius: 14, x: 0, y: 4)
        /// The window against the desktop.
        static let window = Spec(color: .black.opacity(0.28), radius: 32, x: 0, y: 12)

        struct Spec {
            let color: SwiftUI.Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }

    // MARK: - Motion

    /// Mechanical, not bouncy. A key travels and stops; it doesn't spring.
    enum Motion {
        /// A control taking the press. Spring rather than ease, so releasing early still
        /// resolves smoothly instead of snapping back from wherever it was interrupted.
        static let press = Animation.spring(response: 0.22, dampingFraction: 0.7)
        /// The same spring on release.
        static let release = Animation.spring(response: 0.30, dampingFraction: 0.75)
        /// Panel and view changes.
        static let panel = Animation.easeInOut(duration: 0.22)
        /// Hover in and out.
        static let hover = Animation.easeOut(duration: 0.14)
        /// The record indicator coming on.
        static let lamp = Animation.easeOut(duration: 0.12)

        /// VU ballistics. A real VU meter reaches 99% of a step in ~300ms and overshoots
        /// slightly; that lag *is* the instrument's character, so the needle is damped
        /// rather than tracking the signal directly.
        static let needleAttack: TimeInterval = 0.30
        static let needleRelease: TimeInterval = 0.42
        /// Peak overshoot as a fraction of the step, before settling.
        static let needleOvershoot: Double = 0.06
    }
}

// MARK: - Hex helpers

private extension SwiftUI.Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

private extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
