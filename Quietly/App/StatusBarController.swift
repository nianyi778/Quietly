import AppKit
import SwiftUI
import Combine
import QuartzCore

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    private var iconAnimator: MenuBarIconAnimator?
    private var animationTimer: Timer?
    private var frameIndex: Int = 0

    private let asteroidLayer = CAShapeLayer()
    private let occluderLayer = CAShapeLayer()

    init<V: View>(model: AppModel, rootView: @escaping () -> V) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 320, height: 420)
        self.popover = popover
        
        // 使用闭包创建视图
        let hostingController = NSHostingController(rootView: rootView())
        popover.contentViewController = hostingController

        if let button = statusItem.button {
            // 优先使用自定义图标，回退到 SF Symbol
            if let customImage = NSImage(named: "MenuBarIcon") {
                customImage.isTemplate = true  // 关键：自动适配深浅色模式
                button.image = customImage
                print("Using custom MenuBarIcon")

                let animator = MenuBarIconAnimator(baseImage: customImage)
                self.iconAnimator = animator

                setupLayers(for: button)
            } else if let sfImage = NSImage(systemSymbolName: "moon.circle", accessibilityDescription: "Quietly") {
                sfImage.isTemplate = true
                button.image = sfImage
                print("Fallback to SF Symbol: moon.circle")
            } else {
                print("Error: Failed to load any icon for status bar.")
                button.title = "Q"
            }

            model.$isPaused
                .removeDuplicates()
                .sink { [weak self] isPaused in
                    self?.setAsteroidAnimating(!isPaused)
                }
                .store(in: &cancellables)

            // 初始化状态：根据当前 paused 状态决定是否旋转
            setAsteroidAnimating(!model.isPaused)

            button.action = #selector(togglePopover(_:))
            button.target = self
            
            print("StatusBarController initialized. Button: \(button), Image: \(String(describing: button.image))")
        } else {
            print("Error: statusItem.button is nil")
        }
        
        // 监听点击外部事件，关闭弹窗
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let self = self, self.popover.isShown {
                self.popover.performClose(nil)
            }
        }
    }
    
    deinit {
        animationTimer?.invalidate()
        animationTimer = nil
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    /// 关闭弹窗（供外部调用）
    func closePopover() {
        if popover.isShown {
            popover.performClose(nil)
        }
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            // 激活应用并获取焦点
            NSApp.activate(ignoringOtherApps: true)
            
            // 最稳的锚点：用 button.bounds 保证点击与箭头定位一致
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

            // 让 popover 更贴近菜单栏：在窗口创建后上移少量像素
            DispatchQueue.main.async { [weak self] in
                guard let self, let window = self.popover.contentViewController?.view.window else { return }
                var frame = window.frame
                frame.origin.y += 6
                window.setFrame(frame, display: true)
            }
            
            // 确保 popover 窗口获取焦点
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func setupRotationTargetLayer(for button: NSStatusBarButton) {
        button.wantsLayer = true
    }

    private func setupLayers(for button: NSStatusBarButton) {
        button.wantsLayer = true

        asteroidLayer.actions = [
            "position": NSNull(),
            "path": NSNull(),
            "fillColor": NSNull(),
            "opacity": NSNull()
        ]
        occluderLayer.actions = [
            "path": NSNull(),
            "strokeColor": NSNull(),
            "lineWidth": NSNull(),
            "opacity": NSNull()
        ]

        occluderLayer.fillColor = nil
        occluderLayer.lineCap = .round
        occluderLayer.lineJoin = .round

        // 先确保不会重复添加
        asteroidLayer.removeFromSuperlayer()
        occluderLayer.removeFromSuperlayer()

        button.layer?.addSublayer(asteroidLayer)
        button.layer?.addSublayer(occluderLayer)

        // 初始绘制
        updateAsteroidLayers(for: button, running: false)
    }

    private func setAsteroidAnimating(_ animating: Bool) {
        guard let button = statusItem.button else { return }

        if animating {
            startAsteroidAnimation(for: button)
        } else {
            stopAsteroidAnimation(for: button)
        }
    }

    private func startAsteroidAnimation(for button: NSStatusBarButton) {
        guard animationTimer == nil else { return }
        guard let animator = iconAnimator else { return }

        animationTimer = Timer.scheduledTimer(
            timeInterval: animator.frameInterval,
            target: self,
            selector: #selector(handleAsteroidTimerFired(_:)),
            userInfo: nil,
            repeats: true
        )

        // 立即刷新一次，避免“启动后等一拍才动”
        updateAsteroidLayers(for: button, running: true)
    }

    private func stopAsteroidAnimation(for button: NSStatusBarButton) {
        animationTimer?.invalidate()
        animationTimer = nil

        // 暂停时：停在当前位置（不重置 frameIndex），只换颜色
        updateAsteroidLayers(for: button, running: false)
    }

    @objc private func handleAsteroidTimerFired(_ timer: Timer) {
        guard let button = statusItem.button else { return }
        guard let animator = iconAnimator else { return }

        frameIndex = (frameIndex + 1) % max(1, animator.frameCount)
        updateAsteroidLayers(for: button, running: true)
    }

    private func updateAsteroidLayers(for button: NSStatusBarButton, running: Bool) {
        guard let animator = iconAnimator else { return }
        guard let hostLayer = button.layer else { return }

        // 动态颜色：底图仍走模板；小球用产品状态色
        let asteroidColor = running ? NSColor.systemGreen : NSColor.systemOrange
        asteroidLayer.fillColor = asteroidColor.cgColor

        // 遮挡段颜色：跟随小球当前颜色，避免背面出现“黑边”
        occluderLayer.strokeColor = asteroidColor.cgColor

        // 使用 button.bounds 作为绘制坐标系
        let frame = animator.asteroidFrame(phase: frameIndex, in: hostLayer.bounds)

        let radius = max(0.5, frame.radius)
        let asteroidPath = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        asteroidLayer.path = asteroidPath
        asteroidLayer.position = frame.position
        asteroidLayer.opacity = frame.occluderVisible ? 0.72 : 1.0

        occluderLayer.path = frame.occluderPath
        occluderLayer.lineWidth = frame.occluderLineWidth * 0.75
        occluderLayer.opacity = frame.occluderVisible ? 1.0 : 0.0
    }
}
