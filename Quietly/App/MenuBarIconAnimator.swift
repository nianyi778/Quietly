import AppKit

struct MenuBarIconAnimatorConfig: Sendable {
    let frameCount: Int
    let framesPerSecond: Double

    /// 在 18x18 viewBox 里轨道半径是 7（x 方向）
    let orbitRadiusXRatio: CGFloat
    /// 倾斜椭圆的 y 半径（以 viewBox 单位定义），默认约 0.78 * 7
    let orbitRadiusYRatio: CGFloat
    /// 轨道倾角（弧度）
    let orbitRotationRadians: CGFloat
    /// 轨道描边宽度（以 viewBox 单位定义）
    let orbitStrokeWidth: CGFloat

    /// 小行星远/近的半径（以 viewBox 单位定义）
    let asteroidRadiusFar: CGFloat
    let asteroidRadiusNear: CGFloat

    static let `default` = MenuBarIconAnimatorConfig(
        frameCount: 24,
        framesPerSecond: 8,
        orbitRadiusXRatio: 7.0 / 18.0,
        orbitRadiusYRatio: 5.46 / 18.0,
        orbitRotationRadians: (-20.0 * .pi) / 180.0,
        orbitStrokeWidth: 1.2,
        asteroidRadiusFar: 0.9,
        asteroidRadiusNear: 1.7
    )
}

final class MenuBarIconAnimator {
    struct AsteroidFrame {
        let position: CGPoint
        let radius: CGFloat
        let occluderPath: CGPath?
        let occluderLineWidth: CGFloat
        let occluderVisible: Bool
    }

    private let baseImage: NSImage
    private let config: MenuBarIconAnimatorConfig

    private(set) var frames: [NSImage] = []

    init(baseImage: NSImage, config: MenuBarIconAnimatorConfig = .default) {
        self.baseImage = baseImage
        self.config = config
    }

    var frameInterval: TimeInterval {
        1.0 / max(1.0, config.framesPerSecond)
    }

    var frameCount: Int {
        config.frameCount
    }

    func asteroidFrame(phase: Int, in rect: CGRect) -> AsteroidFrame {
        let minSide = min(rect.width, rect.height)
        let scale = minSide / 18.0

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let orbitRx = minSide * config.orbitRadiusXRatio
        let orbitRy = minSide * config.orbitRadiusYRatio
        let orbitRotation = config.orbitRotationRadians

        let t = CGFloat(phase) / CGFloat(max(1, config.frameCount))
        let theta = t * .pi * 2

        // 椭圆参数方程 + 旋转
        let localX = orbitRx * cos(theta)
        let localY = orbitRy * sin(theta)
        let rotatedX = localX * cos(orbitRotation) - localY * sin(orbitRotation)
        let rotatedY = localX * sin(orbitRotation) + localY * cos(orbitRotation)

        let position = CGPoint(x: center.x + rotatedX, y: center.y + rotatedY)

        // 远小近大：按屏幕 y 方向计算
        let maxYOffset = hypot(orbitRx * sin(orbitRotation), orbitRy * cos(orbitRotation))
        let yNorm = maxYOffset > 0 ? max(-1, min(1, rotatedY / maxYOffset)) : 0
        let depth = (1 - yNorm) * 0.5 // 0(远) -> 1(近)
        let radiusViewBox = config.asteroidRadiusFar + (config.asteroidRadiusNear - config.asteroidRadiusFar) * depth
        let radius = radiusViewBox * scale

        let occluderVisible = rotatedY > 0
        let occluderLineWidth = config.orbitStrokeWidth * scale
        let occluderPath = occluderVisible
            ? makeOccluderOrbitSegmentPath(
                center: center,
                orbitRx: orbitRx,
                orbitRy: orbitRy,
                orbitRotation: orbitRotation,
                theta: theta,
                coverRadius: radius
            )
            : nil

        return AsteroidFrame(
            position: position,
            radius: radius,
            occluderPath: occluderPath,
            occluderLineWidth: occluderLineWidth,
            occluderVisible: occluderVisible
        )
    }

    func prepareFramesIfNeeded() {
        guard frames.isEmpty else { return }
        frames = (0..<config.frameCount).compactMap { renderFrame(phase: $0) }
        if frames.isEmpty {
            frames = [baseImage]
        }
    }

    private func renderFrame(phase: Int) -> NSImage? {
        let size = baseImage.size
        guard size.width > 0, size.height > 0 else { return nil }

        let image = NSImage(size: size)
        image.isTemplate = true

        image.lockFocus()
        defer { image.unlockFocus() }

        NSGraphicsContext.current?.imageInterpolation = .high

        baseImage.draw(in: NSRect(origin: .zero, size: size))
        drawMonochromeAsteroid(in: NSRect(origin: .zero, size: size), phase: phase)

        return image
    }

    private func drawMonochromeAsteroid(in rect: NSRect, phase: Int) {
        let frame = asteroidFrame(phase: phase, in: rect)
        let radius = max(0.5, frame.radius)

        let asteroidRect = NSRect(
            x: frame.position.x - radius,
            y: frame.position.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        NSColor.black.setFill()
        NSBezierPath(ovalIn: asteroidRect).fill()

        guard frame.occluderVisible, let occluderPath = frame.occluderPath else { return }
        NSColor.black.setStroke()

        let path = NSBezierPath()
        path.append(NSBezierPath(cgPath: occluderPath))
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.lineWidth = frame.occluderLineWidth
        path.stroke()
    }

    private func makeOccluderOrbitSegmentPath(
        center: CGPoint,
        orbitRx: CGFloat,
        orbitRy: CGFloat,
        orbitRotation: CGFloat,
        theta: CGFloat,
        coverRadius: CGFloat
    ) -> CGPath {
        // 组合方案：缩短遮挡弧段，避免“背面时像变黑”
        let desiredArcLength = coverRadius * 1.7
        let approxRadius = (orbitRx + orbitRy) * 0.5
        let delta = approxRadius > 0 ? (desiredArcLength / approxRadius) : 0.2
        let start = theta - delta
        let end = theta + delta

        let segments = 12
        let path = CGMutablePath()
        for i in 0...segments {
            let u = CGFloat(i) / CGFloat(segments)
            let a = start + (end - start) * u

            let localX = orbitRx * cos(a)
            let localY = orbitRy * sin(a)
            let rotatedX = localX * cos(orbitRotation) - localY * sin(orbitRotation)
            let rotatedY = localX * sin(orbitRotation) + localY * cos(orbitRotation)

            let p = CGPoint(x: center.x + rotatedX, y: center.y + rotatedY)
            if i == 0 {
                path.move(to: p)
            } else {
                path.addLine(to: p)
            }
        }

        return path
    }
}
