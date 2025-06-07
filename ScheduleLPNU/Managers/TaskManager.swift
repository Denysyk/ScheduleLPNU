import Foundation

class TaskManager {
    static let shared = TaskManager()
    private let userDefaults = UserDefaults.standard
    private let tasksKey = "SavedTasks"
    
    private init() {}
    
    func saveTasks(_ tasks: [Task]) {
        do {
            let data = try JSONEncoder().encode(tasks)
            userDefaults.set(data, forKey: tasksKey)
        } catch {
            print("Error saving tasks: \(error)")
        }
    }
    
    func loadTasks() -> [Task] {
        guard let data = userDefaults.data(forKey: tasksKey) else {
            return []
        }
        
        do {
            let tasks = try JSONDecoder().decode([Task].self, from: data)
            return tasks.sorted { $0.createdDate > $1.createdDate }
        } catch {
            print("Error loading tasks: \(error)")
            
            // Якщо є проблема з декодуванням, очищуємо дані
            userDefaults.removeObject(forKey: tasksKey)
            return []
        }
    }
    
    func addTask(_ task: Task) {
        var tasks = loadTasks()
        tasks.insert(task, at: 0)
        saveTasks(tasks)
        
        // Плануємо сповіщення для нового завдання
        NotificationManager.shared.scheduleNotification(for: task)
        
        // Оновлюємо щоденні сповіщення
        NotificationManager.shared.scheduleReminderNotifications()
    }
    
    func updateTask(_ updatedTask: Task) {
        var tasks = loadTasks()
        if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            let oldTask = tasks[index]
            tasks[index] = updatedTask
            saveTasks(tasks)
            
            // Якщо завдання було виконано - скасовуємо його сповіщення
            if !oldTask.isCompleted && updatedTask.isCompleted {
                NotificationManager.shared.cancelNotification(for: updatedTask.id)
            }
            // Якщо завдання розмічено як невиконане - плануємо сповіщення знову
            else if oldTask.isCompleted && !updatedTask.isCompleted {
                NotificationManager.shared.scheduleNotification(for: updatedTask)
            }
            // Якщо змінилась дата або інші деталі - переплануємо сповіщення
            else if !updatedTask.isCompleted && (oldTask.dueDate != updatedTask.dueDate || oldTask.title != updatedTask.title) {
                NotificationManager.shared.cancelNotification(for: updatedTask.id)
                NotificationManager.shared.scheduleNotification(for: updatedTask)
            }
            
            // Оновлюємо щоденні та вечірні сповіщення
            NotificationManager.shared.scheduleReminderNotifications()
            NotificationManager.shared.scheduleMotivationalReminders()
        }
    }
    
    func deleteTask(withId id: String) {
        var tasks = loadTasks()
        tasks.removeAll { $0.id == id }
        saveTasks(tasks)
        
        // Скасовуємо сповіщення для видаленого завдання
        NotificationManager.shared.cancelNotification(for: id)
        
        // Оновлюємо щоденні сповіщення
        NotificationManager.shared.scheduleReminderNotifications()
    }
    
    // ДОДАНО: Зручний метод для позначення завдання як виконаного
    func completeTask(withId id: String) {
        var tasks = loadTasks()
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            var task = tasks[index]
            task.isCompleted = true
            updateTask(task) // Використовуємо існуючий updateTask який вже оновить сповіщення
        }
    }
    
    // ДОДАНО: Зручний метод для скасування виконання завдання
    func uncompleteTask(withId id: String) {
        var tasks = loadTasks()
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            var task = tasks[index]
            task.isCompleted = false
            updateTask(task) // Використовуємо існуючий updateTask який вже оновить сповіщення
        }
    }
}
