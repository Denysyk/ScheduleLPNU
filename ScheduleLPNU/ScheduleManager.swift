//
//  ScheduleManager.swift
//  ScheduleLPNU
//
//  Created by Denys Brativnyk on 25.05.2025.
//

import Foundation

class ScheduleManager {
    static let shared = ScheduleManager()
    private let userDefaults = UserDefaults.standard
    private let savedSchedulesKey = "SavedSchedules"
    
    private init() {}
    
    func saveSchedule(_ schedule: SavedSchedule) {
        var savedSchedules = getSavedSchedules()
        
        // Видаляємо старий розклад з такою ж назвою, якщо є
        savedSchedules.removeAll { $0.id == schedule.id }
        
        // Додаємо новий розклад на початок
        savedSchedules.insert(schedule, at: 0)
        
        // Обмежуємо кількість збережених розкладів (наприклад, 10)
        if savedSchedules.count > 10 {
            savedSchedules = Array(savedSchedules.prefix(10))
        }
        
        saveSchedulesToUserDefaults(savedSchedules)
    }
    
    func getSavedSchedules() -> [SavedSchedule] {
        guard let data = userDefaults.data(forKey: savedSchedulesKey) else {
            return []
        }
        
        do {
            let schedules = try JSONDecoder().decode([SavedSchedule].self, from: data)
            return schedules
        } catch {
            print("Error decoding saved schedules: \(error)")
            return []
        }
    }
    
    func deleteSchedule(withId id: String) {
        var savedSchedules = getSavedSchedules()
        savedSchedules.removeAll { $0.id == id }
        saveSchedulesToUserDefaults(savedSchedules)
    }
    
    private func saveSchedulesToUserDefaults(_ schedules: [SavedSchedule]) {
        do {
            let data = try JSONEncoder().encode(schedules)
            userDefaults.set(data, forKey: savedSchedulesKey)
        } catch {
            print("Error encoding saved schedules: \(error)")
        }
    }
}
