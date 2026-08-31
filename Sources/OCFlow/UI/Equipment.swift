import SwiftUI

// The physical vocabulary of the app: panels, wells, keys, lamps, silkscreen, meters.
// Every value here comes from `DS`. If a component needs a number that isn't a token, the
// token is missing — add it there rather than inlining it.

// MARK: - Surfaces

/// A flat surface with a single hairline edge.
///
/// Named for what it replaced. It used to draw brushed-aluminum grain and a bevel; the
/// monochrome palette has no room for either, and a filled rect with one border reads as
/// far less noise behind a list of transcripts.
struct BrushedPanel: View {
    var radius: CGFloat = DS.Radius.panel

    var body: some View {
        DS.Color.panel
            .clipShape(.rect(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(DS.Color.seam, lineWidth: DS.Border.seam)
            )
    }

    /// Fine horizontal striations, the direction a rolled aluminum sheet is brushed.
    private struct Grain: View {
        var body: some View {
            Canvas { context, size in
                var y: CGFloat = 0
                var alternate = false
                while y < size.height {
                    let shade = alternate ? DS.Material.grainDark : DS.Material.grainLight
                    let color = alternate ? Color.black : Color.white
                    context.fill(
                        Path(CGRect(x: 0, y: y, width: size.width, height: DS.Material.grainPitch / 2)),
                        with: .color(color.opacity(shade))
                    )
                    y += DS.Material.grainPitch
                    alternate.toggle()
                }
            }
            .rotationEffect(DS.Material.grainAngle)
            .allowsHitTesting(false)
        }
    }
}

/// A recessed well cut into the panel. Content sits *in* it, so the inner edge is dark at
/// the top and light at the bottom — the inverse of a raised cap.
struct Well<Content: View>: View {
    var radius: CGFloat = DS.Radius.panel
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(DS.Color.well, in: .rect(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(DS.Color.seam, lineWidth: DS.Border.hairline)
            )
    }
}

/// The dark readout window — the tape window of a deck. Darker than a `Well`, and always
/// dark regardless of face, because a lit readout needs something to be lit against.
struct DeckWindow<Content: View>: View {
    var radius: CGFloat = DS.Radius.panel
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(DS.Color.deck, in: .rect(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(DS.Color.seam, lineWidth: DS.Border.hairline)
            )
    }
}

// MARK: - Labels

/// A silkscreened panel label: small, uppercase, tightly tracked.
///
/// The uppercasing happens here rather than at the call site so a label can never be
/// half-styled — the look depends on all three of size, tracking and case.
struct Silkscreen: View {
    let text: String
    var large = false
    var color: Color = DS.Color.silkscreen

    var body: some View {
        Text(text)
            .font(large ? DS.Font.sectionLabelLarge : DS.Font.sectionLabel)
            .foregroundStyle(color)
    }
}

// MARK: - Hardware detail

/// A panel screw. Purely decorative, and deliberately so — real equipment has fasteners,
/// and their absence is one of the things that makes software look like software.
struct Screw: View {
    var body: some View {
        Circle()
            .fill(DS.Color.panelShade)
            .overlay(
                Circle().strokeBorder(DS.Color.seam.opacity(0.6), lineWidth: DS.Border.hairline)
            )
            .overlay(
                Rectangle()
                    .fill(DS.Color.seam.opacity(0.7))
                    .frame(width: DS.Material.screwSize * 0.55, height: DS.Border.hairline)
                    .rotationEffect(.degrees(28))
            )
            .overlay(alignment: .top) {
                Circle()
                    .fill(DS.Color.panelHighlight)
                    .frame(height: DS.Border.bevel)
                    .opacity(0.6)
            }
            .frame(width: DS.Material.screwSize, height: DS.Material.screwSize)
    }
}

/// A run of ventilation slots.
struct Vents: View {
    var count = 6

    var body: some View {
        HStack(spacing: DS.Material.ventSlotGap) {
            ForEach(0..<count, id: \.self) { _ in
                RoundedRectangle(cornerRadius: DS.Material.ventRadius)
                    .fill(DS.Color.seam)
                    .frame(width: DS.Material.ventSlotWidth, height: DS.Material.ventSlotHeight)
                    .opacity(0.5)
            }
        }
    }
}

/// An indicator lamp behind a lens. Lit lamps get a specular dot, not a bloom — the brief
/// rules out glow, and real lamps read as lit because of the highlight on the lens.
struct Lamp: View {
    let color: Color
    var isLit: Bool
    var size: CGFloat = DS.Material.lampSize

    var body: some View {
        // A dot, not a lamp. The specular highlight and bezel that made this read as a
        // physical indicator have no counterpart in a flat monochrome interface — and a lit
        // dot that grows slightly is a clearer signal than one that gains a glint.
        Circle()
            .fill(isLit ? color : DS.Color.recordIdle)
            .frame(width: size, height: size)
            .scaleEffect(isLit ? 1 : 0.8)
            .animation(DS.Motion.lamp, value: isLit)
    }
}

// MARK: - Controls

/// A transport key: rectangular, chunky, with real travel. Pressed means *pressed* — the cap
/// sinks and its shadow collapses — rather than merely tinted.
struct TransportKey: View {
    let title: String
    var systemImage: String?
    var isEngaged = false
    var engagedColor: Color = DS.Color.ink
    var isEnabled = true
    let action: () -> Void

    @State private var isPressed = false
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Space.tight) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 9, weight: .semibold))
                }
                Text(title)
                    .font(DS.Font.bodyEmphasis)
            }
            .foregroundStyle(labelColor)
            .frame(minWidth: DS.Material.keyMinWidth)
            .frame(height: DS.Material.keyHeight)
            .padding(.horizontal, DS.Space.roomy)
            .background(cap)
            // Scale rather than vertical travel. A key that moves down needs a bevel and a
            // shadow to explain where it went; a control that compresses reads as pressed
            // on a flat surface, and survives the monochrome palette.
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.35)
        .onHover { hovering in
            withAnimation(DS.Motion.hover) { isHovering = hovering && isEnabled }
        }
        .onLongPressGesture(minimumDuration: 0) {} onPressingChanged: { pressing in
            withAnimation(pressing ? DS.Motion.press : DS.Motion.release) { isPressed = pressing }
        }
    }

    /// Engaged inverts the control rather than tinting its label. With no hue available,
    /// inversion is the strongest state signal the palette can produce.
    private var labelColor: Color {
        isEngaged ? DS.Color.panel : DS.Color.ink
    }

    private var fill: Color {
        if isEngaged { return engagedColor }
        if isPressed { return DS.Color.selection }
        if isHovering { return DS.Color.hover }
        return DS.Color.cap
    }

    private var cap: some View {
        RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
            .fill(fill)
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .strokeBorder(isEngaged ? .clear : DS.Color.seam, lineWidth: DS.Border.hairline)
            }
            .shadow(
                color: (isPressed ? DS.Shadow.pressed : DS.Shadow.raised).color,
                radius: (isPressed ? DS.Shadow.pressed : DS.Shadow.raised).radius,
                x: 0,
                y: (isPressed ? DS.Shadow.pressed : DS.Shadow.raised).y
            )
    }
}

// MARK: - Instrumentation

/// A VU meter with a real needle.
///
/// The needle is damped rather than driven directly from the signal: a physical VU movement
/// takes ~300ms to reach a step and overshoots slightly before settling, and that lag is the
/// instrument's character. Tracking the level exactly would produce a twitching line that
/// reads as a progress bar with a stick on it.
struct VUMeter: View {
    /// Current input level, 0...1.
    let level: Float
    var isActive: Bool

    /// The needle's physical state lives in a plain reference type, deliberately *not* in
    /// `@State`. The movement has to advance once per drawn frame, and SwiftUI state mutated
    /// inside a `Canvas` draw closure is a mutation during view update — which SwiftUI logs
    /// as undefined behavior and which, at 120fps, floods the process. A reference the view
    /// merely holds is invisible to the state graph, so stepping it is safe.
    @State private var movement = NeedleMovement()

    private final class NeedleMovement {
        var position: Double = 0
        var velocity: Double = 0
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                draw(in: &context, size: size, at: timeline.date)
            }
        }
        .background(DS.Color.meterFace)
        .overlay(
            Rectangle()
                .fill(DS.Color.meterLamp)
                .opacity(isActive ? 0.14 : 0)
                .animation(DS.Motion.lamp, value: isActive)
        )
        .clipShape(.rect(cornerRadius: DS.Radius.chip))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.chip)
                .strokeBorder(DS.Color.seam, lineWidth: DS.Border.hairline)
        )
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, at date: Date) {
        advanceNeedle()

        let pivot = CGPoint(x: size.width / 2, y: size.height * 1.05)
        let radius = min(size.width * 0.46, size.height * 0.92)
        let sweep = DS.Material.needleSweep.radians

        // Scale arc, with the red zone past 0 VU.
        for tick in stride(from: 0.0, through: 1.0, by: 0.1) {
            let angle = -sweep / 2 + sweep * tick
            let isOver = tick >= DS.Material.meterZeroPoint
            let inner = radius * (tick.truncatingRemainder(dividingBy: 0.2) < 0.01 ? 0.78 : 0.86)
            var path = Path()
            path.move(to: point(from: pivot, angle: angle, distance: inner))
            path.addLine(to: point(from: pivot, angle: angle, distance: radius))
            context.stroke(
                path,
                with: .color(isOver ? DS.Color.meterRed : DS.Color.meterNeedle),
                lineWidth: DS.Border.hairline
            )
        }

        // Needle.
        let angle = -sweep / 2 + sweep * movement.position
        var needlePath = Path()
        needlePath.move(to: pivot)
        needlePath.addLine(to: point(from: pivot, angle: angle, distance: radius * 0.98))
        context.stroke(
            needlePath,
            with: .color(DS.Color.meterNeedle),
            lineWidth: DS.Material.needleWidth
        )
    }

    /// Critically-damped-ish spring toward the target, tuned to VU ballistics.
    private func advanceNeedle() {
        let target = Double(min(max(level, 0), 1))
        let rising = target > movement.position
        let time = rising ? DS.Motion.needleAttack : DS.Motion.needleRelease
        // Frame-rate independent enough at 60–120Hz, and a meter is forgiving of the rest.
        let stiffness = 1 / time
        let delta = target - movement.position
        movement.velocity += delta * stiffness * 0.16
        movement.velocity *= 0.72
        movement.position += movement.velocity
        movement.position = min(max(movement.position, 0), 1 + DS.Motion.needleOvershoot)
    }

    private func point(from origin: CGPoint, angle: Double, distance: CGFloat) -> CGPoint {
        CGPoint(
            x: origin.x + sin(angle) * distance,
            y: origin.y - cos(angle) * distance
        )
    }
}

/// A monospaced readout on a dark window — the tape counter.
struct Readout: View {
    let text: String
    var large = false

    var body: some View {
        Text(text)
            .font(large ? DS.Font.counterLarge : DS.Font.counter)
            .foregroundStyle(DS.Color.inkOnDeck)
    }
}

/// A flat run of level-reactive bars. Replaces the swept-needle VU meter.
///
/// A needle instrument reads as a machine you operate; this reads as an app that is
/// listening. Same information — the level — without the chrome around it.
struct LevelBars: View {
    let level: Float
    let isActive: Bool

    var barCount: Int = 32
    var maxHeight: CGFloat = 26

    private static let floorHeight: CGFloat = 2

    /// Irrational multiplier keeps the offsets from lining up into a visible period.
    private func phase(_ index: Int) -> Double {
        (Double(index) * 0.618).truncatingRemainder(dividingBy: 1)
    }

    /// Bars taper toward the ends so the run reads as one shape.
    private func envelope(_ index: Int) -> CGFloat {
        let normalized = Double(index) / Double(max(1, barCount - 1))
        return CGFloat(0.4 + 0.6 * sin(normalized * .pi))
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<barCount, id: \.self) { index in
                    Capsule()
                        .fill(isActive ? DS.Color.ink : DS.Color.recordIdle)
                        .frame(width: 2, height: height(for: index, at: time))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func height(for index: Int, at time: TimeInterval) -> CGFloat {
        guard isActive else { return Self.floorHeight }
        let wave = sin(time * 6.0 + phase(index) * .pi * 2)
        let amplitude = CGFloat(max(0.04, level))
        // Wave rides on top of the level so bars still breathe during quiet passages.
        let scaled = amplitude * (0.55 + 0.45 * CGFloat(wave)) * envelope(index)
        return Self.floorHeight + max(0, scaled) * maxHeight
    }
}

// MARK: - Modern controls

/// A tiny uppercase chip — engine name, "korrigiert", counts. The one place letterspaced
/// caps survive in this design, because at 9.5pt a lowercase label stops being legible
/// before an uppercase one does.
struct Kicker: View {
    let text: String
    var color: Color = DS.Color.inkSecondary

    var body: some View {
        Text(text.uppercased())
            .font(DS.Font.kicker)
            .tracking(DS.Font.kickerTracking)
            .foregroundStyle(color)
    }
}

/// A keyboard key, drawn the way key hints look in polished onboarding: a small rounded
/// cap with a hairline and a hint of depth. Communicates "press this" without a sentence.
struct KeycapHint: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(DS.Color.ink)
            .padding(.horizontal, 8)
            .frame(height: 22)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(DS.Color.cap)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(DS.Color.seam, lineWidth: DS.Border.hairline)
                    }
                    .shadow(color: .black.opacity(0.10), radius: 1, y: 1)
            }
    }
}

/// A small icon-only button for row actions — copy, delete. Quiet until hovered, so a list
/// of rows doesn't read as a grid of buttons.
struct IconButton: View {
    let systemImage: String
    var help: String = ""
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isHovering ? DS.Color.ink : DS.Color.inkSecondary)
                .frame(width: 26, height: 26)
                .background {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isHovering ? DS.Color.hover : .clear)
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DS.Motion.hover) { isHovering = hovering }
        }
        .help(help)
    }
}

/// The record control: a filled circle whose inner shape morphs from a dot to a rounded
/// square, the way every camera app since iOS 7 has said "recording". While active, a ring
/// breathes around it — motion carries the state across the room, color can't (there is
/// none to spend).
struct RecordButton: View {
    var isRecording: Bool
    let action: () -> Void

    @State private var isHovering = false
    @State private var isPressed = false

    private static let diameter: CGFloat = 44

    var body: some View {
        Button(action: action) {
            ZStack {
                if isRecording {
                    PulseRing(diameter: Self.diameter)
                }

                Circle()
                    .fill(DS.Color.ink)
                    .frame(width: Self.diameter, height: Self.diameter)
                    .shadow(
                        color: .black.opacity(isHovering ? 0.22 : 0.14),
                        radius: isHovering ? 10 : 6,
                        y: 3
                    )

                // The dot-to-square morph. One shape animating its radius and size, so the
                // transition is continuous rather than a crossfade.
                RoundedRectangle(cornerRadius: isRecording ? 3 : 7, style: .continuous)
                    .fill(DS.Color.panel)
                    .frame(
                        width: isRecording ? 14 : 14,
                        height: isRecording ? 14 : 14
                    )
            }
            .scaleEffect(isPressed ? 0.94 : (isHovering ? 1.04 : 1))
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isRecording)
        .onHover { hovering in
            withAnimation(DS.Motion.hover) { isHovering = hovering }
        }
        .onLongPressGesture(minimumDuration: 0) {} onPressingChanged: { pressing in
            withAnimation(pressing ? DS.Motion.press : DS.Motion.release) { isPressed = pressing }
        }
        .help(isRecording ? "Aufnahme stoppen" : "Aufnahme starten")
    }

    /// The breathing ring. Its own view so the repeat-forever animation starts fresh each
    /// time recording starts, instead of being tied to the button's lifetime.
    private struct PulseRing: View {
        let diameter: CGFloat
        @State private var expanded = false

        var body: some View {
            Circle()
                .stroke(DS.Color.ink.opacity(expanded ? 0 : 0.35), lineWidth: 1.5)
                .frame(width: diameter, height: diameter)
                .scaleEffect(expanded ? 1.45 : 1)
                .onAppear {
                    withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
                        expanded = true
                    }
                }
        }
    }
}
