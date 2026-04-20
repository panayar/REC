import SwiftUI

/// The Rec logo — renders the SVG path as a pure shape.
/// White "REC" text with a red recording dot, transparent background.
struct RecLogo: View {
    var height: CGFloat = 16

    private var s: CGFloat { height / 89.0 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // REC text
            RecTextShape()
                .fill(.primary)
                .frame(width: 131 * s, height: 59.42 * s)

            // Red dot
            Circle()
                .fill(Color(red: 1.0, green: 0.25, blue: 0.26))
                .frame(width: 15.7 * s, height: 15.7 * s)
                .offset(x: 120 * s, y: 43.4 * s)
        }
        .frame(width: 136 * s, height: 59.42 * s)
    }
}

/// The "REC" letter shapes as a single Path, origin at (0,0).
struct RecTextShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 131.0
        let sy = rect.height / 59.42

        var p = Path()

        // R
        p.move(to: pt(0, 0, sx, sy))
        p.addLine(to: pt(35.65, 0, sx, sy))
        p.addLine(to: pt(35.65, 5.94, sx, sy))
        p.addLine(to: pt(41.59, 5.94, sx, sy))
        p.addLine(to: pt(41.59, 29.71, sx, sy))
        p.addLine(to: pt(35.65, 29.71, sx, sy))
        p.addLine(to: pt(35.65, 35.65, sx, sy))
        p.addLine(to: pt(41.59, 35.65, sx, sy))
        p.addLine(to: pt(41.59, 59.42, sx, sy))
        p.addLine(to: pt(29.71, 59.42, sx, sy))
        p.addLine(to: pt(29.71, 41.59, sx, sy))
        p.addLine(to: pt(11.88, 41.59, sx, sy))
        p.addLine(to: pt(11.88, 59.42, sx, sy))
        p.addLine(to: pt(0, 59.42, sx, sy))
        p.closeSubpath()
        // R hole
        p.move(to: pt(11.88, 11.88, sx, sy))
        p.addLine(to: pt(29.71, 11.88, sx, sy))
        p.addLine(to: pt(29.71, 29.71, sx, sy))
        p.addLine(to: pt(11.88, 29.71, sx, sy))
        p.closeSubpath()

        // E
        p.move(to: pt(47.55, 0, sx, sy))
        p.addLine(to: pt(83.20, 0, sx, sy))
        p.addLine(to: pt(83.20, 11.88, sx, sy))
        p.addLine(to: pt(59.43, 11.88, sx, sy))
        p.addLine(to: pt(59.43, 23.77, sx, sy))
        p.addLine(to: pt(77.26, 23.77, sx, sy))
        p.addLine(to: pt(77.26, 35.65, sx, sy))
        p.addLine(to: pt(59.43, 35.65, sx, sy))
        p.addLine(to: pt(59.43, 47.53, sx, sy))
        p.addLine(to: pt(83.20, 47.53, sx, sy))
        p.addLine(to: pt(83.20, 59.42, sx, sy))
        p.addLine(to: pt(47.55, 59.42, sx, sy))
        p.closeSubpath()

        // C
        p.move(to: pt(95.08, 0, sx, sy))
        p.addLine(to: pt(124.79, 0, sx, sy))
        p.addLine(to: pt(124.79, 5.94, sx, sy))
        p.addLine(to: pt(130.73, 5.94, sx, sy))
        p.addLine(to: pt(130.73, 17.83, sx, sy))
        p.addLine(to: pt(118.85, 17.83, sx, sy))
        p.addLine(to: pt(118.85, 11.88, sx, sy))
        p.addLine(to: pt(106.96, 11.88, sx, sy))
        p.addLine(to: pt(106.96, 17.83, sx, sy))
        p.addLine(to: pt(101.02, 17.83, sx, sy))
        p.addLine(to: pt(101.02, 41.59, sx, sy))
        p.addLine(to: pt(106.96, 41.59, sx, sy))
        p.addLine(to: pt(106.96, 47.53, sx, sy))
        p.addLine(to: pt(118.85, 47.53, sx, sy))
        p.addLine(to: pt(118.85, 41.59, sx, sy))
        p.addLine(to: pt(130.73, 41.59, sx, sy))
        p.addLine(to: pt(130.73, 53.47, sx, sy))
        p.addLine(to: pt(124.79, 53.47, sx, sy))
        p.addLine(to: pt(124.79, 59.42, sx, sy))
        p.addLine(to: pt(95.08, 59.42, sx, sy))
        p.addLine(to: pt(95.08, 53.47, sx, sy))
        p.addLine(to: pt(89.14, 53.47, sx, sy))
        p.addLine(to: pt(89.14, 5.94, sx, sy))
        p.addLine(to: pt(95.08, 5.94, sx, sy))
        p.closeSubpath()

        return p
    }

    private func pt(_ x: CGFloat, _ y: CGFloat, _ sx: CGFloat, _ sy: CGFloat) -> CGPoint {
        CGPoint(x: x * sx, y: y * sy)
    }
}
