import Foundation

struct TaskStatistics {
    let totalTasks: Int
    let completedTasks: Int
    let pendingTasks: Int
    let completionRate: Double
    let categoryStats: [Task.TaskCategory: Int]
    let priorityStats: [Task.TaskPriority: Int]
    let todayTasks: Int
    let thisWeekTasks: Int
    
    init(tasks: [Task]) {
        self.totalTasks = tasks.count
        self.completedTasks = tasks.filter { $0.isCompleted }.count
        self.pendingTasks = tasks.filter { !$0.isCompleted }.count
        
        self.completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) * 100 : 0
        
        // Category statistics
        var categoryCount: [Task.TaskCategory: Int] = [:]
        for category in Task.TaskCategory.allCases {
            categoryCount[category] = tasks.filter { $0.category == category }.count
        }
        self.categoryStats = categoryCount
        
        // Priority statistics
        var priorityCount: [Task.TaskPriority: Int] = [:]
        for priority in Task.TaskPriority.allCases {
            priorityCount[priority] = tasks.filter { $0.priority == priority }.count
        }
        self.priorityStats = priorityCount
        
        // Today tasks
        let calendar = Calendar.current
        self.todayTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDateInToday(dueDate)
        }.count
        
        // This week tasks
        let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        self.thisWeekTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= weekAgo && dueDate <= Date()
        }.count
    }
}
