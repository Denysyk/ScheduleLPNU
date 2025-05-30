import UIKit
import SwiftSoup
import SystemConfiguration

class ResultTeacherExamScheduleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var teacherName: String = ""
       
    var isOfflineMode: Bool = false
    // Використовуємо загальні структури з ScheduleModels.swift
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
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .semibold)
        ]
        navigationController?.navigationBar.tintColor = theme.accentColor
        
        // Update title view
        if let titleView = navigationItem.titleView as? UILabel {
            titleView.textColor = theme.accentColor
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
    
    private func setupCustomNavigationTitle() {
        let fullTitle = "Екзамени \(teacherName)"
        
        let labelWidth: CGFloat = 250
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: labelWidth, height: 50))
        titleLabel.text = fullTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        titleLabel.adjustsFontSizeToFitWidth = false
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byWordWrapping
        
        titleLabel.preferredMaxLayoutWidth = labelWidth
        
        titleLabel.sizeToFit()
        var frame = titleLabel.frame
        frame.size.width = labelWidth
        titleLabel.frame = frame
        
        navigationItem.titleView = titleLabel
    }
    
    
    private func setupNavigationBar() {
        // Створюємо кастомний заголовок з перенесенням тексту
        setupCustomNavigationTitle()
        
        navigationController?.navigationBar.tintColor = ThemeManager.shared.accentColor
        
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
        
        guard !teacherName.isEmpty else {
            showAlert(title: "Помилка", message: "Ім'я викладача не вказане")
            return
        }
        
        // URL для екзаменів викладачів (без параметрів семестру)
        let baseURL = "https://staff.lpnu.ua/lecturer_exam"
        let encodedTeacher = teacherName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? teacherName
        let urlString = "\(baseURL)?teachername=\(encodedTeacher)"
        
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
            id: "teacherExam_\(teacherName)",
            title: "Екзамени \(teacherName)",
            type: .teacherExam,
            groupName: nil,
            teacherName: teacherName,
            semester: nil,
            semesterDuration: nil,
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
                       
            // Перевіряємо чи є повідомлення про відсутність даних
            if let noDataMessage = try? viewContent.select(".view-empty").first()?.text(),
               !noDataMessage.isEmpty {
                showAlert(title: "Інформація", message: "Розклад екзаменів не знайдено для викладача \(teacherName)")
                return
            }
                       
            // Для екзаменів викладачів використовуємо комбінований підхід:
            // - Лінійний парсинг як у екзаменів студентів
            // - Логіка груп замість викладачів як у звичайному розкладі викладачів
                       
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
                // Перевіряємо чи це заголовок дня (може бути дата для екзаменів)
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
                           
                // Перевіряємо чи це контейнер з екзаменом (.stud_schedule для викладачів)
                if (try? element.hasClass("stud_schedule")) == true {
                    // В контейнері можуть бути кілька .views-row
                    if let lessonRows = try? element.select(".views-row") {
                        for lessonRow in lessonRows {
                            var weekType: WeekType = .full // Екзамени зазвичай не мають чергування тижнів
                            var subgroupType: String?
                                       
                            // Визначаємо тип тижня та підгрупи (якщо є)
                            if let divElement = try? lessonRow.select("[id^=group_], [id^=sub_]").first() {
                                let divId = try? divElement.id()
                                           
                                if let id = divId {
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
                                var type = "Екзамен" // За замовчуванням для екзаменів
                                var timeStart = ""
                                var timeEnd = ""
                                var url: String? = nil
                                           
                                if lines.count > 0 {
                                    lessonName = removeHTMLTags(from: lines[0])
                                }
                                           
                                if lines.count > 1 {
                                    let details = lines[1]
                                    let components = details.components(separatedBy: ", ")
                                               
                                    // Логіка для викладачів: групи замість викладачів
                                    if components.count >= 3 {
                                        // Якщо є принаймні 3 компоненти, останні два - це аудиторія і тип
                                        let groupComponents = Array(components.dropLast(2))
                                        groupName = groupComponents.joined(separator: ", ")
                                                   
                                        room = removeHTMLTags(from: components[components.count - 2])
                                                   
                                        // Останній компонент може бути часом або типом
                                        let lastComponent = removeHTMLTags(from: components[components.count - 1])
                                        if lastComponent.contains(":") {
                                            // Це час екзамену
                                            let timeComponents = lastComponent.components(separatedBy: "-")
                                            if timeComponents.count == 2 {
                                                timeStart = timeComponents[0].trimmingCharacters(in: .whitespacesAndNewlines)
                                                timeEnd = timeComponents[1].trimmingCharacters(in: .whitespacesAndNewlines)
                                            }
                                        } else {
                                            type = lastComponent
                                        }
                                    } else if components.count == 2 {
                                        // Тільки група і аудиторія/час
                                        groupName = removeHTMLTags(from: components[0])
                                        let secondComponent = removeHTMLTags(from: components[1])
                                                   
                                        if secondComponent.contains(":") {
                                            // Це час
                                            let timeComponents = secondComponent.components(separatedBy: "-")
                                            if timeComponents.count == 2 {
                                                timeStart = timeComponents[0].trimmingCharacters(in: .whitespacesAndNewlines)
                                                timeEnd = timeComponents[1].trimmingCharacters(in: .whitespacesAndNewlines)
                                            }
                                        } else {
                                            room = secondComponent
                                        }
                                    } else {
                                        // Тільки група
                                        groupName = removeHTMLTags(from: components[0])
                                    }
                                               
                                    if let subgroup = subgroupType {
                                        groupName += ", \(subgroup)"
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
                                if type.isEmpty { type = "Екзамен" }
                                           
                                // Якщо час не знайдено в тексті, використовуємо стандартний за номером пари
                                if timeStart.isEmpty {
                                    timeStart = getExamTimeStart(for: currentLessonNumber)
                                    timeEnd = getExamTimeEnd(for: currentLessonNumber)
                                }
                                           
                                let lesson = Lesson(
                                    number: currentLessonNumber,
                                    name: lessonName,
                                    teacher: groupName, // Тут зберігаємо групу (логіка викладачів)
                                    room: room,
                                    type: type,
                                    timeStart: timeStart,
                                    timeEnd: timeEnd,
                                    url: url,
                                    weekType: weekType
                                )
                                           
                                currentDaySchedule.lessons.append(lesson)
                            }
                        }
                    }
                }
            }
                       
            // Додаємо останній день, якщо він не порожній
            if !currentDaySchedule.dayName.isEmpty && !currentDaySchedule.lessons.isEmpty {
                scheduleDays.append(currentDaySchedule)
            }
                       
            if scheduleDays.isEmpty {
                showAlert(title: "Інформація", message: "Розклад екзаменів не знайдено для викладача \(teacherName)")
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

    // Час для екзаменів може відрізнятися від звичайних занять
    private func getExamTimeStart(for lessonNumber: String) -> String {
        switch lessonNumber {
        case "1": return "08:30"
        case "2": return "10:15"
        case "3": return "12:00"
        case "4": return "13:45"
        case "5": return "15:30"
        case "6": return "17:15"
        default: return ""
        }
    }

    private func getExamTimeEnd(for lessonNumber: String) -> String {
        switch lessonNumber {
        case "1": return "10:00"
        case "2": return "11:45"
        case "3": return "13:30"
        case "4": return "15:15"
        case "5": return "17:00"
        case "6": return "18:45"
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
        // Для екзаменів може бути дата замість дня тижня
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
                       
            var baseHeight: CGFloat = 120 // Менша базова висота для екзаменів
                       
            // Перевіряємо наявність довгих списків груп
            let hasLongGroupList = lessonGroup.contains { lesson in
                lesson.teacher.count > 30
            }
                       
            if hasLongGroupList {
                baseHeight += 40 // Додаткове місце для довгих списків груп
            }
                       
            let hasURL = lessonGroup.contains {
                guard let url = $0.url else { return false }
                return !url.isEmpty
            }
                       
            if hasURL {
                baseHeight += 50
            }
                       
            // Для екзаменів зазвичай немає підгруп та чергування тижнів
            // Але на всякий випадок залишаємо спрощену логіку
            let evenWeekLessons = lessonGroup.filter { $0.weekType == .even }
            let oddWeekLessons = lessonGroup.filter { $0.weekType == .odd }
            let hasAlternatingWeeks = (!evenWeekLessons.isEmpty || !oddWeekLessons.isEmpty)
                       
            let subgroup1Lessons = lessonGroup.filter { $0.teacher.contains("підгрупа 1") }
            let subgroup2Lessons = lessonGroup.filter { $0.teacher.contains("підгрупа 2") }
            let hasSubgroups = (!subgroup1Lessons.isEmpty || !subgroup2Lessons.isEmpty)
                       
            if hasAlternatingWeeks && hasSubgroups {
                baseHeight += 100
            } else if hasSubgroups {
                baseHeight += 40
            } else if hasAlternatingWeeks {
                baseHeight += 60
            }
                         
            return baseHeight
        }
                     
        return 120
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
                     
        // Використовуємо звичайний метод для екзаменів викладачів
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
