import SwiftUI

/// OC Flow palette. Monochrome, following the O.C. Hairsystems mark.
enum Brand {
    static let ink = Color.white
    static let inkDim = Color.white.opacity(0.38)
    static let hairline = Color.white.opacity(0.14)
    static let surface = Color(red: 0.043, green: 0.043, blue: 0.047)
    static let error = Color(red: 0.94, green: 0.36, blue: 0.32)
}

// MARK: - The mark

/// The O.C. monogram, drawn rather than shipped as a bitmap.
///
/// At HUD size the mark is about 24pt wide, where a downscaled PNG turns to mush and a
/// vector stays crisp. Proportions are taken from the O.C. Hairsystems logo, normalized to
/// a 700 × 278 box: two rings of equal diameter, each trailed by a full stop sitting on the
/// baseline, and the C opening to the right.
struct OCMark: Shape {
    /// Design-space geometry. Every value below is in the 700 × 278 box.
    private enum G {
        static let boxWidth: CGFloat = 700
        static let boxHeight: CGFloat = 278
        static let stroke: CGFloat = 48
        static let letterDiameter: CGFloat = 278
        static let dotDiameter: CGFloat = 55
        static let oCenterX: CGFloat = 139
        static let firstDotCenterX: CGFloat = 317
        static let cCenterX: CGFloat = 499
        static let secondDotCenterX: CGFloat = 672
        /// Dots sit on the baseline, not on the optical center.
        static let dotCenterY: CGFloat = boxHeight - dotDiameter / 2
        /// The C's gap, measured from the 3 o'clock position.
        static let cGap: CGFloat = 40
    }

    func path(in rect: CGRect) -> Path {
        // Uniform scale, then center — so the mark never distorts in a non-matching frame.
        let scale = min(rect.width / G.boxWidth, rect.height / G.boxHeight)
        let drawn = CGSize(width: G.boxWidth * scale, height: G.boxHeight * scale)
        let origin = CGPoint(
            x: rect.midX - drawn.width / 2,
            y: rect.midY - drawn.height / 2
        )

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x * scale, y: origin.y + y * scale)
        }

        let letterRadius = (G.letterDiameter - G.stroke) / 2 * scale
        let strokeWidth = G.stroke * scale
        let letterCenterY = G.letterDiameter / 2

        var path = Path()

        // O — a closed ring.
        path.addPath(
            Path { ring in
                ring.addArc(
                    center: point(G.oCenterX, letterCenterY),
                    radius: letterRadius,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360),
                    clockwise: false
                )
            }
            .strokedPath(StrokeStyle(lineWidth: strokeWidth))
        )

        // C — the same ring with a gap on the right.
        path.addPath(
            Path { arc in
                arc.addArc(
                    center: point(G.cCenterX, letterCenterY),
                    radius: letterRadius,
                    startAngle: .degrees(G.cGap),
                    endAngle: .degrees(360 - G.cGap),
                    clockwise: false
                )
            }
            .strokedPath(StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))
        )

        for centerX in [G.firstDotCenterX, G.secondDotCenterX] {
            let center = point(centerX, G.dotCenterY)
            let radius = G.dotDiameter / 2 * scale
            path.addEllipse(
                in: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
            )
        }

        return path
    }
}

// MARK: - The pill

/// The pill that floats while you hold the key.
///
/// Two elements and nothing else: the mark, so it is obvious whose app is listening, and a
/// single continuous line that answers the only question the pill has to answer — is it
/// hearing me?
///
/// The live transcript deliberately does not render here. It used to, which meant the pill
/// resized mid-sentence and pulled the eye away from the field being dictated into. The
/// text belongs in the field; the pill only has to prove the app is awake.
struct HUDView: View {
    @Bindable var controller: DictationController

    static let size = CGSize(width: 196, height: 44)

    var body: some View {
        HStack(spacing: 0) {
            OCMark()
                .fill(phase == .rest ? Brand.inkDim : Brand.ink)
                .frame(width: 36, height: 15)
                .animation(.easeOut(duration: 0.25), value: phase)

            Rectangle()
                .fill(Brand.hairline)
                .frame(width: 1, height: 16)
                .padding(.horizontal, 14)

            ZStack {
                if let message = errorMessage {
                    Text(message)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Brand.error)
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else {
                    FlowLine(level: controller.level, phase: phase)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.leading, 18)
        .padding(.trailing, 18)
        .frame(width: Self.size.width, height: Self.size.height)
        .background {
            Capsule(style: .continuous)
                .fill(Brand.surface)
                // The border is a gradient, brighter along the top edge — the one detail
                // that makes a flat dark pill read as a lit object instead of a cutout.
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.22), .white.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                }
                .shadow(color: .black.opacity(0.5), radius: 22, y: 8)
        }
        // Entry: the pill grows in from 94% as the panel fades. Keyed to phase, so it also
        // settles back when dictation ends rather than popping off at full size.
        .scaleEffect(phase == .rest ? 0.94 : 1)
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: phase)
    }

    private var errorMessage: String? {
        if case .error(let message) = controller.state { return message }
        return nil
    }

    private var phase: FlowPhase {
        switch controller.state {
        case .listening, .starting: .live
        case .finishing: .settling
        case .idle, .error: .rest
        }
    }
}

enum FlowPhase { case live, settling, rest }

// MARK: - The line

/// One continuous stroke that rides the mic level.
///
/// A line rather than a bar graph, for two reasons. Bars are what every dictation app
/// draws, and a single stroke says "flow" without anyone having to read the name. It also
/// degrades better: at rest it collapses to a hairline, which reads as calm rather than as
/// twelve bars stuck at their minimum height.
struct FlowLine: View {
    let level: Float
    let phase: FlowPhase
    /// The HUD is always dark, so white is the default — the main window passes its own
    /// appearance-aware colors, otherwise the line vanishes on a light panel.
    var ink: Color = Brand.ink
    var inkDim: Color = Brand.inkDim

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: phase == .rest)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                context.stroke(
                    Self.path(in: size, time: time, level: CGFloat(level), phase: phase),
                    with: .color(phase == .live ? ink : inkDim),
                    style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .frame(height: 22)
    }

    /// Amplitude at rest, as a fraction of half the available height.
    private static let restAmplitude: CGFloat = 0.0
    /// The travelling pulse while the transcript is still being written.
    private static let settleAmplitude: CGFloat = 0.30

    private static func path(in size: CGSize, time: TimeInterval, level: CGFloat, phase: FlowPhase) -> Path {
        let midY = size.height / 2
        let maxAmplitude = size.height / 2

        var path = Path()
        path.move(to: CGPoint(x: 0, y: midY))

        // One sample every 1.2pt: fine enough that the curve reads as smooth, coarse enough
        // that a 60fps redraw stays cheap.
        let step: CGFloat = 1.2
        var x: CGFloat = 0
        while x <= size.width {
            let normalized = x / size.width
            // Taper both ends so the stroke resolves into the hairline instead of being
            // clipped mid-swing by the pill's edge. The exponent flattens the taper, which
            // keeps the middle two-thirds at close to full swing instead of only the center.
            let envelope = pow(sin(normalized * .pi), 0.65)

            let amplitude: CGFloat
            var wave: CGFloat
            switch phase {
            case .rest:
                amplitude = restAmplitude
                wave = 0
            case .settling:
                amplitude = settleAmplitude
                // A single slow travelling bump — there is no mic input left to react to.
                wave = sin(normalized * .pi * 2 - time * 2.4)
            case .live:
                amplitude = max(0.10, min(1.0, level * 2.2))
                // Two components at an irrational ratio, so the shape never visibly repeats.
                wave = 0.58 * sin(normalized * 15.0 - time * 8.0)
                     + 0.42 * sin(normalized * 24.5 + time * 5.1)
                // The two rarely peak together, so the sum sits well below ±1 on its own.
                // Scaling then clipping keeps a loud passage looking loud.
                wave = max(-1.0, min(1.0, wave * 1.3))
            }

            let y = midY + wave * amplitude * envelope * maxAmplitude
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }
        path.addLine(to: CGPoint(x: size.width, y: midY))

        return path
    }
}
