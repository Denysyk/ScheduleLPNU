//
//  ResultExternalPhdStudentScheduleViewController.swift
//  ScheduleLPNU
//
//  Created by Denys Brativnyk on 25.05.2025.
//

import UIKit
import SwiftSoup
import SystemConfiguration

class ResultExternalPhdStudentScheduleViewController: BaseFullScreenViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
       
    var groupName: String = ""
    var semester: String = ""
          
    var isOfflineMode: Bool = false
    var scheduleDays: [ScheduleDay] = []
    private var activityIndicator: UIActivityIndicatorView!
    
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
        
        tableView.register(ProgrammaticLessonCell.self, forCellReuseIdentifier: "ProgrammaticLessonCell")
               
        if #available(iOS 10.0, *) {
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(self, action: #selector(refreshSchedule(_:)), for: .valueChanged)
            tableView.refreshControl = refreshControl
        }
    }
           
    private func setupNavigationBar() {
        let fullTitle = "Розклад \(groupName) (Аспіранти-заочники)"
                   
        let containerView = UIView()
               
        let titleLabel = UILabel()
        titleLabel.text = fullTitle
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
               
        containerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
               
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -4),
            titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 200),
            titleLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 50)
        ])
               
        let titleSize = titleLabel.sizeThatFits(CGSize(width: 200, height: 50))
        containerView.frame = CGRect(x: 0, y: 0, width: min(200, titleSize.width + 8), height: max(44, titleSize.height))
               
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
               
        guard !groupName.isEmpty else {
            showAlert(title: "Помилка", message: "Назва групи не вказана")
            return
        }
               
        let semesterValue = semester.contains("1") ? "1" : "2"
               
        let baseURL = "https://student.lpnu.ua/postgraduate_parttime"
        let encodedGroup = groupName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? groupName
        let urlString = "\(baseURL)?studygroup_abbrname=\(encodedGroup)&semestr=\(semesterValue)"
               
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
            id: "externalPhd_\(groupName)_\(semester)",
            title: "Розклад \(groupName) (Аспіранти-заочники)",
            type: .externalPhd,
            groupName: groupName,
            teacherName: nil,
            semester: semester,
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
                showAlert(title: "Інформація", message: "Розклад не знайдено для групи \(groupName)")
                return
            }
                   
            // Парсимо всі елементи послідовно
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
                // Перевіряємо чи це заголовок дня (дата)
                if (try? element.hasClass("view-grouping-header")) == true {
                    let dateText = try! element.text().trimmingCharacters(in: .whitespacesAndNewlines)
                           
                    // Пропускаємо порожні заголовки
                    if dateText.isEmpty {
                        continue
                    }
                           
                    // Зберігаємо попередній день, якщо він не порожній
                    if !currentDaySchedule.dayName.isEmpty && !currentDaySchedule.lessons.isEmpty {
                        scheduleDays.append(currentDaySchedule)
                    }
                           
                    // Починаємо новий день з датою
                    currentDayName = dateText
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
                           
                    // В контейнері можуть бути кілька .views-row
                    if let lessonRows = try? element.select(".views-row") {
                        for lessonRow in lessonRows {
                            var weekType: WeekType = .full
                            var subgroupType: String?
                                   
                            var isActiveThisWeek = false

                            // Визначаємо тип тижня та підгрупи
                            if let divElement = try? lessonRow.select("[id^=group_], [id^=sub_]").first() {
                                let divId = try? divElement.id()
                                let divClass = try? divElement.className()
                                
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
                                
                                // Визначаємо активність через week_color
                                if let className = divClass, className.contains("week_color") {
                                    isActiveThisWeek = true
                                }
                            }
                            // Парсимо вміст заняття
                            if let lessonContent = try? lessonRow.select(".group_content").first() {
                                let lessonHtml = try? lessonContent.html() ?? ""
                                       
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
                                           
                                    // Парсинг для аспірантів-заочників:
                                    // Формат: "Волошин М.М., Практична" (викладач, тип заняття)
                                    let components = details.components(separatedBy: ", ")
                                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                        .filter { !$0.isEmpty }
                                           
                                    if components.count >= 2 {
                                        // Перший компонент - викладач
                                        teacher = removeHTMLTags(from: components[0])
                                        // Другий компонент - тип заняття
                                        type = removeHTMLTags(from: components[1])
                                               
                                        // Додаємо інформацію про підгрупу до імені викладача, якщо вона є
                                        if let subgroup = subgroupType {
                                            teacher += ", \(subgroup)"
                                        }
                                               
                                        // Аудиторії немає для аспірантів-заочників
                                        room = ""
                                    } else if components.count == 1 {
                                        // Якщо тільки один компонент
                                        let component = removeHTMLTags(from: components[0])
                                        if component.lowercased().contains("лекція") ||
                                           component.lowercased().contains("практична") ||
                                           component.lowercased().contains("семінар") ||
                                           component.lowercased().contains("лабораторна") ||
                                           component.lowercased().contains("консультація") ||
                                           component.lowercased().contains("екзамен") {
                                            type = component
                                            teacher = ""
                                        } else {
                                            teacher = component
                                            type = ""
                                        }
                                               
                                        if let subgroup = subgroupType {
                                            teacher = teacher.isEmpty ? subgroup : "\(teacher), \(subgroup)"
                                        }
                                               
                                        room = ""
                                    }
                                }
                                       
                                // Перевіряємо наявність URL для онлайн-заняття
                                if let link = try? lessonContent.select("a[href]").first() {
                                    let href = try? link.attr("href")
                                    if let linkHref = href, !linkHref.isEmpty {
                                        url = linkHref
                                    }
                                }
                                       
                                // НЕ заповнюємо порожні поля заповнювачами
                                if lessonName.isEmpty { lessonName = "Невідомо" }
                                       
                                let lesson = Lesson(
                                    number: currentLessonNumber,
                                    name: lessonName,
                                    teacher: teacher,
                                    room: room,
                                    type: type,
                                    timeStart: getTimeStart(for: currentLessonNumber),
                                    timeEnd: getTimeEnd(for: currentLessonNumber),
                                    url: url,
                                    weekType: weekType, isActiveThisWeek: isActiveThisWeek
                                )
                                       
                                lessonsForThisPair.append(lesson)
                            }
                        }
                    }
                           
                    currentDaySchedule.lessons.append(contentsOf: lessonsForThisPair)
                }
            }
                   
            // Додаємо останній день, якщо він не порожній
            if !currentDaySchedule.dayName.isEmpty && !currentDaySchedule.lessons.isEmpty {
                scheduleDays.append(currentDaySchedule)
            }
                   
            if scheduleDays.isEmpty {
                showAlert(title: "Інформація", message: "Розклад не знайдено для групи \(groupName)")
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
               
        let dayName = scheduleDays[section].dayName
        // Для аспірантів-заочників відображаємо дату як є (2025-01-15)
        dayLabel.text = dayName
               
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
                   
            var baseHeight: CGFloat = 180 // Зменшуємо базову висоту, оскільки немає аудиторії
                   
            // Перевіряємо наявність довгих імен викладачів
            let hasLongTeacherName = lessonGroup.contains { lesson in
                lesson.teacher.count > 30
            }
                   
            if hasLongTeacherName {
                baseHeight += 40
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
                if hasLongTeacherName {
                    baseHeight += 30
                }
            } else if hasSubgroups {
                baseHeight += 50
            } else if hasAlternatingWeeks {
                baseHeight += 120
                if hasLongTeacherName {
                    baseHeight += 30
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
