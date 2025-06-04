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
        
        // Отримуємо поточні завдання
        let tasks = TaskManager.shared.loadTasks()
        let pendingTasks = tasks.filter { !$0.isCompleted }
        let todayTasks = getTodayTasks(from: tasks)
        
        // Визначаємо тип повідомлення
        let notificationContent = createDailyNotificationContent(
            pendingTasks: pendingTasks,
            todayTasks: todayTasks
        )
        
        // Створюємо щоденне нагадування о 9:00 ранку
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_reminder", content: notificationContent, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func getTodayTasks(from tasks: [Task]) -> [Task] {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard let dueDate = task.dueDate, !task.isCompleted else { return false }
            return calendar.isDateInToday(dueDate)
        }
    }
    
    private func createDailyNotificationContent(pendingTasks: [Task], todayTasks: [Task]) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        if todayTasks.isEmpty && pendingTasks.isEmpty {
            // Немає завдань - мотивуємо додати
            content.title = "🎯 Час планувати!"
            content.body = "Додайте нові завдання та досягайте своїх цілей разом з ScheduleLPNU"
            
        } else if todayTasks.isEmpty && !pendingTasks.isEmpty {
            // Є завдання, але не на сьогодні - заохочуємо продуктивність
            let motivationalMessages = [
                "💪 Гарний день для продуктивності! У вас є \(pendingTasks.count) завдань для виконання",
                "⭐ Почніть день з малого кроку до великої мети!",
                "🚀 Сьогодні чудовий день щоб наблизитися до своїх цілей!",
                "✨ Невеликі щоденні дії ведуть до великих результатів"
            ]
            content.title = "Доброго ранку!"
            content.body = motivationalMessages.randomElement() ?? motivationalMessages[0]
            
        } else {
            // Є завдання на сьогодні
            content.title = "📋 Завдання на сьогодні"
            
            if todayTasks.count == 1 {
                content.body = "У вас 1 завдання на сьогодні: \(todayTasks[0].title)"
            } else {
                content.body = "У вас \(todayTasks.count) завдань на сьогодні. Час братися до роботи! 💪"
            }
            
            // Додаємо badge з кількістю завдань на сьогодні
            content.badge = NSNumber(value: todayTasks.count)
        }
        
        return content
    }
    
    // ДОДАНО: Метод для планування мотивуючих повідомлень
    func scheduleMotivationalReminders() {
        // Скасовуємо старі мотивуючі повідомлення
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["evening_motivation"])
        
        let tasks = TaskManager.shared.loadTasks()
        let completedToday = getCompletedTodayTasks(from: tasks)
        
        // Вечірнє мотивуюче повідомлення о 20:00
        if !completedToday.isEmpty {
            let content = UNMutableNotificationContent()
            content.title = "🎉 Чудова робота!"
            content.body = "Сьогодні ви виконали \(completedToday.count) завдань. Продовжуйте в тому ж дусі!"
            content.sound = .default
            
            var dateComponents = DateComponents()
            dateComponents.calendar = Calendar.current
            dateComponents.hour = 20
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "evening_motivation", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    private func getCompletedTodayTasks(from tasks: [Task]) -> [Task] {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard task.isCompleted else { return false }
            // Припускаємо що дата виконання зберігається в createdDate (або можна додати completedDate)
            return calendar.isDateInToday(task.createdDate)
        }
    }
    
    // ДОДАНО: Метод для скасування всіх нагадувань
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "daily_reminder",
            "evening_motivation"
        ])
    }
}
