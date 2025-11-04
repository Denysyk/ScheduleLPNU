import Foundation
import EventKit

class CalendarManager {
    static let shared = CalendarManager()
    
    private let eventStore = EKEventStore()
    private let userDefaults = UserDefaults.standard
    private let calendarTasksKey = "CalendarTaskIds"
    private let calendarPermissionRequestedKey = "CalendarPermissionRequested"
    
    private init() {}
    
    // Запит дозволів на календар
    func requestCalendarAccess(completion: @escaping (Bool, Error?) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    completion(granted, error)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    completion(granted, error)
                }
            }
        }
    }
    
    // Перевірка статусу дозволів
    func checkCalendarAuthorizationStatus() -> EKAuthorizationStatus {
        if #available(iOS 17.0, *) {
            return EKEventStore.authorizationStatus(for: .event)
        } else {
            return EKEventStore.authorizationStatus(for: .event)
        }
    }
    // MARK: - Permission Management

    /// Перевіряє, чи потрібно запитувати дозвіл при першому запуску
    func shouldRequestPermissionOnFirstLaunch() -> Bool {
        // Якщо дозвіл вже визначено (granted або denied), не запитуємо
        let status = checkCalendarAuthorizationStatus()
        if status != .notDetermined {
            return false
        }
        
        // Якщо ми вже запитували раніше, не запитуємо знову
        let wasRequested = userDefaults.bool(forKey: calendarPermissionRequestedKey)
        return !wasRequested
    }

    /// Позначає що дозвіл був запитаний
    func markPermissionAsRequested() {
        userDefaults.set(true, forKey: calendarPermissionRequestedKey)
    }
    
    // Додати завдання в календар
    func addTaskToCalendar(task: Task, completion: @escaping (Bool, Error?) -> Void) {
        guard let dueDate = task.dueDate else {
            completion(false, NSError(domain: "CalendarManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Завдання не має дати виконання"]))
            return
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = task.title
        event.notes = task.description
        event.startDate = dueDate
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: dueDate) ?? dueDate
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // Додаємо лише 2 нагадування
        let oneDayBeforeAlarm = EKAlarm(relativeOffset: -86400) // 24 години
        let oneHourBeforeAlarm = EKAlarm(relativeOffset: -3600) // 1 година
        event.alarms = [oneDayBeforeAlarm, oneHourBeforeAlarm]
        
        do {
            try eventStore.save(event, span: .thisEvent)
            saveCalendarEventId(taskId: task.id, eventId: event.eventIdentifier)
            completion(true, nil)
        } catch {
            completion(false, error)
        }
    }
    
    // Видалити завдання з календаря
    func removeTaskFromCalendar(taskId: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let eventId = getCalendarEventId(for: taskId) else {
            completion(false, NSError(domain: "CalendarManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Подія не знайдена"]))
            return
        }
        
        guard let event = eventStore.event(withIdentifier: eventId) else {
            removeCalendarEventId(for: taskId)
            completion(false, NSError(domain: "CalendarManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Подія не існує в календарі"]))
            return
        }
        
        do {
            try eventStore.remove(event, span: .thisEvent)
            removeCalendarEventId(for: taskId)
            completion(true, nil)
        } catch {
            completion(false, error)
        }
    }
    
    // Оновити завдання в календарі
    func updateTaskInCalendar(task: Task, completion: @escaping (Bool, Error?) -> Void) {
        guard let eventId = getCalendarEventId(for: task.id),
              let event = eventStore.event(withIdentifier: eventId),
              let dueDate = task.dueDate else {
            completion(false, NSError(domain: "CalendarManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Не вдалося знайти подію для оновлення"]))
            return
        }
        
        event.title = task.title
        event.notes = task.description
        event.startDate = dueDate
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: dueDate) ?? dueDate
        
        // Оновлюємо нагадування
        let oneDayBeforeAlarm = EKAlarm(relativeOffset: -86400)
        let oneHourBeforeAlarm = EKAlarm(relativeOffset: -3600)
        event.alarms = [oneDayBeforeAlarm, oneHourBeforeAlarm]
        
        do {
            try eventStore.save(event, span: .thisEvent)
            completion(true, nil)
        } catch {
            completion(false, error)
        }
    }
    
    // Перевірити чи завдання в календарі
    func isTaskInCalendar(taskId: String) -> Bool {
        return getCalendarEventId(for: taskId) != nil
    }
    
    // MARK: - Private Methods
    
    private func saveCalendarEventId(taskId: String, eventId: String) {
        var mapping = getCalendarTasksMapping()
        mapping[taskId] = eventId
        userDefaults.set(mapping, forKey: calendarTasksKey)
    }
    
    private func getCalendarEventId(for taskId: String) -> String? {
        let mapping = getCalendarTasksMapping()
        return mapping[taskId]
    }
    
    private func removeCalendarEventId(for taskId: String) {
        var mapping = getCalendarTasksMapping()
        mapping.removeValue(forKey: taskId)
        userDefaults.set(mapping, forKey: calendarTasksKey)
    }
    
    private func getCalendarTasksMapping() -> [String: String] {
        return userDefaults.dictionary(forKey: calendarTasksKey) as? [String: String] ?? [:]
    }
}
