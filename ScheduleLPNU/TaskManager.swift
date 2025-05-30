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
    }
    
    func updateTask(_ updatedTask: Task) {
        var tasks = loadTasks()
        if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            tasks[index] = updatedTask
            saveTasks(tasks)
        }
    }
    
    func deleteTask(withId id: String) {
        var tasks = loadTasks()
        tasks.removeAll { $0.id == id }
        saveTasks(tasks)
    }
}
