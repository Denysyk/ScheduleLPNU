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
        
        let notifications = [
            (hours: 24, identifier: "task_24h_\(task.id)", title: "Нагадування про завдання"),
            (hours: 1, identifier: "task_1h_\(task.id)", title: "Завдання незабаром!")
        ]
        
        for notification in notifications {
            let notificationDate = Calendar.current.date(byAdding: .hour, value: -notification.hours, to: dueDate)
            
            if let notificationDate = notificationDate, notificationDate > now {
                let content = UNMutableNotificationContent()
                content.title = notification.title
                content.body = task.title
                content.sound = .default
                content.badge = 1
                
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
    
   
}
