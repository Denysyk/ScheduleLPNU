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
            userDefaults.removeObject(forKey: tasksKey)
            return []
        }
    }
    
    func addTask(_ task: Task) {
        var tasks = loadTasks()
        tasks.insert(task, at: 0)
        saveTasks(tasks)
        
        // ТІЛЬКИ сповіщення для конкретного завдання
        NotificationManager.shared.scheduleNotification(for: task)
    }
    
    func updateTask(_ updatedTask: Task) {
        var tasks = loadTasks()
        if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            let oldTask = tasks[index]
            tasks[index] = updatedTask
            saveTasks(tasks)
            
            // Обробка сповіщень
            if !oldTask.isCompleted && updatedTask.isCompleted {
                NotificationManager.shared.cancelNotification(for: updatedTask.id)
                
                // Видаляємо з календаря при виконанні
                if updatedTask.isInCalendar {
                    CalendarManager.shared.removeTaskFromCalendar(taskId: updatedTask.id) { _, _ in }
                }
            } else if oldTask.isCompleted && !updatedTask.isCompleted {
                NotificationManager.shared.scheduleNotification(for: updatedTask)
                
                // НОВЕ: Повертаємо в календар при uncomplete
                if updatedTask.isInCalendar && updatedTask.dueDate != nil {
                    CalendarManager.shared.addTaskToCalendar(task: updatedTask) { _, _ in }
                }
            } else if !updatedTask.isCompleted && (oldTask.dueDate != updatedTask.dueDate || oldTask.title != updatedTask.title) {
                NotificationManager.shared.cancelNotification(for: updatedTask.id)
                NotificationManager.shared.scheduleNotification(for: updatedTask)
                
                // Оновлюємо в календарі якщо там є
                if updatedTask.isInCalendar {
                    CalendarManager.shared.updateTaskInCalendar(task: updatedTask) { _, _ in }
                }
            }
        }
    }
    
    func deleteTask(withId id: String) {
        var tasks = loadTasks()
        
        // Знаходимо завдання перед видаленням
        if let task = tasks.first(where: { $0.id == id }), task.isInCalendar {
            CalendarManager.shared.removeTaskFromCalendar(taskId: id) { _, _ in }
        }
        
        tasks.removeAll { $0.id == id }
        saveTasks(tasks)
        
        // ТІЛЬКИ скасовуємо сповіщення для цього завдання
        NotificationManager.shared.cancelNotification(for: id)
    }
    
    func completeTask(withId id: String) {
        var tasks = loadTasks()
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            var task = tasks[index]
            task.isCompleted = true
            updateTask(task)
        }
    }
    
    func uncompleteTask(withId id: String) {
        var tasks = loadTasks()
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            var task = tasks[index]
            task.isCompleted = false
            updateTask(task)
        }
    }
    
    // MARK: - Calendar Integration
    
    func addTaskToCalendar(taskId: String, completion: @escaping (Bool, String?) -> Void) {
        var tasks = loadTasks()
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else {
            completion(false, "Завдання не знайдено")
            return
        }
        
        var task = tasks[index]
        
        CalendarManager.shared.addTaskToCalendar(task: task) { success, error in
            if success {
                task.isInCalendar = true
                tasks[index] = task
                self.saveTasks(tasks)
                completion(true, nil)
            } else {
                completion(false, error?.localizedDescription ?? "Невідома помилка")
            }
        }
    }
    
    func removeTaskFromCalendar(taskId: String, completion: @escaping (Bool, String?) -> Void) {
        var tasks = loadTasks()
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else {
            completion(false, "Завдання не знайдено")
            return
        }
        
        var task = tasks[index]
        
        CalendarManager.shared.removeTaskFromCalendar(taskId: taskId) { success, error in
            if success || error != nil {
                task.isInCalendar = false
                tasks[index] = task
                self.saveTasks(tasks)
                completion(true, nil)
            } else {
                completion(false, error?.localizedDescription ?? "Невідома помилка")
            }
        }
    }
}
