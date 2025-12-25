import AppKit
import SwiftUI

/// 窗口管理器：负责创建和管理独立窗口
@MainActor
final class WindowManager {
    static let shared = WindowManager()
    
    private var aboutWindow: NSWindow?
    private var preferencesWindow: NSWindow?
    
    private init() {}
    
    // MARK: - About Window
    
    func showAboutWindow() {
        if let window = aboutWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let aboutView = AboutView()
        let hostingController = NSHostingController(rootView: aboutView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "关于 Quietly"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        
        // 居中到屏幕正中间
        centerWindowOnScreen(window)
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        self.aboutWindow = window
    }
    
    // MARK: - Preferences Window
    
    func showPreferencesWindow() {
        if let window = preferencesWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let preferencesView = PreferencesView()
        let hostingController = NSHostingController(rootView: preferencesView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "偏好设置"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        
        // 居中到屏幕正中间
        centerWindowOnScreen(window)
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        self.preferencesWindow = window
    }
    
    // MARK: - Helper
    
    private func centerWindowOnScreen(_ window: NSWindow) {
        guard let screen = NSScreen.main else {
            window.center()
            return
        }
        
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        
        let x = screenFrame.origin.x + (screenFrame.width - windowSize.width) / 2
        let y = screenFrame.origin.y + (screenFrame.height - windowSize.height) / 2
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
