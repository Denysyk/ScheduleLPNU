import UIKit
import SwiftSoup
import SystemConfiguration

class ResultTeacherScheduleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var isOfflineMode: Bool = false
    var teacherName: String = ""
    var semester: String = ""
    var semesterDuration: String = ""
       
    // Тепер використовуємо загальні структури з ScheduleModels.swift
       
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
        
        setupActivityIndicator()
        setupTableView()
        setupNavigationBar()
        
        // Налаштування тем
        setupThemeObserver()
        applyTheme()
        
        loadScheduleData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
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
        
        // Navigation bar background
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = theme.backgroundColor
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationController?.navigationBar.barTintColor = theme.backgroundColor
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
        
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        
        // Реєструємо ту саму клітинку
        tableView.register(ProgrammaticLessonCell.self, forCellReuseIdentifier: "ProgrammaticLessonCell")
        
        if #available(iOS 10.0, *) {
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(self, action: #selector(refreshSchedule(_:)), for: .valueChanged)
            tableView.refreshControl = refreshControl
        }
    }
    
    private func setupNavigationBar() {
        let fullTitle = "\(teacherName)"
            
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
        // Якщо офлайн режим, не завантажуємо дані з мережі
        if isOfflineMode {
            if scheduleDays.isEmpty {
                showAlert(title: "Інформація", message: "Збережений розклад порожній")
            } else {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                
                self.tableView.reloadData()
                
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
                
                CATransaction.commit()
            }
            return
        }
        
        guard !teacherName.isEmpty else {
            showAlert(title: "Помилка", message: "Ім'я викладача не вказане")
            return
        }
        
        let semesterValue = semester.contains("1") ? "1" : "2"
        
        var semesterDurationValue = "1"
        if semesterDuration.contains("Перша") {
            semesterDurationValue = "2"
        } else if semesterDuration.contains("Друга") {
            semesterDurationValue = "3"
        }
        
        let baseURL = "https://staff.lpnu.ua/lecturer_schedule"
        let encodedTeacher = teacherName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? teacherName
        let urlString = "\(baseURL)?teachername=\(encodedTeacher)&semestr=\(semesterValue)&semestrduration=\(semesterDurationValue)"
        
        guard let url = URL(string: urlString) else {
            showAlert(title: "Помилка", message: "Невірний URL")
            return
        }
        
        activityIndicator.startAnimating()
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                
                if let error = error {
                    self?.showAlert(title: "Помилка мережі", message: error.localizedDescription)
                    return
                }
                
                guard let data = data, let htmlString = String(data: data, encoding: .utf8) else {
                    self?.showAlert(title: "Помилка", message: "Не вдалося отримати дані")
                    return
                }
                
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
        
        scheduleDays.removeAll()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        tableView.reloadData()
        CATransaction.commit()
        
        loadScheduleData()
        
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
            id: "teacher_\(teacherName)_\(semester)_\(semesterDuration)",
            title: "Розклад \(teacherName)",
            type: .teacher,
            groupName: nil,
            teacherName: teacherName,
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

    private func removeHTMLTags(from string: String) -> String {
        do {
            let cleanString = try SwiftSoup.clean(string, Whitelist.none())
            return cleanString?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            // У випадку помилки використовуємо регулярний вираз як запасний варіант
            let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: .caseInsensitive)
            let range = NSRange(location: 0, length: string.count)
            let result = regex?.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "") ?? string
            return result.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    // Тут буде метод parseScheduleFromHTML - схожий до студентського, але адаптований для викладачів
    private func parseScheduleFromHTML(_ html: String) {
        do {
            let doc = try SwiftSoup.parse(html)
            
            guard let viewContent = try? doc.select(".view-content").first() else {
                showAlert(title: "Помилка", message: "Відсутні дані за заданим запитом")
                return
            }
            
            scheduleDays.removeAll()
            
            // Перевіряємо чи є повідомлення про відсутність даних
            if let noDataMessage = try? viewContent.select(".view-empty").first()?.text(),
               !noDataMessage.isEmpty {
                showAlert(title: "Інформація", message: "Розклад не знайдено для викладача \(teacherName)")
                return
            }
            
            // Для викладачів парсимо всі елементи послідовно
            var allElements: [Element] = []
            if let children = try? viewContent.children() {
                for child in children {
                    allElements.append(child)
                }
            }
            
            var currentDayName = ""
            var currentLessonNumber = ""
            var currentDaySchedule = ScheduleDay(dayName: "", lessons: [])
            
            for element in allElements {
                // Перевіряємо чи це заголовок дня
                if (try? element.hasClass("view-grouping-header")) == true {
                    // Зберігаємо попередній день, якщо він не порожній
                    if !currentDaySchedule.dayName.isEmpty && !currentDaySchedule.lessons.isEmpty {
                        scheduleDays.append(currentDaySchedule)
                    }
                    
                    // Починаємо новий день
                    currentDayName = try! element.text()
                    currentDaySchedule = ScheduleDay(dayName: currentDayName, lessons: [])
                    continue
                }
                
                // Перевіряємо чи це номер пари
                if (try? element.tagName()) == "h3" {
                    currentLessonNumber = try! element.text()
                    continue
                }
                
                // Перевіряємо чи це контейнер з заняттям
                if (try? element.hasClass("stud_schedule")) == true {
                    var lessonsForThisPair: [Lesson] = []
                    var lessonIdTypes: [String] = [] // Зберігаємо типи id для аналізу пріоритету
                    
                    // В контейнері можуть бути кілька .views-row
                    if let lessonRows = try? element.select(".views-row") {
                        for lessonRow in lessonRows {
                            var weekType: WeekType = .full
                            var subgroupType: String?
                            var elementIdType = ""
                            
                            // Визначаємо тип тижня та підгрупи
                            if let divElement = try? lessonRow.select("[id^=group_], [id^=sub_]").first() {
                                let divId = try? divElement.id()
                                
                                if let id = divId {
                                    elementIdType = id // Зберігаємо повний id
                                    
                                    if id.contains("chys") {
                                        weekType = .even
                                    } else if id.contains("znam") {
                                        weekType = .odd
                                    }
                                    
                                    if id.contains("sub_1") {
                                        subgroupType = "підгрупа 1"
                                    } else if id.contains("sub_2") {
                                        subgroupType = "підгрупа 2"
                                    }
                                }
                            }
                            
                            if let lessonContent = try? lessonRow.select(".group_content").first() {
                                let lessonHtml = try? lessonContent.html() ?? ""
                                
                                let lessonText = lessonHtml?.replacingOccurrences(of: "<br>", with: "\n")
                                                             .replacingOccurrences(of: "<br />", with: "\n") ?? ""
                                let lines = lessonText.components(separatedBy: "\n")
                                                     .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                                     .filter { !$0.isEmpty }
                                
                                var lessonName = ""
                                var groupName = ""
                                var room = ""
                                var type = ""
                                var url: String? = nil
                                
                                if lines.count > 0 {
                                    lessonName = removeHTMLTags(from: lines[0])
                                }
                                
                                if lines.count > 1 {
                                    let details = lines[1]
                                    
                                    // Правильний парсинг для викладачів
                                    let components = details.components(separatedBy: ", ")
                                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                        .filter { !$0.isEmpty }
                                    
                                    if !components.isEmpty {
                                        // Останній компонент - завжди тип заняття
                                        let lastComponent = components.last!
                                        if lastComponent.lowercased().contains("лекція") ||
                                           lastComponent.lowercased().contains("практична") ||
                                           lastComponent.lowercased().contains("семінар") ||
                                           lastComponent.lowercased().contains("лабораторна") {
                                            type = removeHTMLTags(from: lastComponent)
                                            
                                            if components.count > 1 {
                                                // Передостанній може бути аудиторією
                                                let secondToLast = components[components.count - 2]
                                                let cleanSecondToLast = removeHTMLTags(from: secondToLast)
                                                
                                                // Перевіряємо чи це схоже на аудиторію
                                                if cleanSecondToLast.range(of: "\\d", options: .regularExpression) != nil ||
                                                   cleanSecondToLast.count <= 10 {
                                                    room = cleanSecondToLast
                                                    // Групи - все крім останніх двох компонентів
                                                    if components.count > 2 {
                                                        let groupComponents = Array(components.dropLast(2))
                                                        groupName = groupComponents.map { removeHTMLTags(from: $0) }.joined(separator: ", ")
                                                    }
                                                } else {
                                                    // Це не аудиторія, а частина групи
                                                    let groupComponents = Array(components.dropLast(1))
                                                    groupName = groupComponents.map { removeHTMLTags(from: $0) }.joined(separator: ", ")
                                                }
                                            }
                                        } else {
                                            // Останній компонент не схожий на тип - всі компоненти є групами
                                            groupName = components.map { removeHTMLTags(from: $0) }.joined(separator: ", ")
                                        }
                                    }
                                    
                                    if let subgroup = subgroupType {
                                        groupName = groupName.isEmpty ? subgroup : "\(groupName), \(subgroup)"
                                    }
                                }
                                
                                // Перевіряємо наявність URL
                                if let link = try? lessonContent.select("a[href]").first() {
                                    let href = try? link.attr("href")
                                    if let linkHref = href, !linkHref.isEmpty {
                                        url = linkHref
                                    }
                                }
                                
                                if lessonName.isEmpty { lessonName = "Невідомо" }
                                if groupName.isEmpty { groupName = "Група не вказана" }
                                if room.isEmpty { room = "Аудиторія не вказана" }
                                if type.isEmpty { type = "Тип не вказаний" }
                                
                                let lesson = Lesson(
                                    number: currentLessonNumber,
                                    name: lessonName,
                                    teacher: groupName,
                                    room: room,
                                    type: type,
                                    timeStart: getTimeStart(for: currentLessonNumber),
                                    timeEnd: getTimeEnd(for: currentLessonNumber),
                                    url: url,
                                    weekType: weekType
                                )
                                
                                lessonsForThisPair.append(lesson)
                                lessonIdTypes.append(elementIdType)
                            }
                        }
                    }
                    
                    // ВИПРАВЛЕНА логіка пріоритету на основі HTML id
                    let filteredLessons = filterLessonsByHtmlId(lessonsForThisPair, idTypes: lessonIdTypes)
                    currentDaySchedule.lessons.append(contentsOf: filteredLessons)
                }
            }
            
            // Додаємо останній день, якщо він не порожній
            if !currentDaySchedule.dayName.isEmpty && !currentDaySchedule.lessons.isEmpty {
                scheduleDays.append(currentDaySchedule)
            }
            
            if scheduleDays.isEmpty {
                showAlert(title: "Інформація", message: "Розклад не знайдено для викладача \(teacherName)")
            } else {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                
                self.tableView.reloadData()
                
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
                
                CATransaction.commit()
            }
        } catch {
            showAlert(title: "Помилка парсингу", message: error.localizedDescription)
        }
    }

    // НОВИЙ МЕТОД: Фільтрування занять за HTML id
    private func filterLessonsByHtmlId(_ lessons: [Lesson], idTypes: [String]) -> [Lesson] {
        guard lessons.count == idTypes.count else {
            return lessons // Якщо кількість не співпадає, повертаємо всі заняття
        }
        
        // Перевіряємо чи є group_full серед id
        let hasGroupFull = idTypes.contains { id in
            id.starts(with: "group_") && id.contains("full")
        }
        
        if hasGroupFull {
            // Якщо є group_full, беремо тільки ті заняття, що мають group_full id
            var filteredLessons: [Lesson] = []
            for (index, id) in idTypes.enumerated() {
                if id.starts(with: "group_") && id.contains("full") {
                    filteredLessons.append(lessons[index])
                }
            }
            return filteredLessons
        } else {
            // Якщо немає group_full, беремо всі заняття (включно з sub_full)
            return lessons
        }
    }

    // НОВИЙ МЕТОД: Фільтрування занять за пріоритетом
    // ВИПРАВЛЕНИЙ МЕТОД: Фільтрування занять за пріоритетом
    private func filterLessonsByPriority(_ lessons: [Lesson]) -> [Lesson] {
        // Просто повертаємо всі заняття без фільтрації по пріоритету
        // Оскільки логіка визначення group_full vs sub_full має базуватися на HTML id, а не на тексті
        return lessons
    }

    private func groupLessonsByNumber(_ lessons: [Lesson]) -> [[Lesson]] {
        var lessonGroups: [String: [Lesson]] = [:]
        
        for lesson in lessons {
            if lessonGroups[lesson.number] == nil {
                lessonGroups[lesson.number] = []
            }
            lessonGroups[lesson.number]?.append(lesson)
        }
        
        var resultGroups: [[Lesson]] = []
        
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
          
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.tintColor = ThemeManager.shared.accentColor
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }

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
        
        let topLine = UIView()
        topLine.backgroundColor = theme.accentColor.withAlphaComponent(0.1)
        topLine.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(topLine)
        
        let dayLabel = UILabel()
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        dayLabel.font = .systemFont(ofSize: 17, weight: .medium)
        dayLabel.textColor = theme.accentColor
        
        let shortDayName = scheduleDays[section].dayName
        dayLabel.text = dayTranslations[shortDayName] ?? shortDayName
        
        headerView.addSubview(dayLabel)
        
        NSLayoutConstraint.activate([
            topLine.topAnchor.constraint(equalTo: headerView.topAnchor),
            topLine.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            topLine.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            topLine.heightAnchor.constraint(equalToConstant: 1),
            
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
            
            var baseHeight: CGFloat = 180 // Збільшуємо базову висоту
            
            // Перевіряємо наявність довгих списків груп
            let hasLongGroupList = lessonGroup.contains { lesson in
                lesson.teacher.count > 30 // Якщо список груп довгий
            }
            
            if hasLongGroupList {
                baseHeight += 40 // Додаємо додаткове місце для довгих списків
            }
            
            let hasURL = lessonGroup.contains {
                guard let url = $0.url else { return false }
                return !url.isEmpty
            }
            
            if hasURL {
                baseHeight += 50
            }
            
            let evenWeekLessons = lessonGroup.filter { $0.weekType == .even }
            let oddWeekLessons = lessonGroup.filter { $0.weekType == .odd }
            let hasAlternatingWeeks = (!evenWeekLessons.isEmpty || !oddWeekLessons.isEmpty)
            
            let subgroup1Lessons = lessonGroup.filter { $0.teacher.contains("підгрупа 1") }
            let subgroup2Lessons = lessonGroup.filter { $0.teacher.contains("підгрупа 2") }
            let hasSubgroups = (!subgroup1Lessons.isEmpty || !subgroup2Lessons.isEmpty)
            
            if hasAlternatingWeeks && hasSubgroups {
                baseHeight += 120
                if hasLongGroupList {
                    baseHeight += 30 // Ще більше місця для складних випадків
                }
            } else if hasSubgroups {
                baseHeight += 50
            } else if hasAlternatingWeeks {
                baseHeight += 120
                if hasLongGroupList {
                    baseHeight += 30 // Додаткове місце для чергування тижнів з довгими списками
                }
            }
              
            return baseHeight
        }
          
        return 180
    }
          
    func numberOfSections(in tableView: UITableView) -> Int {
        return scheduleDays.count
    }
          
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let groupedLessons = groupLessonsByNumber(scheduleDays[section].lessons)
        return groupedLessons.count
    }
          
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let groupedLessons = groupLessonsByNumber(scheduleDays[indexPath.section].lessons)
        guard groupedLessons.count > indexPath.row else {
            return UITableViewCell()
        }
          
        let lessonGroup = groupedLessons[indexPath.row]
          
        // Використовуємо ту саму клітинку!
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProgrammaticLessonCell", for: indexPath) as! ProgrammaticLessonCell
        cell.configureWithLessons(lessons: lessonGroup)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
