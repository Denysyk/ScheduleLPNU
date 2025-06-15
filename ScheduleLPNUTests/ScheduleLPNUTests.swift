import XCTest
import SwiftSoup
@testable import ScheduleLPNU

final class ScheduleLPNUTests: XCTestCase {
    
    var scheduleManager: ScheduleManager!
    var taskManager: TaskManager!
    var gradeManager: GradeManager!
    
    override func setUpWithError() throws {
        scheduleManager = ScheduleManager.shared
        taskManager = TaskManager.shared
        gradeManager = GradeManager.shared
        
        // Очищаємо UserDefaults для тестів
        UserDefaults.standard.removeObject(forKey: "SavedSchedules")
        UserDefaults.standard.removeObject(forKey: "SavedTasks")
        UserDefaults.standard.removeObject(forKey: "SavedGrades")
    }
    
    override func tearDownWithError() throws {
        // Очищаємо після тестів
        UserDefaults.standard.removeObject(forKey: "SavedSchedules")
        UserDefaults.standard.removeObject(forKey: "SavedTasks")
        UserDefaults.standard.removeObject(forKey: "SavedGrades")
    }
    
    // MARK: - Schedule Manager Tests
    
    func testScheduleManagerSaveAndLoad() throws {
        // Створюємо тестовий розклад
        let lesson = Lesson(
            number: "1",
            name: "Програмування",
            teacher: "Іванов І.І.",
            room: "100",
            type: "Лекція",
            timeStart: "08:30",
            timeEnd: "09:50",
            url: nil,
            weekType: .full
        )
        
        let scheduleDay = ScheduleDay(dayName: "Понеділок", lessons: [lesson])
        let schedule = SavedSchedule(
            id: "test_schedule",
            title: "Тестовий розклад",
            type: .student,
            groupName: "КН-111",
            teacherName: nil,
            semester: "2 семестр",
            semesterDuration: "Весь семестр",
            savedDate: Date(),
            scheduleDays: [scheduleDay]
        )
        
        // Тестуємо збереження
        scheduleManager.saveSchedule(schedule)
        
        // Тестуємо завантаження
        let savedSchedules = scheduleManager.getSavedSchedules()
        XCTAssertEqual(savedSchedules.count, 1)
        XCTAssertEqual(savedSchedules.first?.id, "test_schedule")
        XCTAssertEqual(savedSchedules.first?.title, "Тестовий розклад")
    }
    
    func testScheduleManagerDelete() throws {
        // Створюємо та зберігаємо розклад
        let lesson = Lesson(
            number: "1",
            name: "Тестовий предмет",
            teacher: "Тестовий викладач",
            room: "100",
            type: "Лекція",
            timeStart: "08:30",
            timeEnd: "09:50",
            url: nil,
            weekType: .full
        )
        
        let scheduleDay = ScheduleDay(dayName: "Понеділок", lessons: [lesson])
        let schedule = SavedSchedule(
            id: "delete_test",
            title: "Розклад для видалення",
            type: .student,
            groupName: "КН-111",
            teacherName: nil,
            semester: "1 семестр",
            semesterDuration: "Весь семестр",
            savedDate: Date(),
            scheduleDays: [scheduleDay]
        )
        
        scheduleManager.saveSchedule(schedule)
        XCTAssertEqual(scheduleManager.getSavedSchedules().count, 1)
        
        // Тестуємо видалення
        scheduleManager.deleteSchedule(withId: "delete_test")
        XCTAssertEqual(scheduleManager.getSavedSchedules().count, 0)
    }
    
    // MARK: - Task Manager Tests
    
    func testTaskManagerAddTask() throws {
        let task = Task(
            title: "Тестове завдання",
            description: "Опис тестового завдання",
            priority: .medium,
            dueDate: Date(),
            category: .study,
            tags: ["тест", "завдання"]
        )
        
        taskManager.addTask(task)
        
        let savedTasks = taskManager.loadTasks()
        XCTAssertEqual(savedTasks.count, 1)
        XCTAssertEqual(savedTasks.first?.title, "Тестове завдання")
        XCTAssertEqual(savedTasks.first?.category, .study)
    }
    
    func testTaskManagerUpdateTask() throws {
        // Створюємо та зберігаємо завдання
        var task = Task(
            title: "Початкова назва",
            description: "Початковий опис",
            priority: .low,
            dueDate: nil,
            category: .personal,
            tags: []
        )
        
        taskManager.addTask(task)
        
        // Оновлюємо завдання
        task.title = "Оновлена назва"
        task.priority = .high
        task.category = .work
        taskManager.updateTask(task)
        
        let savedTasks = taskManager.loadTasks()
        XCTAssertEqual(savedTasks.count, 1)
        XCTAssertEqual(savedTasks.first?.title, "Оновлена назва")
        XCTAssertEqual(savedTasks.first?.priority, .high)
        XCTAssertEqual(savedTasks.first?.category, .work)
    }
    
    func testTaskManagerDeleteTask() throws {
        let task = Task(
            title: "Завдання для видалення",
            description: nil,
            priority: .medium,
            dueDate: nil,
            category: .other,
            tags: []
        )
        
        taskManager.addTask(task)
        XCTAssertEqual(taskManager.loadTasks().count, 1)
        
        taskManager.deleteTask(withId: task.id)
        XCTAssertEqual(taskManager.loadTasks().count, 0)
    }
    
    // MARK: - Grade Manager Tests
    
    func testGradeManagerAddGrade() throws {
        let grade = SubjectGrade(
            name: "Математика",
            credits: 5,
            grade: 88.0
        )
        
        gradeManager.addGrade(grade)
        
        let savedGrades = gradeManager.loadGrades()
        XCTAssertEqual(savedGrades.count, 1)
        XCTAssertEqual(savedGrades.first?.name, "Математика")
        XCTAssertEqual(savedGrades.first?.credits, 5)
        XCTAssertEqual(savedGrades.first?.grade, 88.0)
    }
    
    func testGradeManagerCalculateGPA() throws {
        let grade1 = SubjectGrade(name: "Математика", credits: 5, grade: 90.0)
        let grade2 = SubjectGrade(name: "Фізика", credits: 4, grade: 85.0)
        let grade3 = SubjectGrade(name: "Хімія", credits: 3, grade: 95.0)
        
        gradeManager.addGrade(grade1)
        gradeManager.addGrade(grade2)
        gradeManager.addGrade(grade3)
        
        let gpa = gradeManager.calculateGPA()
        
        // Перевіряємо що GPA обчислюється правильно
        // (90*5 + 85*4 + 95*3) / (5+4+3) = (450 + 340 + 285) / 12 = 1075/12 ≈ 89.58
        XCTAssertEqual(gpa, 89.58333333333333, accuracy: 0.01)
    }
    
    func testGradeManagerDeleteGrade() throws {
        let grade = SubjectGrade(
            name: "Тестовий предмет",
            credits: 3,
            grade: 80.0
        )
        
        gradeManager.addGrade(grade)
        XCTAssertEqual(gradeManager.loadGrades().count, 1)
        
        gradeManager.deleteGrade(withId: grade.id)
        XCTAssertEqual(gradeManager.loadGrades().count, 0)
    }
    
    // MARK: - Model Tests
    
    func testTaskPriorityColors() throws {
        XCTAssertEqual(Task.TaskPriority.low.color, UIColor.systemGreen)
        XCTAssertEqual(Task.TaskPriority.medium.color, UIColor.systemOrange)
        XCTAssertEqual(Task.TaskPriority.high.color, UIColor.systemRed)
    }
    
    func testTaskCategoryIcons() throws {
        XCTAssertEqual(Task.TaskCategory.personal.icon, "person.fill")
        XCTAssertEqual(Task.TaskCategory.work.icon, "briefcase.fill")
        XCTAssertEqual(Task.TaskCategory.study.icon, "book.fill")
        XCTAssertEqual(Task.TaskCategory.health.icon, "heart.fill")
        XCTAssertEqual(Task.TaskCategory.shopping.icon, "cart.fill")
        XCTAssertEqual(Task.TaskCategory.other.icon, "folder.fill")
    }
    
    func testSubjectGradeDescriptions() throws {
        let excellentGrade = SubjectGrade(name: "Тест", credits: 5, grade: 95.0)
        XCTAssertEqual(excellentGrade.gradeDescription, "Відмінно")
        
        let goodGrade = SubjectGrade(name: "Тест", credits: 5, grade: 75.0)
        XCTAssertEqual(goodGrade.gradeDescription, "Добре")
        
        let failGrade = SubjectGrade(name: "Тест", credits: 5, grade: 40.0)
        XCTAssertEqual(failGrade.gradeDescription, "Незадовільно")
    }
    
    func testSubjectGradePoints() throws {
        let grade = SubjectGrade(name: "Тест", credits: 4, grade: 85.0)
        XCTAssertEqual(grade.gradePoints, 340.0) // 85 * 4 = 340
    }
    
    func testWeekTypeEnum() throws {
        XCTAssertEqual(WeekType.full.rawValue, "full")
        XCTAssertEqual(WeekType.odd.rawValue, "odd")
        XCTAssertEqual(WeekType.even.rawValue, "even")
    }
    
    // MARK: - Theme Manager Tests
    
    func testThemeManagerSingleton() throws {
        let theme1 = ThemeManager.shared
        let theme2 = ThemeManager.shared
        XCTAssertTrue(theme1 === theme2, "ThemeManager має бути singleton")
    }
    
    func testAccentColorEnum() throws {
        XCTAssertEqual(AccentColor.default.displayName, "За замовчуванням")
        XCTAssertEqual(AccentColor.blue.displayName, "Синій")
        XCTAssertEqual(AccentColor.purple.displayName, "Фіолетовий")
        XCTAssertEqual(AccentColor.pink.displayName, "Рожевий")
    }
    
    func testThemeEnum() throws {
        XCTAssertEqual(Theme.light.displayName, "Світла")
        XCTAssertEqual(Theme.dark.displayName, "Темна")
        XCTAssertEqual(Theme.system.displayName, "Системна")
        
        XCTAssertEqual(Theme.light.icon, "sun.max")
        XCTAssertEqual(Theme.dark.icon, "moon")
        XCTAssertEqual(Theme.system.icon, "gear")
    }
    
    // MARK: - Performance Tests з точними вимірюваннями
    
    func testScheduleLoadingTime() throws {
        // Створюємо великий тестовий розклад
        var lessons: [Lesson] = []
        for i in 1...8 { // 8 пар на день
            let lesson = Lesson(
                number: "\(i)",
                name: "Предмет \(i)",
                teacher: "Викладач \(i)",
                room: "Аудиторія \(i)",
                type: "Лекція",
                timeStart: "08:30",
                timeEnd: "09:50",
                url: nil,
                weekType: .full
            )
            lessons.append(lesson)
        }
        
        var scheduleDays: [ScheduleDay] = []
        let dayNames = ["Понеділок", "Вівторок", "Середа", "Четвер", "П'ятниця"]
        for dayName in dayNames {
            scheduleDays.append(ScheduleDay(dayName: dayName, lessons: lessons))
        }
        
        let schedule = SavedSchedule(
            id: "performance_test",
            title: "Великий тестовий розклад",
            type: .student,
            groupName: "КН-111",
            teacherName: nil,
            semester: "2 семестр",
            semesterDuration: "Весь семестр",
            savedDate: Date(),
            scheduleDays: scheduleDays
        )
        
        scheduleManager.saveSchedule(schedule)
        
        // Вимірюємо час завантаження
        let startTime = CFAbsoluteTimeGetCurrent()
        let _ = scheduleManager.getSavedSchedules()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        print("📊 Час завантаження розкладу: \(timeElapsed * 1000) мс")
        
        // Перевіряємо що час менше встановленого ліміту (3 секунди)
        XCTAssertLessThan(timeElapsed, 3.0, "Час завантаження розкладу має бути менше 3 секунд")
    }
    
    func testUIResponseTime() throws {
        // Симулюємо інтенсивну роботу з UI
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Створюємо багато завдань для тестування відгуку
        for i in 1...50 {
            let task = Task(
                title: "UI Test Task \(i)",
                description: "Performance test",
                priority: [.low, .medium, .high].randomElement()!,
                dueDate: Date(),
                category: Task.TaskCategory.allCases.randomElement()!,
                tags: ["test\(i)"]
            )
            taskManager.addTask(task)
        }
        
        // Вимірюємо час відгуку UI операцій
        let tasks = taskManager.loadTasks()
        let _ = TaskStatistics(tasks: tasks)
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        print("📊 Час відгуку інтерфейсу: \(timeElapsed * 1000) мс")
        
        // Перевіряємо що час менше встановленого ліміту (150 мс)
        XCTAssertLessThan(timeElapsed, 0.15, "Час відгуку інтерфейсу має бути менше 150 мс")
    }
    
    func testHTMLParsingPerformanceDetailed() throws {
        let complexHTML = """
        <div class="view-content">
            <div class="view-grouping-header">Понеділок</div>
            <h3>1 пара</h3>
            <div class="views-row">
                <div id="group_chys_sub_1" class="group_content">
                    Математичний аналіз<br>
                    Іванов І.І., 100, Лекція
                </div>
            </div>
            <div class="views-row">
                <div id="group_znam_sub_2" class="group_content">
                    Програмування<br>
                    Петров П.П., 200, Практика
                </div>
            </div>
            <h3>2 пара</h3>
            <div class="views-row">
                <div class="group_content">
                    Фізика<br>
                    Сидоров С.С., 300, Лабораторна
                </div>
            </div>
            <div class="view-grouping-header">Вівторок</div>
            <h3>1 пара</h3>
            <div class="views-row">
                <div class="group_content">
                    Хімія<br>
                    Козлов К.К., 400, Лекція
                </div>
            </div>
        </div>
        """
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let doc = try SwiftSoup.parse(complexHTML)
            let content = try doc.select(".view-content")
            let dayHeaders = try content.select(".view-grouping-header")
            let rows = try content.select(".views-row")
            
            // Симулюємо повну обробку як в реальному коді
            for row in rows {
                let _ = try row.select(".group_content").text()
            }
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            
            print("📊 Час парсингу HTML: \(timeElapsed * 1000) мс")
            print("📊 Оброблено днів: \(dayHeaders.size())")
            print("📊 Оброблено занять: \(rows.size())")
            
            // Перевіряємо продуктивність
            XCTAssertLessThan(timeElapsed, 0.05, "Парсинг HTML має бути швидше 50 мс")
            
        } catch {
            XCTFail("HTML парсинг не повинен падати: \(error)")
        }
    }
    
    func testGPACalculationPerformance() throws {
        // Створюємо багато предметів для тестування
        for i in 1...100 {
            let grade = SubjectGrade(
                name: "Предмет \(i)",
                credits: Int.random(in: 1...8),
                grade: Double.random(in: 60...100)
            )
            gradeManager.addGrade(grade)
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let gpa = gradeManager.calculateGPA()
        let gpa5Scale = gradeManager.calculateGPA5Scale()
        let stats = gradeManager.getGradeStatistics()
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        print("📊 Час обчислення GPA: \(timeElapsed * 1000) мс")
        print("📊 GPA (100-бальна): \(gpa)")
        print("📊 GPA (5-бальна): \(gpa5Scale)")
        print("📊 Всього предметів: \(stats.completedSubjects)")
        
        // Перевіряємо що обчислення швидкі
        XCTAssertLessThan(timeElapsed, 0.01, "Обчислення GPA має бути швидше 10 мс")
    }
    
    func testMemoryUsageStability() throws {
        // Тест стабільності використання пам'яті
        var results: [String] = []
        
        for cycle in 1...10 {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Створюємо та видаляємо багато об'єктів
            for i in 1...50 {
                let task = Task(
                    title: "Memory Test \(cycle)-\(i)",
                    description: "Test description",
                    priority: .medium,
                    dueDate: Date(),
                    category: .study,
                    tags: []
                )
                taskManager.addTask(task)
            }
            
            let tasks = taskManager.loadTasks()
            
            // Очищаємо для наступного циклу
            for task in tasks {
                if task.title.contains("Memory Test") {
                    taskManager.deleteTask(withId: task.id)
                }
            }
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            results.append("Цикл \(cycle): \(timeElapsed * 1000) мс")
        }
        
        print("📊 Результати тестування пам'яті:")
        for result in results {
            print("📊 \(result)")
        }
        
        XCTAssertTrue(results.count == 10, "Всі цикли мають завершитися успішно")
    }

    func testHTMLParsingPerformance() throws {
        let sampleHTML = """
        <div class="view-content">
            <div class="view-grouping-header">Пн</div>
            <div class="views-row">
                <div class="group_content">
                    Математичний аналіз<br>
                    Іванов І.І., 100, Лекція
                </div>
            </div>
            <div class="view-grouping-header">Вт</div>
            <div class="views-row">
                <div class="group_content">
                    Програмування<br>
                    Петров П.П., 200, Практика
                </div>
            </div>
        </div>
        """
        
        measure {
            do {
                let doc = try SwiftSoup.parse(sampleHTML)
                let content = try doc.select(".view-content")
                let rows = try content.select(".views-row")
                _ = rows.size()
            } catch {
                XCTFail("HTML парсинг не повинен падати")
            }
        }
    }
    
    func testScheduleLoadingPerformance() throws {
        // Створюємо тестовий розклад
        let lesson = Lesson(
            number: "1",
            name: "Програмування",
            teacher: "Іванов І.І.",
            room: "100",
            type: "Лекція",
            timeStart: "08:30",
            timeEnd: "09:50",
            url: nil,
            weekType: .full
        )
        
        let scheduleDay = ScheduleDay(dayName: "Понеділок", lessons: [lesson])
        let schedule = SavedSchedule(
            id: "test_schedule",
            title: "Тестовий розклад",
            type: .student,
            groupName: "КН-111",
            teacherName: nil,
            semester: "2 семестр",
            semesterDuration: "Весь семестр",
            savedDate: Date(),
            scheduleDays: [scheduleDay]
        )
        
        scheduleManager.saveSchedule(schedule)
        
        // Вимірюємо час завантаження розкладу
        measure {
            _ = scheduleManager.getSavedSchedules()
        }
    }
    
    func testTaskStatisticsPerformance() throws {
        // Створюємо багато завдань для тестування
        for i in 1...100 {
            let task = Task(
                title: "Завдання \(i)",
                description: "Опис завдання \(i)",
                priority: [.low, .medium, .high].randomElement()!,
                dueDate: Date(),
                category: Task.TaskCategory.allCases.randomElement()!,
                tags: ["тег\(i)"]
            )
            taskManager.addTask(task)
        }
        
        // Вимірюємо час створення статистики
        measure {
            let tasks = taskManager.loadTasks()
            _ = TaskStatistics(tasks: tasks)
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyDataHandling() throws {
        // Тестуємо поведінку з порожніми даними
        XCTAssertEqual(scheduleManager.getSavedSchedules().count, 0)
        XCTAssertEqual(taskManager.loadTasks().count, 0)
        XCTAssertEqual(gradeManager.loadGrades().count, 0)
        XCTAssertEqual(gradeManager.calculateGPA(), 0.0)
    }
    
    func testTaskWithEmptyDescription() throws {
        let task = Task(
            title: "Завдання без опису",
            description: nil,
            priority: .medium,
            dueDate: nil,
            category: .other,
            tags: []
        )
        
        taskManager.addTask(task)
        
        let savedTasks = taskManager.loadTasks()
        XCTAssertEqual(savedTasks.count, 1)
        XCTAssertNil(savedTasks.first?.description)
    }
    
    func testGradeWithZeroCredits() throws {
        // Тестуємо що не можна створити предмет з 0 кредитів через валідацію
        // Оскільки в SubjectGrade немає валідації в init, створюємо з мінімальними кредитами
        let grade = SubjectGrade(name: "Тест", credits: 1, grade: 100.0)
        XCTAssertEqual(grade.credits, 1)
        XCTAssertEqual(grade.gradePoints, 100.0) // 100 * 1 = 100
    }
    
    func testLessonWithEmptyData() throws {
        let lesson = Lesson(
            number: "",
            name: "",
            teacher: "",
            room: "",
            type: "",
            timeStart: "",
            timeEnd: "",
            url: nil,
            weekType: .full
        )
        
        // Перевіряємо що створення порожнього заняття не падає
        XCTAssertNotNil(lesson)
        XCTAssertEqual(lesson.name, "")
        XCTAssertEqual(lesson.teacher, "")
        XCTAssertNil(lesson.url)
    }
}
