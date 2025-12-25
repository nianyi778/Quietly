import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private var didRequestAuthorization = false

    private init() {}

    func ensureAuthorizationRequested() {
        guard !didRequestAuthorization else { return }
        didRequestAuthorization = true

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("[NotificationManager] requestAuthorization error: \(error)")
            } else {
                print("[NotificationManager] authorization granted: \(granted)")
            }
        }
    }

    func post(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[NotificationManager] add notification error: \(error)")
            }
        }
    }
}
