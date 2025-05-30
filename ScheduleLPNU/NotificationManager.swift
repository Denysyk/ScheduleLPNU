import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func scheduleNotification(for task: Task) {
        guard let dueDate = task.dueDate else { return }
        
        let now = Date()
        
        // Створюємо два нагадування: за 24 години і за 1 годину до дедлайну
        let notifications = [
            (hours: 24, identifier: "task_24h_\(task.id)", title: "Нагадування про завдання"),
            (hours: 1, identifier: "task_1h_\(task.id)", title: "Завдання незабаром!")
        ]
        
        for notification in notifications {
            let notificationDate = Calendar.current.date(byAdding: .hour, value: -notification.hours, to: dueDate)
            
            // Перевіряємо чи час нагадування не в минулому
            if let notificationDate = notificationDate, notificationDate > now {
                let content = UNMutableNotificationContent()
                content.title = notification.title
                content.body = task.title
                content.sound = .default
                content.badge = 1
                
                // ВИПРАВЛЕНО: використовуємо емодзі замість назв іконок
                let categoryEmoji = getCategoryEmoji(task.category)
                
                if notification.hours == 24 {
                    content.subtitle = "\(categoryEmoji) \(task.category.rawValue) • Залишилось 24 години"
                } else {
                    content.subtitle = "\(categoryEmoji) \(task.category.rawValue) • Залишилась 1 година"
                }
                
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate),
                    repeats: false
                )
                
                let request = UNNotificationRequest(
                    identifier: notification.identifier,
                    content: content,
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    // ДОДАНО: Метод для отримання емодзі категорій
    private func getCategoryEmoji(_ category: Task.TaskCategory) -> String {
        switch category {
        case .personal: return "👤"
        case .work: return "💼"
        case .study: return "📚"
        case .health: return "❤️"
        case .shopping: return "🛒"
        case .other: return "📁"
        }
    }
    
    func cancelNotification(for taskId: String) {
        let identifiers = [
            "task_24h_\(taskId)",
            "task_1h_\(taskId)"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func scheduleReminderNotifications() {
        // Спочатку скасовуємо старе нагадування
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
        
        // Щоденне нагадування о 9:00 ранку
        let content = UNMutableNotificationContent()
        content.title = "Перевірте ваші завдання"
        content.body = "Не забудьте подивитися на заплановані завдання на сьогодні"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
