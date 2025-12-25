import SwiftUI

struct AboutView: View {
    private let appVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }()
    
    private let buildNumber: String = {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }()

    private let windowWidth: CGFloat = 280
    private let windowHeight: CGFloat = 300
    private let windowPadding: CGFloat = 24
    
    var body: some View {
        VStack {
            Spacer(minLength: 0)
            content
            Spacer(minLength: 0)
        }
        .padding(windowPadding)
        .frame(width: windowWidth, height: windowHeight)
    }

    private var content: some View {
        VStack(spacing: 16) {
            // App 图标 - 从 Bundle 加载 icns 或使用系统图标
            appIconView
                .frame(width: 80, height: 80)

            // App 名称
            Text("Quietly")
                .font(.title)
                .fontWeight(.semibold)

            // 版本号
            Text("版本 \(appVersion) (\(buildNumber))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // 描述
            Text("macOS 情境自动化工具")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()
                .padding(.horizontal, 20)

            // 版权信息
            VStack(spacing: 4) {
                Text("© 2024")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Link("GitHub: Quietly", destination: URL(string: "https://github.com")!)
                    .font(.caption)
            }
        }
    }
    
    // 加载 App 图标
    @ViewBuilder
    private var appIconView: some View {
        // 尝试从 Asset Catalog 加载 (需要在 Assets 中添加名为 "AppIconImage" 的 Image Set)
        if let iconImage = loadAppIcon() {
            Image(nsImage: iconImage)
                .resizable()
                .interpolation(.high)
        } else {
            // 回退：使用 SF Symbol
            Image(systemName: "moon.circle.fill")
                .resizable()
                .foregroundStyle(.blue)
        }
    }
    
    private func loadAppIcon() -> NSImage? {
        // 方法1：从 Bundle 加载 icns 文件
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let icon = NSImage(contentsOfFile: iconPath) {
            return icon
        }
        
        // 方法2：从 Info.plist 获取图标名称
        if let iconName = Bundle.main.infoDictionary?["CFBundleIconFile"] as? String,
           let iconPath = Bundle.main.path(forResource: iconName, ofType: iconName.hasSuffix(".icns") ? nil : "icns"),
           let icon = NSImage(contentsOfFile: iconPath) {
            return icon
        }
        
        // 方法3：使用 NSWorkspace 获取应用图标
        if let bundlePath = Bundle.main.bundlePath as String? {
            let icon = NSWorkspace.shared.icon(forFile: bundlePath)
            // 检查是否是有效图标（不是通用文档图标）
            if icon.size.width >= 32 {
                return icon
            }
        }
        
        return nil
    }
}
