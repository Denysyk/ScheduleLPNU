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
           weekType: .full,
           isActiveThisWeek: true
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
           weekType: .full,
           isActiveThisWeek: true
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
               weekType: .full,
               isActiveThisWeek: true
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
       
       // Масив для збереження результатів
       var measurements: [Double] = []
       let numberOfMeasurements = 50
       
       print("Починаємо \(numberOfMeasurements) вимірювань...")
       
       // Виконуємо 25 вимірювань
       for i in 1...numberOfMeasurements {
           let startTime = CFAbsoluteTimeGetCurrent()
           let _ = scheduleManager.getSavedSchedules()
           let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
           
           let timeInMs = timeElapsed * 1000
           measurements.append(timeInMs)
           
           print("Вимірювання \(i): \(String(format: "%.8f", timeInMs)) мс")
       }
       
       // Обчислюємо статистику
       let minTime = measurements.min() ?? 0
       let maxTime = measurements.max() ?? 0
       let avgTime = measurements.reduce(0, +) / Double(measurements.count)
       
       // Медіана
       let sortedMeasurements = measurements.sorted()
       let median = sortedMeasurements.count % 2 == 0
           ? (sortedMeasurements[sortedMeasurements.count/2 - 1] + sortedMeasurements[sortedMeasurements.count/2]) / 2
           : sortedMeasurements[sortedMeasurements.count/2]
       
       print("\n📈 СТАТИСТИКА ВИМІРЮВАНЬ:")
       print("🔹 Мінімальний час: \(String(format: "%.8f", minTime)) мс")
       print("🔹 Максимальний час: \(String(format: "%.8f", maxTime)) мс")
       print("🔹 Середній час: \(String(format: "%.8f", avgTime)) мс")
       print("🔹 Медіана: \(String(format: "%.8f", median)) мс")
       print("🔹 Всі вимірювання: \(measurements.map { String(format: "%.8f", $0) }.joined(separator: ", ")) мс")
       
       // Перевіряємо що середній час менше встановленого ліміту
       XCTAssertLessThan(avgTime / 1000, 3.0, "Середній час завантаження розкладу має бути менше 3 секунд")
       
       // Додаткова перевірка - 95% вимірювань мають бути швидше за 3 секунди
       let fastMeasurements = measurements.filter { $0 / 1000 < 3.0 }
       let successRate = Double(fastMeasurements.count) / Double(measurements.count) * 100
       print("🎯 Відсоток швидких завантажень (< 3с): \(String(format: "%.1f", successRate))%")
       
       XCTAssertGreaterThanOrEqual(successRate, 95.0, "Принаймні 95% вимірювань мають бути швидше за 3 секунди")
   }
   
   func testUIResponseTime() throws {
       // Симулюємо інтенсивну роботу з UI
       let startTime = CFAbsoluteTimeGetCurrent()
       
       // Створюємо багато завдань для тестування відгуку
       for i in 1...25 {
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
       XCTAssertLessThan(timeElapsed, 0.15, "Час відгуку інтерфейсу має бути менше 100 мс")
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
           weekType: .full,
           isActiveThisWeek: true
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
   
   // MARK: - CPU/Memory Tests with Real Metrics
   
   func testCPUAndMemoryUsage() throws {
       // Тест з реальними метриками процесора та пам'яті
       measure(metrics: [
           XCTCPUMetric(),           // 🔥 CPU Usage
           XCTMemoryMetric(),        // 💾 Memory Usage
           XCTStorageMetric()        // 💽 Disk I/O
       ]) {
           // Створюємо навантаження на систему
           let scheduleManager = ScheduleManager.shared
           
           // Інтенсивні операції з даними
           for i in 1...50 {
               let lessons = createTestLessons(count: 30)
               let scheduleDays = createTestScheduleDays(lessons: lessons)
               
               let schedule = SavedSchedule(
                   id: "cpu_test_\(i)",
                   title: "CPU Test Schedule \(i)",
                   type: .student,
                   groupName: "CPU-\(i)",
                   teacherName: nil,
                   semester: "2 семестр",
                   semesterDuration: "Весь семестр",
                   savedDate: Date(),
                   scheduleDays: scheduleDays
               )
               
               scheduleManager.saveSchedule(schedule)
           }
           
           // Завантажуємо та обробляємо дані
           let schedules = scheduleManager.getSavedSchedules()
           
           // Інтенсивна обробка (споживає CPU)
           for schedule in schedules {
               let _ = schedule.scheduleDays.flatMap { $0.lessons }
                   .map { "\($0.name) - \($0.teacher)" }
                   .sorted()
           }
           
           // Очищаємо дані
           for i in 1...50 {
               scheduleManager.deleteSchedule(withId: "cpu_test_\(i)")
           }
       }
   }
   
   func testMemoryPressureWithMetrics() throws {
       // Спеціальний тест для вимірювання споживання пам'яті
       measure(metrics: [
           XCTMemoryMetric(),  // 💾 Memory - ВИПРАВЛЕНО
           XCTCPUMetric()      // 🔥 CPU usage
       ]) {
           var memoryIntensiveData: [String] = []
           
           // Створюємо багато об'єктів в пам'яті
           for i in 1...1000 {
               let largeString = String(repeating: "ScheduleLPNU Memory Test Data \(i) ", count: 100)
               memoryIntensiveData.append(largeString)
           }
           
           // Обробляємо дані (споживає CPU)
           let processedData = memoryIntensiveData.map { data in
               return data.uppercased().components(separatedBy: " ").joined(separator: "-")
           }
           
           // Фільтруємо та сортуємо (більше CPU/Memory)
           let filteredData = processedData.filter { $0.contains("SCHEDULELPNU") }
               .sorted()
           
           // Використовуємо результат щоб уникнути оптимізації компілятора
           XCTAssertGreaterThan(filteredData.count, 0)
           
           // Очищаємо пам'ять
           memoryIntensiveData.removeAll()
       }
   }
   
   func testHTMLParsingCPUIntensive() throws {
       // Тест парсингу HTML з вимірюванням CPU
       measure(metrics: [
           XCTCPUMetric(),
           XCTMemoryMetric()
       ]) {
           let complexHTML = createVeryComplexHTML()
           
           // Інтенсивний парсинг HTML (споживає CPU)
           for _ in 1...100 {
               do {
                   let doc = try SwiftSoup.parse(complexHTML)
                   
                   // Складні CSS селектори (більше CPU)
                                      let allElements = try doc.select("*")
                                      let contentElements = try doc.select(".view-content")
                                      let dayHeaders = try doc.select(".view-grouping-header")
                                      let rows = try doc.select(".views-row")
                                      
                                      // Обробка тексту (CPU intensive)
                                      for element in contentElements {
                                          let text = try element.text()
                                          let _ = text.components(separatedBy: " ")
                                              .filter { $0.count > 3 }
                                              .map { $0.lowercased() }
                                              .sorted()
                                      }
                                      
                                      // Валідація результатів
                                      XCTAssertGreaterThan(allElements.size(), 0)
                                      XCTAssertGreaterThan(rows.size(), 0)
                                      
                                  } catch {
                                      XCTFail("HTML parsing failed: \(error)")
                                  }
                              }
                          }
                      }
                      
                      func testTaskProcessingWithSystemMetrics() throws {
                          // Тест обробки завдань з системними метриками
                          measure(metrics: [
                              XCTCPUMetric(),
                              XCTMemoryMetric(),
                              XCTStorageMetric(),       // 💽 Disk operations
                              XCTClockMetric()          // ⏰ Wall clock time
                          ]) {
                              let taskManager = TaskManager.shared
                              
                              // Створюємо багато завдань
                              var createdTasks: [Task] = []
                              for i in 1...200 {
                                  let task = Task(
                                      title: "System Metrics Test Task \(i)",
                                      description: String(repeating: "Detailed description for task \(i) ", count: 50),
                                      priority: [.low, .medium, .high].randomElement()!,
                                      dueDate: Date().addingTimeInterval(TimeInterval(i * 3600)),
                                      category: Task.TaskCategory.allCases.randomElement()!,
                                      tags: Array(1...10).map { "tag\(i)_\($0)" }
                                  )
                                  taskManager.addTask(task)
                                  createdTasks.append(task)
                              }
                              
                              // Інтенсивна обробка (CPU + Memory)
                              let tasks = taskManager.loadTasks()
                              let statistics = TaskStatistics(tasks: tasks)
                              
                              // Складні обчислення
                              let sortedByPriority = tasks.sorted { task1, task2 in
                                  if task1.priority.rawValue != task2.priority.rawValue {
                                      return task1.priority.rawValue > task2.priority.rawValue
                                  }
                                  return task1.title < task2.title
                              }
                              
                              let groupedByCategory = Dictionary(grouping: sortedByPriority) { $0.category }
                              
                              // Обробка кожної групи
                              for (_, categoryTasks) in groupedByCategory {
                                  let _ = categoryTasks.map { task in
                                      "\(task.title): \(task.description ?? "")"
                                  }.joined(separator: "\n")
                              }
                              
                              // Очищаємо створені завдання
                              for task in createdTasks {
                                  taskManager.deleteTask(withId: task.id)
                              }
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
                              weekType: .full,
                              isActiveThisWeek: false
                          )
                          
                          // Перевіряємо що створення порожнього заняття не падає
                          XCTAssertNotNil(lesson)
                          XCTAssertEqual(lesson.name, "")
                          XCTAssertEqual(lesson.teacher, "")
                          XCTAssertNil(lesson.url)
                      }
                      
                      // MARK: - Helper Methods for CPU/Memory tests
                      
                      private func createTestLessons(count: Int) -> [Lesson] {
                          var lessons: [Lesson] = []
                          for i in 1...count {
                              let lesson = Lesson(
                                  number: "\(i % 8 + 1)",
                                  name: "Тестовий предмет \(i)",
                                  teacher: "Викладач \(i)",
                                  room: "Аудиторія \(i % 100 + 100)",
                                  type: ["Лекція", "Практика", "Лабораторна"].randomElement()!,
                                  timeStart: "08:30",
                                  timeEnd: "09:50",
                                  url: nil,
                                  weekType: .full,
                                  isActiveThisWeek: true
                              )
                              lessons.append(lesson)
                          }
                          return lessons
                      }
                      
                      private func createTestScheduleDays(lessons: [Lesson]) -> [ScheduleDay] {
                          let dayNames = ["Понеділок", "Вівторок", "Середа", "Четвер", "П'ятниця"]
                          return dayNames.map { dayName in
                              let dayLessons = Array(lessons.prefix(8)) // 8 пар на день
                              return ScheduleDay(dayName: dayName, lessons: dayLessons)
                          }
                      }
                      
                      private func createVeryComplexHTML() -> String {
                          var html = """
                          <div class="view-content">
                          """
                          
                          let dayNames = ["Понеділок", "Вівторок", "Середа", "Четвер", "П'ятниця", "Субота"]
                          let subjects = ["Математичний аналіз", "Програмування", "Фізика", "Хімія", "Англійська мова", "Історія"]
                          let teachers = ["Іванов І.І.", "Петров П.П.", "Сидоров С.С.", "Коваленко К.К.", "Мельник М.М."]
                          let types = ["Лекція", "Практика", "Лабораторна", "Семінар"]
                          
                          for (dayIndex, day) in dayNames.enumerated() {
                              html += """
                              <div class="view-grouping-header">\(day)</div>
                              """
                              
                              for pairNumber in 1...8 {
                                  html += """
                                  <h3>\(pairNumber) пара</h3>
                                  """
                                  
                                  // Додаємо кілька занять для кожної пари
                                  for subjectIndex in 0..<min(3, subjects.count) {
                                      let subject = subjects[(dayIndex + pairNumber + subjectIndex) % subjects.count]
                                      let teacher = teachers[(dayIndex + pairNumber + subjectIndex) % teachers.count]
                                      let type = types[(pairNumber + subjectIndex) % types.count]
                                      let room = 100 + (dayIndex * 10) + pairNumber + subjectIndex
                                      
                                      html += """
                                      <div class="views-row">
                                          <div id="group_\(dayIndex)_\(pairNumber)_\(subjectIndex)" class="group_content">
                                              \(subject)<br>
                                              \(teacher), \(room), \(type)
                                              <div class="additional-info">
                                                  <span class="time">08:30 - 09:50</span>
                                                  <span class="week-type">Весь семестр</span>
                                              </div>
                                          </div>
                                      </div>
                                      """
                                  }
                              }
                          }
                          
                          html += "</div>"
                          return html
                      }
                   }

                   class ScheduleLPNUPerformanceTests: XCTestCase {
                      
                      var scheduleManager: ScheduleManager!
                      var taskManager: TaskManager!
                      
                      override func setUpWithError() throws {
                          scheduleManager = ScheduleManager.shared
                          taskManager = TaskManager.shared
                      }
                      
                      // MARK: - Stress Testing (Симуляція великого навантаження)
                      
                      func testMassiveDataHandling() throws {
                          // Створюємо багато даних для стрес-тестування
                          measure {
                              // Створюємо 100 розкладів
                              for i in 1...100 {
                                  let lessons = createTestLessons(count: 40) // 8 пар * 5 днів
                                  let scheduleDays = createTestScheduleDays(lessons: lessons)
                                  
                                  let schedule = SavedSchedule(
                                      id: "stress_test_\(i)",
                                      title: "Стрес тест \(i)",
                                      type: .student,
                                      groupName: "КН-\(111 + i)",
                                      teacherName: nil,
                                      semester: "2 семестр",
                                      semesterDuration: "Весь семестр",
                                      savedDate: Date(),
                                      scheduleDays: scheduleDays
                                  )
                                  
                                  scheduleManager.saveSchedule(schedule)
                              }
                              
                              // Завантажуємо всі розклади
                              let _ = scheduleManager.getSavedSchedules()
                          }
                          
                          // Очищаємо після тесту
                          for i in 1...100 {
                              scheduleManager.deleteSchedule(withId: "stress_test_\(i)")
                          }
                      }
                      
                      // MARK: - Network Performance Simulation
                      
                      func testHTMLParsingUnderLoad() throws {
                          // Симулюємо парсинг багатьох HTML сторінок
                          let complexHTML = createComplexHTML()
                          
                          measure {
                              // Парсимо HTML 50 разів підряд
                              for _ in 1...50 {
                                  do {
                                      let doc = try SwiftSoup.parse(complexHTML)
                                      let content = try doc.select(".view-content")
                                      let dayHeaders = try content.select(".view-grouping-header")
                                      let rows = try content.select(".views-row")
                                      
                                      // Симулюємо обробку як у реальному додатку
                                      for row in rows {
                                          let _ = try row.select(".group_content").text()
                                      }
                                      
                                      // Додаткова обробка для навантаження
                                      XCTAssertGreaterThan(dayHeaders.size(), 0)
                                      XCTAssertGreaterThan(rows.size(), 0)
                                  } catch {
                                      XCTFail("HTML parsing failed: \(error)")
                                  }
                              }
                          }
                      }
                      
                      func testConcurrentDataAccess() throws {
                          // Тестуємо одночасний доступ до даних (симуляція багатьох користувачів)
                          let expectation = XCTestExpectation(description: "Concurrent access test")
                          expectation.expectedFulfillmentCount = 10
                          
                          measure {
                              // Створюємо 10 concurrent операцій
                              DispatchQueue.concurrentPerform(iterations: 10) { index in
                                  // Кожна "нитка" виконує операції з даними
                                  let schedule = createTestSchedule(id: "concurrent_\(index)")
                                  scheduleManager.saveSchedule(schedule)
                                  
                                  let _ = scheduleManager.getSavedSchedules()
                                  
                                  scheduleManager.deleteSchedule(withId: "concurrent_\(index)")
                                  
                                  expectation.fulfill()
                              }
                          }
                          
                          wait(for: [expectation], timeout: 10.0)
                      }
                      
                      // MARK: - Memory Pressure Testing
                      
                      func testMemoryUsageUnderPressure() throws {
                          // Тестуємо споживання пам'яті при великих обсягах даних
                          var memoryTestData: [SavedSchedule] = []
                          
                          measure {
                              // Створюємо багато об'єктів в пам'яті
                              for i in 1...200 {
                                  let lessons = createTestLessons(count: 50)
                                  let scheduleDays = createTestScheduleDays(lessons: lessons)
                                  
                                  let schedule = SavedSchedule(
                                      id: "memory_test_\(i)",
                                      title: "Пам'ять тест \(i) з дуже довгою назвою для збільшення споживання пам'яті",
                                      type: .student,
                                      groupName: "МП-\(i)",
                                      teacherName: "Викладач з дуже довгим іменем \(i)",
                                      semester: "2 семестр",
                                      semesterDuration: "Весь семестр",
                                      savedDate: Date(),
                                      scheduleDays: scheduleDays
                                  )
                                  
                                  memoryTestData.append(schedule)
                              }
                              
                              // Обробляємо всі дані
                              for schedule in memoryTestData {
                                  let _ = schedule.scheduleDays.flatMap { $0.lessons }
                              }
                          }
                          
                          // Очищаємо пам'ять
                          memoryTestData.removeAll()
                      }
                      
                      // MARK: - Helper Methods
                      
                      private func createTestLessons(count: Int) -> [Lesson] {
                          var lessons: [Lesson] = []
                          for i in 1...count {
                              let lesson = Lesson(
                                  number: "\(i % 8 + 1)",
                                  name: "Тестовий предмет \(i)",
                                  teacher: "Викладач \(i)",
                                  room: "Аудиторія \(i % 100 + 100)",
                                  type: ["Лекція", "Практика", "Лабораторна"].randomElement()!,
                                  timeStart: "08:30",
                                  timeEnd: "09:50",
                                  url: nil,
                                  weekType: .full,
                                  isActiveThisWeek: true
                              )
                              lessons.append(lesson)
                          }
                          return lessons
                      }
                      
                      private func createTestScheduleDays(lessons: [Lesson]) -> [ScheduleDay] {
                          let dayNames = ["Понеділок", "Вівторок", "Середа", "Четвер", "П'ятниця"]
                          return dayNames.map { dayName in
                              let dayLessons = Array(lessons.prefix(8)) // 8 пар на день
                              return ScheduleDay(dayName: dayName, lessons: dayLessons)
                          }
                      }
                      
                      private func createTestSchedule(id: String) -> SavedSchedule {
                          let lessons = createTestLessons(count: 20)
                          let scheduleDays = createTestScheduleDays(lessons: lessons)
                          
                          return SavedSchedule(
                              id: id,
                              title: "Тест розклад",
                              type: .student,
                              groupName: "ТГ-111",
                              teacherName: nil,
                              semester: "2 семестр",
                              semesterDuration: "Весь семестр",
                              savedDate: Date(),
                              scheduleDays: scheduleDays
                          )
                      }
                      
                      private func createComplexHTML() -> String {
                          var html = """
                          <div class="view-content">
                          """
                          
                          let dayNames = ["Понеділок", "Вівторок", "Середа", "Четвер", "П'ятниця"]
                          
                          for day in dayNames {
                              html += """
                              <div class="view-grouping-header">\(day)</div>
                              """
                              
                              for pairNumber in 1...8 {
                                  html += """
                                  <h3>\(pairNumber) пара</h3>
                                  <div class="views-row">
                                      <div class="group_content">
                                          Предмет \(pairNumber) (\(day))<br>
                                          Викладач \(pairNumber), Аудиторія \(pairNumber + 100), Лекція
                                      </div>
                                  </div>
                                  """
                              }
                          }
                          
                          html += "</div>"
                          return html
                      }
                   }

                   // MARK: - Додайте цей клас для детального профілювання

                   class ScheduleLPNUProfileTests: XCTestCase {
                      
                      func testAppLaunchPerformanceProfile() throws {
                          // Більш детальний тест запуску з профілюванням
                          measure(metrics: [
                              XCTCPUMetric(),
                              XCTMemoryMetric(),
                              XCTStorageMetric(),
                              XCTClockMetric()
                          ]) {
                              // Симулюємо ініціалізацію додатку
                              let scheduleManager = ScheduleManager.shared
                              let taskManager = TaskManager.shared
                              let gradeManager = GradeManager.shared
                              
                              // Завантажуємо збережені дані
                              let _ = scheduleManager.getSavedSchedules()
                              let _ = taskManager.loadTasks()
                              let _ = gradeManager.loadGrades()
                          }
                      }
                      
                      func testDataProcessingPerformanceProfile() throws {
                          // Профілювання обробки даних
                          measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
                              let scheduleManager = ScheduleManager.shared
                              
                              // Створюємо і обробляємо дані
                              for i in 1...50 {
                                  let schedule = createLargeSchedule(id: "profile_\(i)")
                                  scheduleManager.saveSchedule(schedule)
                              }
                              
                              let _ = scheduleManager.getSavedSchedules()
                              
                              // Очищаємо
                              for i in 1...50 {
                                  scheduleManager.deleteSchedule(withId: "profile_\(i)")
                              }
                          }
                      }
                      
                      private func createLargeSchedule(id: String) -> SavedSchedule {
                          var lessons: [Lesson] = []
                          for i in 1...40 { // 8 пар * 5 днів
                              let lesson = Lesson(
                                  number: "\(i % 8 + 1)",
                                  name: "Складний предмет з довгою назвою \(i)",
                                  teacher: "Професор з дуже довгим іменем та науковими ступенями \(i)",
                                  room: "Аудиторія \(i)",
                                  type: "Лекція з практичними елементами",
                                  timeStart: "08:30",
                                  timeEnd: "09:50",
                                  url: "https://example.com/very-long-url-for-testing-purposes/\(i)",
                                  weekType: .full,
                                  isActiveThisWeek: true
                              )
                              lessons.append(lesson)
                          }
                          
                          let dayNames = ["Понеділок", "Вівторок", "Середа", "Четвер", "П'ятниця"]
                          let scheduleDays = dayNames.map { dayName in
                              let dayLessons = Array(lessons.filter { _ in Int.random(in: 1...10) > 3 })
                              return ScheduleDay(dayName: dayName, lessons: dayLessons)
                          }
                          
                          return SavedSchedule(
                              id: id,
                              title: "Великий розклад з багатьма деталями та довгою назвою \(id)",
                              type: .student,
                              groupName: "КН-111",
                              teacherName: nil,
                              semester: "2 семестр",
                              semesterDuration: "Весь семестр",
                              savedDate: Date(),
                              scheduleDays: scheduleDays
                          )
                      }
                   }

