import SwiftUI
import ServiceManagement

struct PreferencesView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showNotifications") private var showNotifications = true
    @AppStorage("pollInterval") private var pollInterval = 5
    
    private let pollIntervalOptions = [3, 5, 10, 15, 30]
    private let windowWidth: CGFloat = 340
    private let windowHeight: CGFloat = 240
    private let windowPadding: CGFloat = 24
    
    var body: some View {
        VStack {
            Spacer(minLength: 0)
            HStack {
                Spacer(minLength: 0)
                content
                    .frame(width: windowWidth - windowPadding * 2, alignment: .leading)
                Spacer(minLength: 0)
            }
            Spacer(minLength: 0)
        }
        .padding(windowPadding)
        .frame(width: windowWidth, height: windowHeight)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 通用设置
            VStack(alignment: .leading, spacing: 12) {
                Text("通用")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Toggle("开机时自动启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }

                Toggle("显示通知", isOn: $showNotifications)
            }

            Divider()

            // 轮询设置
            VStack(alignment: .leading, spacing: 12) {
                Text("状态检测")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("轮询间隔")
                    Spacer()
                    Picker("", selection: $pollInterval) {
                        ForEach(pollIntervalOptions, id: \.self) { interval in
                            Text("\(interval) 秒").tag(interval)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
            }
        }
    }
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to set launch at login: \(error)")
        }
    }
}

#Preview {
    PreferencesView()
}
