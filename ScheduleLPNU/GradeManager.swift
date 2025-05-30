import Foundation

class GradeManager {
    static let shared = GradeManager()
    private let userDefaults = UserDefaults.standard
    private let gradesKey = "SavedGrades"
    
    private init() {}
    
    // MARK: - Збереження та завантаження
    
    func saveGrades(_ grades: [SubjectGrade]) {
        do {
            let data = try JSONEncoder().encode(grades)
            userDefaults.set(data, forKey: gradesKey)
        } catch {
            print("Помилка збереження оцінок: \(error)")
        }
    }
    
    func loadGrades() -> [SubjectGrade] {
        guard let data = userDefaults.data(forKey: gradesKey) else {
            return []
        }
        
        do {
            let grades = try JSONDecoder().decode([SubjectGrade].self, from: data)
            return grades
        } catch {
            print("Помилка завантаження оцінок: \(error)")
            return []
        }
    }
    
    // MARK: - CRUD операції
    
    func addGrade(_ grade: SubjectGrade) {
        var grades = loadGrades()
        grades.append(grade)
        saveGrades(grades)
    }
    
    func updateGrade(_ updatedGrade: SubjectGrade) {
        var grades = loadGrades()
        if let index = grades.firstIndex(where: { $0.id == updatedGrade.id }) {
            grades[index] = updatedGrade
            saveGrades(grades)
        }
    }
    
    func deleteGrade(withId id: String) {
        var grades = loadGrades()
        grades.removeAll { $0.id == id }
        saveGrades(grades)
    }
    
    // MARK: - Обрахунок середнього балу (100-бальна шкала)
    
    func calculateGPA() -> Double {
        let grades = loadGrades().filter { $0.isCompleted }
        
        guard !grades.isEmpty else { return 0.0 }
        
        let totalGradePoints = grades.reduce(0.0) { sum, grade in
            return sum + grade.gradePoints
        }
        
        let totalCredits = grades.reduce(0) { sum, grade in
            return sum + grade.credits
        }
        
        guard totalCredits > 0 else { return 0.0 }
        
        return totalGradePoints / Double(totalCredits)
    }
    
    // Конвертація в 5-бальну систему для відображення
    func calculateGPA5Scale() -> Double {
        let grades = loadGrades().filter { $0.isCompleted }
        
        guard !grades.isEmpty else { return 0.0 }
        
        // Переводимо кожну оцінку в 5-бальну і знаходимо середнє арифметичне
        let sum5Scale = grades.reduce(0.0) { sum, grade in
            return sum + grade.gradeTo5Scale
        }
        
        return sum5Scale / Double(grades.count)
    }
    
    func getGradeStatistics() -> (gpa: Double, gpa5Scale: Double, totalCredits: Int, completedSubjects: Int, totalGradePoints: Double) {
        let grades = loadGrades().filter { $0.isCompleted }
        
        let totalCredits = grades.reduce(0) { $0 + $1.credits }
        let totalGradePoints = grades.reduce(0.0) { $0 + $1.gradePoints }
        let gpa = totalCredits > 0 ? totalGradePoints / Double(totalCredits) : 0.0
        let gpa5Scale = calculateGPA5Scale()
        
        return (gpa: gpa, gpa5Scale: gpa5Scale, totalCredits: totalCredits, completedSubjects: grades.count, totalGradePoints: totalGradePoints)
    }
    
    // MARK: - Імпорт з розкладу
    
    func importSubjectsFromSchedule() -> [String] {
        let savedSchedules = ScheduleManager.shared.getSavedSchedules()
        var subjectNames: Set<String> = []
        
        for schedule in savedSchedules {
            for day in schedule.scheduleDays {
                for lesson in day.lessons {
                    if !lesson.name.isEmpty && lesson.name != "Невідомо" {
                        subjectNames.insert(lesson.name)
                    }
                }
            }
        }
        
        return Array(subjectNames).sorted()
    }
}
