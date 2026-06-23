import Foundation
import UserNotifications

class NotificationManager {

    static let shared = NotificationManager()

    // Запрос разрешения
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    // Проверить текущий статус разрешения
    func checkPermissionStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    // Запланировать ежедневное уведомление
    func scheduleDailyReminder(hour: Int, minute: Int) {
        // Сначала удаляем старое
        cancelDailyReminder()

        let content = UNMutableNotificationContent()
        content.title = "Привет, малышка! 💙"
        content.body = "Как прошёл день? Не забудь записать траты 💸"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "daily_expense_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Ошибка планирования уведомления: \(error)")
            }
        }
    }

    // Отменить уведомление
    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["daily_expense_reminder"]
        )
    }

    // Проверить — запланировано ли уведомление
    func isReminderScheduled(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests.contains { $0.identifier == "daily_expense_reminder" })
            }
        }
    }
}
