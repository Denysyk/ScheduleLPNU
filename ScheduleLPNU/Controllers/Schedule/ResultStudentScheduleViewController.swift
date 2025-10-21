import UIKit
import SwiftSoup
import SystemConfiguration

class ResultStudentScheduleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
       
    var groupName: String = ""
    var semester: String = ""
    var semesterDuration: String = ""
          
    var isOfflineMode: Bool = false
    var scheduleDays: [ScheduleDay] = []
    private var activityIndicator: UIActivityIndicatorView!
    
    // Таблиця відповідності днів тижня українською
    private let dayTranslations = [
        "Пн": "Понеділок",
        "Вт": "Вівторок",
        "Ср": "Середа",
        "Чт": "Четвер",
        "Пт": "П'ятниця",
        "Сб": "Субота",
        "Нд": "Неділя"
    ]
       
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Створюємо індикатор завантаження
        setupActivityIndicator()
        
        // Налаштування таблиці
        setupTableView()
            
        // Налаштування навігаційного бару
        setupNavigationBar()
        
        // Налаштування тем
        setupThemeObserver()
        applyTheme()
            
        // Завантаження даних
        loadScheduleData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Проста перевалідація розкладу без затримок і анімацій
        if !scheduleDays.isEmpty {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            tableView.beginUpdates()
            tableView.endUpdates()
            
            CATransaction.commit()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupThemeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: ThemeManager.themeChangedNotification,
            object: nil
        )
    }
    
    @objc private func themeDidChange() {
        applyTheme()
    }
    
    private func applyTheme() {
        let theme = ThemeManager.shared
        
        // Background
        view.backgroundColor = theme.backgroundColor
        
        // Navigation
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: theme.accentColor,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15, weight: .semibold)
        ]
        navigationController?.navigationBar.tintColor = theme.accentColor
        
        // Update title view
        if let titleView = navigationItem.titleView,
           let titleLabel = titleView.subviews.first as? UILabel {
            titleLabel.textColor = theme.accentColor
        }
        
        // Table view
        tableView.backgroundColor = theme.backgroundColor
        
        // Activity indicator
        activityIndicator.color = theme.accentColor
        
        // Refresh control
        if #available(iOS 10.0, *) {
            tableView.refreshControl?.tintColor = theme.accentColor
        }
        
        // Reload table to update cells
        tableView.reloadData()
    }
    
    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        
        // Оптимізація для швидкодії
        tableView.estimatedRowHeight = 0 // Вимкнути оцінку висоти
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        
        // Реєструємо програмну клітинку
        tableView.register(ProgrammaticLessonCell.self, forCellReuseIdentifier: "ProgrammaticLessonCell")
        
        // Додаємо pull-to-refresh
        if #available(iOS 10.0, *) {
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(self, action: #selector(refreshSchedule(_:)), for: .valueChanged)
            tableView.refreshControl = refreshControl
        }
    }
    
    private func setupNavigationBar() {
        let fullTitle = "Розклад \(groupName)"
            
        // Створюємо контейнер для заголовка
        let containerView = UIView()
        
        // Створюємо лейбл
        let titleLabel = UILabel()
        titleLabel.text = fullTitle
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        
        // Додаємо лейбл до контейнера
        containerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Налаштовуємо constraints
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -4),
            titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 200),
            titleLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 50)
        ])
        
        // Встановлюємо розмір контейнера
        let titleSize = titleLabel.sizeThatFits(CGSize(width: 200, height: 50))
        containerView.frame = CGRect(x: 0, y: 0, width: min(200, titleSize.width + 8), height: max(44, titleSize.height))
        
        // Встановлюємо як titleView
        navigationItem.titleView = containerView
        
        // Завжди показуємо обидві кнопки
           let saveButton = UIBarButtonItem(
               image: UIImage(systemName: "square.and.arrow.down"),
               style: .plain,
               target: self,
               action: #selector(saveSchedule)
           )
           
           let refreshButton = UIBarButtonItem(
               barButtonSystemItem: .refresh,
               target: self,
               action: #selector(refreshSchedule(_:))
           )
           refreshButton.isEnabled = isInternetAvailable()
           
           let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
           spacer.width = 4
           
           navigationItem.rightBarButtonItems = [spacer, saveButton, refreshButton]
    }
    
    private func isInternetAvailable() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return isReachable && !needsConnection
    }

    private func loadScheduleData() {
        // Якщо є збережені дані розкладу, відображаємо їх
        if !scheduleDays.isEmpty {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            self.tableView.reloadData()
            
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
            
            CATransaction.commit()
            return
        }
        
        // Перевірка чи поля заповнені
        guard !groupName.isEmpty else {
            showAlert(title: "Помилка", message: "Назва групи не вказана")
            return
        }
        
        // Визначення параметрів семестру
        let semesterValue = semester.contains("1") ? "1" : "2"
        
        // НОВА ЛОГІКА: визначення тривалості семестру
        var semesterDurationValue = "1" // За замовчуванням "Весь семестр та перша половина"
        if semesterDuration.contains("друга") || semesterDuration.contains("Друга") {
            semesterDurationValue = "2" // "Весь семестр та друга половина"
        }
        
        // Формування URL для запиту
        let baseURL = "https://student.lpnu.ua/students_schedule"
        let encodedGroup = groupName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? groupName
        let urlString = "\(baseURL)?studygroup_abbrname=\(encodedGroup)&semestr=\(semesterValue)&semestrduration=\(semesterDurationValue)"
        
        guard let url = URL(string: urlString) else {
            showAlert(title: "Помилка", message: "Невірний URL")
            return
        }
        
        // Показуємо індикатор завантаження
        activityIndicator.startAnimating()
        
        // Виконуємо запит
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            // Виконується в фоновому потоці
            
            DispatchQueue.main.async {
                // Прибираємо індикатор
                self?.activityIndicator.stopAnimating()
                
                if let error = error {
                    self?.showAlert(title: "Помилка мережі", message: error.localizedDescription)
                    return
                }
                
                guard let data = data, let htmlString = String(data: data, encoding: .utf8) else {
                    self?.showAlert(title: "Помилка", message: "Не вдалося отримати дані")
                    return
                }
                
                // Парсимо HTML
                self?.parseScheduleFromHTML(htmlString)
            }
        }.resume()
    }

    @objc private func refreshSchedule(_ sender: Any? = nil) {
        // Перевіряємо наявність інтернету
        if !isInternetAvailable() {
            showAlert(title: "Немає інтернету", message: "Неможливо оновити розклад без інтернет-з'єднання")
            if let refreshControl = sender as? UIRefreshControl {
                refreshControl.endRefreshing()
            }
            return
        }
        
        // Очищаємо дані розкладу перед оновленням
        scheduleDays.removeAll()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        tableView.reloadData()
        CATransaction.commit()
        
        // Завантажуємо дані заново
        loadScheduleData()
        
        // Зупиняємо індикатор оновлення без затримки
        if let refreshControl = sender as? UIRefreshControl {
            refreshControl.endRefreshing()
        }
    }

    @objc private func saveSchedule() {
        guard !scheduleDays.isEmpty else {
            showAlert(title: "Помилка", message: "Немає даних для збереження")
            return
        }
        
        let schedule = SavedSchedule(
            id: "student_\(groupName)_\(semester)_\(semesterDuration)",
            title: "Розклад \(groupName)",
            type: .student,
            groupName: groupName,
            teacherName: nil,
            semester: semester,
            semesterDuration: semesterDuration,
            savedDate: Date(),
            scheduleDays: scheduleDays
        )
        
        ScheduleManager.shared.saveSchedule(schedule)
        showSuccessAlert()
    }

    private func showSuccessAlert() {
        let alert = UIAlertController(title: "Успіх", message: "Розклад збережено", preferredStyle: .alert)
        alert.view.tintColor = ThemeManager.shared.accentColor
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }
    

    // Допоміжна функція для видалення HTML-тегів
    private func removeHTMLTags(from string: String) -> String {
        do {
            // Використовуємо SwiftSoup для надійного видалення HTML-тегів
            let cleanString = try SwiftSoup.clean(string, Whitelist.none())
            return (cleanString?.trimmingCharacters(in: .whitespacesAndNewlines))!
        } catch {
            // У випадку помилки використовуємо регулярний вираз як запасний варіант
            let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: .caseInsensitive)
            let range = NSRange(location: 0, length: string.count)
            let result = regex?.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "") ?? string
            return result.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    

    private func parseScheduleFromHTML(_ html: String) {
        do {
            let doc = try SwiftSoup.parse(html)
            
            guard let viewContent = try? doc.select(".view-content").first() else {
                showAlert(title: "Помилка", message: "Відсутні дані за заданим запитом")
                return
            }
            
            scheduleDays.removeAll()
            
            if let dayHeaders = try? viewContent.select(".view-grouping-header") {
                for dayHeader in dayHeaders {
                    if let dayName = try? dayHeader.text() {
                        var daySchedule = ScheduleDay(dayName: dayName, lessons: [])
                        var currentLessonNumber = ""
                        
                        var nextElement = try? dayHeader.nextElementSibling()
                        
                        while nextElement != nil {
                            // Перевірка на кінець дня
                            if (try? nextElement?.hasClass("view-grouping-header")) == true {
                                break
                            }
                            
                            // Знаходимо номер пари
                            if (try? nextElement?.tagName()) == "h3" {
                                currentLessonNumber = try! nextElement?.text() ?? "0"
                            }
                            
                            // Знаходимо заняття для поточної пари
                            if let lessonRows = try? nextElement?.select(".views-row") {
                                for lessonRow in lessonRows {
                                    // Визначаємо тип тижня та підгрупи
                                    var weekType: WeekType = .full
                                    var subgroupType: String?
                                    var isActiveThisWeek = false

                                    // Шукаємо divElement для визначення типу тижня та підгрупи
                                    if let divElement = try? lessonRow.select("[id^=group_], [id^=sub_]").first() {
                                        let divId = try? divElement.id()
                                        let divClass = try? divElement.className()

                                        if let id = divId {
                                            // Визначаємо тип тижня - ЗАЛИШАЄМО ОРИГІНАЛЬНУ ЛОГІКУ!
                                            if id.contains("chys") {
                                                weekType = .even
                                            } else if id.contains("znam") {
                                                weekType = .odd
                                            }
                                            
                                            // Визначаємо підгрупу
                                            if id.contains("sub_1") {
                                                subgroupType = "підгрупа 1"
                                            } else if id.contains("sub_2") {
                                                subgroupType = "підгрупа 2"
                                            }
                                        }
                                        
                                        // Визначаємо активність через week_color
                                        if let className = divClass, className.contains("week_color") {
                                            isActiveThisWeek = true
                                        }
                                    }
                                    
                                    // Завжди обробляємо всі заняття, незалежно від типу тижня
                                    // Парсимо вміст заняття
                                    if let lessonContent = try? lessonRow.select(".group_content").first() {
                                        // ВАЖЛИВО: Зберігаємо весь HTML-вміст для обробки
                                        let lessonHtml = try? lessonContent.html() ?? ""
                                        
                                        // Обробляємо HTML для виділення тексту
                                        let lessonText = lessonHtml?.replacingOccurrences(of: "<br>", with: "\n")
                                                                 .replacingOccurrences(of: "<br />", with: "\n") ?? ""
                                        let lines = lessonText.components(separatedBy: "\n")
                                                             .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                                             .filter { !$0.isEmpty }
                                        
                                        var lessonName = ""
                                        var teacher = ""
                                        var room = ""
                                        var type = ""
                                        var url: String? = nil
                                        
                                        if lines.count > 0 {
                                            lessonName = removeHTMLTags(from: lines[0])
                                        }
                                        
                                        if lines.count > 1 {
                                            let details = lines[1]
                                            let components = details.components(separatedBy: ", ")
                                            
                                            if components.count > 0 {
                                                teacher = removeHTMLTags(from: components[0])
                                                // Додаємо інформацію про підгрупу до імені викладача, якщо вона є
                                                if let subgroup = subgroupType {
                                                    teacher += ", \(subgroup)"
                                                }
                                            }
                                            
                                            if components.count > 1 {
                                                room = removeHTMLTags(from: components[1])
                                            }
                                            
                                            if components.count > 2 {
                                                type = removeHTMLTags(from: components[2])
                                            }
                                        }
                                        
                                        // Перевіряємо наявність URL для онлайн-заняття
                                        if let link = try? lessonContent.select("a[href]").first() {
                                            let href = try? link.attr("href")
                                            if let linkHref = href, !linkHref.isEmpty {
                                                url = linkHref
                                            }
                                        }
                                        
                                        // Переконуємося, що всі поля мають значення
                                        if lessonName.isEmpty { lessonName = "Невідомо" }
                                        if teacher.isEmpty { teacher = "Викладач не вказаний" }
                                        if room.isEmpty { room = "Аудиторія не вказана" }
                                        if type.isEmpty { type = "" }
                                        
                                        // Створюємо об'єкт заняття
                                        let lesson = Lesson(
                                            number: currentLessonNumber,
                                            name: lessonName,
                                            teacher: teacher,
                                            room: room,
                                            type: type,
                                            timeStart: getTimeStart(for: currentLessonNumber),
                                            timeEnd: getTimeEnd(for: currentLessonNumber),
                                            url: url,
                                            weekType: weekType,
                                            isActiveThisWeek: isActiveThisWeek
                                        )
                                        
                                        // Додаємо заняття - незалежно від типу тижня
                                        daySchedule.lessons.append(lesson)
                                    }
                                }
                            }
                            
                            nextElement = try? nextElement?.nextElementSibling()
                        }
                        
                        // Додаємо день з усіма заняттями, відсортованими за номером пари
                        let sortedLessons = daySchedule.lessons.sorted {
                            (Int($0.number) ?? 0) < (Int($1.number) ?? 0)
                        }
                        
                        scheduleDays.append(ScheduleDay(dayName: dayName, lessons: sortedLessons))
                    }
                }
                
                if scheduleDays.isEmpty {
                    showAlert(title: "Інформація", message: "Розклад не знайдено для групи \(groupName)")
                } else {
                    // Прибираємо всі анімації
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    
                    // Оновлюємо таблицю без анімацій
                    self.tableView.reloadData()
                    
                    // Виконуємо одне оновлення розміру клітинок без анімації
                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                    
                    CATransaction.commit()
                }
            }
        } catch {
            showAlert(title: "Помилка парсингу", message: error.localizedDescription)
        }
    }


    

    private func groupLessonsByNumber(_ lessons: [Lesson]) -> [[Lesson]] {
        // Словник для групування занять за номером пари
        var lessonGroups: [String: [Lesson]] = [:]
        
        // Групуємо заняття за номером пари
        for lesson in lessons {
            if lessonGroups[lesson.number] == nil {
                lessonGroups[lesson.number] = []
            }
            lessonGroups[lesson.number]?.append(lesson)
        }
        
        // Сортування та підготовка результату
        var resultGroups: [[Lesson]] = []
        
        // Впорядкуємо номери пар
        let sortedLessonNumbers = lessonGroups.keys.sorted {
            (Int($0) ?? 0) < (Int($1) ?? 0)
        }
        
        for number in sortedLessonNumbers {
            if let groupLessons = lessonGroups[number] {
                resultGroups.append(groupLessons)
            }
        }
        
        return resultGroups
    }
          
    // Функція для відображення сповіщень про помилки
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.tintColor = ThemeManager.shared.accentColor
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }

    // Допоміжні функції для визначення часу початку та кінця пари
    private func getTimeStart(for lessonNumber: String) -> String {
        switch lessonNumber {
        case "1": return "08:30"
        case "2": return "10:05"
        case "3": return "11:40"
        case "4": return "13:15"
        case "5": return "14:50"
        case "6": return "16:25"
        case "7": return "18:00"
        case "8": return "19:35"
        default: return ""
        }
    }

    private func getTimeEnd(for lessonNumber: String) -> String {
        switch lessonNumber {
        case "1": return "09:50"
        case "2": return "11:25"
        case "3": return "13:00"
        case "4": return "14:35"
        case "5": return "16:10"
        case "6": return "17:45"
        case "7": return "19:20"
        case "8": return "20:55"
        default: return ""
        }
    }
         
    // MARK: - UITableViewDataSource та UITableViewDelegate
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let theme = ThemeManager.shared
        let headerView = UIView()
        headerView.backgroundColor = theme.backgroundColor
        
        // Створюємо верхню лінію-роздільник
        let topLine = UIView()
        topLine.backgroundColor = theme.accentColor.withAlphaComponent(0.1)
        topLine.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(topLine)
        
        // Створюємо мітку для назви дня
        let dayLabel = UILabel()
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        dayLabel.font = .systemFont(ofSize: 17, weight: .medium)
        dayLabel.textColor = theme.accentColor
        
        // Конвертуємо скорочену назву дня у повну, якщо можливо
        let shortDayName = scheduleDays[section].dayName
        dayLabel.text = dayTranslations[shortDayName] ?? shortDayName
        
        headerView.addSubview(dayLabel)
        
        NSLayoutConstraint.activate([
            // Лінія зверху
            topLine.topAnchor.constraint(equalTo: headerView.topAnchor),
            topLine.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            topLine.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            topLine.heightAnchor.constraint(equalToConstant: 1),
            
            // День тижня
            dayLabel.topAnchor.constraint(equalTo: topLine.bottomAnchor, constant: 8),
            dayLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            dayLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])
        
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let groupedLessons = groupLessonsByNumber(scheduleDays[indexPath.section].lessons)
          
        if groupedLessons.count > indexPath.row {
            let lessonGroup = groupedLessons[indexPath.row]
            
            // Базова висота для картки з заняттям
            var baseHeight: CGFloat = 180 // Базова висота клітинки
            
            // Якщо є URL, додаємо висоту для кнопки
            let hasURL = lessonGroup.contains {
                guard let url = $0.url else { return false }
                return !url.isEmpty
            }
            
            if hasURL {
                baseHeight += 80
            }
            
            // Перевіряємо чи маємо парний/непарний тижні або підгрупи
            let evenWeekLessons = lessonGroup.filter { $0.weekType == .even }
            let oddWeekLessons = lessonGroup.filter { $0.weekType == .odd }
            let hasAlternatingWeeks = (!evenWeekLessons.isEmpty || !oddWeekLessons.isEmpty)
            
            let subgroup1Lessons = lessonGroup.filter { $0.teacher.contains("підгрупа 1") }
            let subgroup2Lessons = lessonGroup.filter { $0.teacher.contains("підгрупа 2") }
            let hasSubgroups = (!subgroup1Lessons.isEmpty || !subgroup2Lessons.isEmpty)
            
            // Якщо маємо одночасно і підгрупи, і тижні - додатково збільшуємо висоту
            if hasAlternatingWeeks && hasSubgroups {
                baseHeight += 150  // Збільшуємо з 100 до 150
            } else if hasSubgroups {
                baseHeight += 50  // Збільшуємо з 50 до 100 для блоків з підгрупами
            } else if hasAlternatingWeeks {
                baseHeight += 150
            }
              
            return baseHeight
        }
          
        return 180 // Стандартна висота
    }
          
    // Кількість секцій = кількість днів
    func numberOfSections(in tableView: UITableView) -> Int {
        return scheduleDays.count
    }
          
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let groupedLessons = groupLessonsByNumber(scheduleDays[section].lessons)
        return groupedLessons.count
    }
          
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Отримуємо дані для клітинки
        let groupedLessons = groupLessonsByNumber(scheduleDays[indexPath.section].lessons)
        guard groupedLessons.count > indexPath.row else {
            return UITableViewCell() // повертаємо порожню клітинку, якщо даних немає
        }
        
        // Отримуємо уроки для цього ряду
        let lessonGroup = groupedLessons[indexPath.row]
        
        // Створюємо програмну клітинку
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProgrammaticLessonCell", for: indexPath) as! ProgrammaticLessonCell
        cell.configureWithLessons(lessons: lessonGroup)
               return cell
           }
           
           func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
               // Легка анімація натискання на клітинку для зворотного зв'язку
               if let cell = tableView.cellForRow(at: indexPath) {
                   UIView.animate(withDuration: 0.1, animations: {
                       cell.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
                       cell.alpha = 0.8
                   }) { _ in
                       UIView.animate(withDuration: 0.1) {
                           cell.transform = CGAffineTransform.identity
                           cell.alpha = 1.0
                       }
                   }
               }
           }
        }
