import Foundation
import UserNotifications

@MainActor
final class DailyReminderManager: ObservableObject {
    @Published private(set) var isAuthorized = false
    @Published var errorMessage: String?

    private let center = UNUserNotificationCenter.current()
    private let identifier = "energyCoach.dailyReminder"

    init() {
        Task { await refreshAuthorization() }
    }

    func refreshAuthorization() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    func enable(hour: Int, minute: Int) async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            guard granted else {
                errorMessage = "Notifications are disabled. You can enable them later in Settings."
                return false
            }
            try await schedule(hour: hour, minute: minute)
            return true
        } catch {
            errorMessage = "The daily reminder could not be enabled."
            return false
        }
    }

    func schedule(hour: Int, minute: Int) async throws {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "How is your energy today?"
        content.body = "Open Energy Coach for your daily score and check-in."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    func disable() {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
