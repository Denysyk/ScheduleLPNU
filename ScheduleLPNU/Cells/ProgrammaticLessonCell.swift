import UIKit

class ProgrammaticLessonCell: UITableViewCell {
    // UI елементи для хедера
    private var headerView: UIView!
    private var headerNumberLabel: UILabel!
    private var headerTimeLabel: UILabel!
    
    // Контейнер для занять
    private var lessonsContainerView: UIView!
    
    // Масиви для занять
    private var lessonViews: [UIView] = []
    private var lessonURLButtons: [UIButton] = []
    private var lessonURLs: [URL] = []
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupThemeObserver()
        applyTheme()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupThemeObserver()
        applyTheme()
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
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        // Header
        headerView?.backgroundColor = theme.cardBackgroundColor
        headerNumberLabel?.textColor = theme.accentColor
        headerTimeLabel?.textColor = theme.secondaryTextColor
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        setupHeaderView()
        setupLessonsContainerView()
    }
    
    private func setupHeaderView() {
        headerView = UIView()
        headerView.layer.cornerRadius = 16
        headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        headerView.clipsToBounds = true
        
        // Тінь
        headerView.layer.shadowColor = UIColor.black.cgColor
        headerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        headerView.layer.shadowOpacity = 0.08
        headerView.layer.shadowRadius = 6
        headerView.layer.masksToBounds = false
        
        contentView.addSubview(headerView)
        
        // Мітка для номера пари
        headerNumberLabel = UILabel()
        headerNumberLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        headerView.addSubview(headerNumberLabel)
        
        // Мітка для часу
        headerTimeLabel = UILabel()
        headerTimeLabel.font = .systemFont(ofSize: 14, weight: .medium)
        headerView.addSubview(headerTimeLabel)
        
        // Налаштування Auto Layout
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        headerTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            headerView.heightAnchor.constraint(equalToConstant: 38),
            
            headerNumberLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            headerNumberLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            headerTimeLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            headerTimeLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
    }
    
    private func setupLessonsContainerView() {
        lessonsContainerView = UIView()
        lessonsContainerView.backgroundColor = .clear
        contentView.addSubview(lessonsContainerView)
        
        lessonsContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            lessonsContainerView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            lessonsContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            lessonsContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            lessonsContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])
    }
    
    func configureWithLessons(lessons: [Lesson]) {
        clearLessons()
        
        guard !lessons.isEmpty else {
            createEmptyLessonView()
            return
        }
        
        if let firstLesson = lessons.first {
            headerNumberLabel.text = "\(firstLesson.number) пара"
            headerTimeLabel.text = "\(firstLesson.timeStart) - \(firstLesson.timeEnd)"
        }
        
        let fullWeekLessons = lessons.filter { $0.weekType == .full }
        let evenWeekLessons = lessons.filter { $0.weekType == .even }
        let oddWeekLessons = lessons.filter { $0.weekType == .odd }
        
        let subgroup1Lessons = lessons.filter { $0.teacher.contains("підгрупа 1") }
        let subgroup2Lessons = lessons.filter { $0.teacher.contains("підгрупа 2") }
        
        let hasSubgroups = !subgroup1Lessons.isEmpty || !subgroup2Lessons.isEmpty
        let hasAlternatingWeeks = !evenWeekLessons.isEmpty || !oddWeekLessons.isEmpty
        
        if hasSubgroups && hasAlternatingWeeks {
            createComplexView(subgroup1Lessons, subgroup2Lessons, evenWeekLessons, oddWeekLessons)
        } else if hasSubgroups {
            createSplitViewForSubgroups(subgroup1Lessons, subgroup2Lessons)
        } else if hasAlternatingWeeks {
            createSplitViewForWeeks(evenWeekLessons, oddWeekLessons)
        } else if !fullWeekLessons.isEmpty {
            createFullWidthView(fullWeekLessons)
        } else {
            createEmptyLessonView()
        }
    }
    
    // Метод для створення складного відображення для підгруп і тижнів
    private func createComplexView(_ subgroup1Lessons: [Lesson],
                                 _ subgroup2Lessons: [Lesson],
                                 _ evenWeekLessons: [Lesson],
                                 _ oddWeekLessons: [Lesson]) {
        let horizontalStack = UIStackView()
        horizontalStack.axis = .horizontal
        horizontalStack.distribution = .fillEqually
        horizontalStack.spacing = 10
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        lessonsContainerView.addSubview(horizontalStack)
        
        NSLayoutConstraint.activate([
            horizontalStack.topAnchor.constraint(equalTo: lessonsContainerView.topAnchor),
            horizontalStack.leadingAnchor.constraint(equalTo: lessonsContainerView.leadingAnchor),
            horizontalStack.trailingAnchor.constraint(equalTo: lessonsContainerView.trailingAnchor),
            horizontalStack.bottomAnchor.constraint(equalTo: lessonsContainerView.bottomAnchor)
        ])
        
        let leftVerticalStack = UIStackView()
        leftVerticalStack.axis = .vertical
        leftVerticalStack.distribution = .fillEqually
        leftVerticalStack.spacing = 6
        leftVerticalStack.translatesAutoresizingMaskIntoConstraints = false
        horizontalStack.addArrangedSubview(leftVerticalStack)
        
        let rightVerticalStack = UIStackView()
        rightVerticalStack.axis = .vertical
        rightVerticalStack.distribution = .fillEqually
        rightVerticalStack.spacing = 6
        rightVerticalStack.translatesAutoresizingMaskIntoConstraints = false
        horizontalStack.addArrangedSubview(rightVerticalStack)
        
        let subgroup1Even = subgroup1Lessons.first(where: { $0.weekType == .even }) ??
        evenWeekLessons.first(where: { $0.teacher.contains("підгрупа 1") })
        let subgroup1Odd = subgroup1Lessons.first(where: { $0.weekType == .odd }) ??
        oddWeekLessons.first(where: { $0.teacher.contains("підгрупа 1") })
        
        let hasURL1Even = subgroup1Even?.url != nil && !(subgroup1Even?.url?.isEmpty ?? true)
        let hasURL1Odd = subgroup1Odd?.url != nil && !(subgroup1Odd?.url?.isEmpty ?? true)
        
        let subgroup2Even = subgroup2Lessons.first(where: { $0.weekType == .even }) ??
        evenWeekLessons.first(where: { $0.teacher.contains("підгрупа 2") })
        let subgroup2Odd = subgroup2Lessons.first(where: { $0.weekType == .odd }) ??
        oddWeekLessons.first(where: { $0.teacher.contains("підгрупа 2") })
        let hasURL2Even = subgroup2Even?.url != nil && !(subgroup2Even?.url?.isEmpty ?? true)
        let hasURL2Odd = subgroup2Odd?.url != nil && !(subgroup2Odd?.url?.isEmpty ?? true)
        
        // ВЕРХНІЙ РЯД (even week) - без верхнього заокруглення
        if let lesson = subgroup1Even {
            let evenView = createLessonView(lesson: lesson, isFullWidth: false, isTopRow: true,
                                          hasExtraSpaceForURL: hasURL2Even && !hasURL1Even)
            leftVerticalStack.addArrangedSubview(evenView)
        } else {
            leftVerticalStack.addArrangedSubview(createEmptyTopRowView())
        }
        
        // НИЖНІЙ РЯД (odd week) - з усім заокругленням
        if let lesson = subgroup1Odd {
            let oddView = createLessonView(lesson: lesson, isFullWidth: false, isTopRow: false,
                                         hasExtraSpaceForURL: hasURL2Odd && !hasURL1Odd)
            leftVerticalStack.addArrangedSubview(oddView)
        } else {
            leftVerticalStack.addArrangedSubview(createEmptyOddWeekView())
        }
        
        // ВЕРХНІЙ РЯД (even week) - без верхнього заокруглення
        if let lesson = subgroup2Even {
            let evenView = createLessonView(lesson: lesson, isFullWidth: false, isTopRow: true,
                                           hasExtraSpaceForURL: hasURL1Even && !hasURL2Even)
            rightVerticalStack.addArrangedSubview(evenView)
        } else {
            rightVerticalStack.addArrangedSubview(createEmptyTopRowView())
        }
        
        // НИЖНІЙ РЯД (odd week) - з усім заокругленням
        if let lesson = subgroup2Odd {
            let oddView = createLessonView(lesson: lesson, isFullWidth: false, isTopRow: false,
                                          hasExtraSpaceForURL: hasURL1Odd && !hasURL2Odd)
            rightVerticalStack.addArrangedSubview(oddView)
        } else {
            rightVerticalStack.addArrangedSubview(createEmptyOddWeekView())
        }
    }
    
    private func createSplitViewForSubgroups(_ subgroup1Lessons: [Lesson], _ subgroup2Lessons: [Lesson]) {
        let horizontalStack = UIStackView()
        horizontalStack.axis = .horizontal
        horizontalStack.distribution = .fillEqually
        horizontalStack.spacing = 10
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        lessonsContainerView.addSubview(horizontalStack)
        
        NSLayoutConstraint.activate([
            horizontalStack.topAnchor.constraint(equalTo: lessonsContainerView.topAnchor),
            horizontalStack.leadingAnchor.constraint(equalTo: lessonsContainerView.leadingAnchor),
            horizontalStack.trailingAnchor.constraint(equalTo: lessonsContainerView.trailingAnchor),
            horizontalStack.bottomAnchor.constraint(equalTo: lessonsContainerView.bottomAnchor)
        ])
        
        let hasURL1 = !subgroup1Lessons.isEmpty && subgroup1Lessons[0].url != nil && !subgroup1Lessons[0].url!.isEmpty
        let hasURL2 = !subgroup2Lessons.isEmpty && subgroup2Lessons[0].url != nil && !subgroup2Lessons[0].url!.isEmpty
        
        if !subgroup1Lessons.isEmpty {
            let leftView = createLessonView(lesson: subgroup1Lessons[0], isFullWidth: false, isTopRow: true,
                                             hasExtraSpaceForURL: hasURL2 && !hasURL1)
            horizontalStack.addArrangedSubview(leftView)
        } else {
            horizontalStack.addArrangedSubview(createEmptyTopRowView())
        }
        
        if !subgroup2Lessons.isEmpty {
            let rightView = createLessonView(lesson: subgroup2Lessons[0], isFullWidth: false, isTopRow: true,
                                              hasExtraSpaceForURL: hasURL1 && !hasURL2)
            horizontalStack.addArrangedSubview(rightView)
        } else {
            horizontalStack.addArrangedSubview(createEmptyTopRowView())
        }
    }
    
    private func createSplitViewForWeeks(_ evenWeekLessons: [Lesson], _ oddWeekLessons: [Lesson]) {
        let verticalStack = UIStackView()
        verticalStack.axis = .vertical
        verticalStack.distribution = .fillEqually
        verticalStack.spacing = 6
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        lessonsContainerView.addSubview(verticalStack)
        
        NSLayoutConstraint.activate([
            verticalStack.topAnchor.constraint(equalTo: lessonsContainerView.topAnchor),
            verticalStack.leadingAnchor.constraint(equalTo: lessonsContainerView.leadingAnchor),
            verticalStack.trailingAnchor.constraint(equalTo: lessonsContainerView.trailingAnchor),
            verticalStack.bottomAnchor.constraint(equalTo: lessonsContainerView.bottomAnchor)
        ])
        
        // ВЕРХНІЙ БЛОК (even week) - без верхнього заокруглення
        if !evenWeekLessons.isEmpty {
            let evenView = createLessonView(lesson: evenWeekLessons[0], isFullWidth: true, isTopRow: true)
            verticalStack.addArrangedSubview(evenView)
        } else {
            verticalStack.addArrangedSubview(createEmptyTopRowView())
        }
        
        // НИЖНІЙ БЛОК (odd week) - з усім заокругленням
        if !oddWeekLessons.isEmpty {
            let oddView = createLessonView(lesson: oddWeekLessons[0], isFullWidth: true, isTopRow: false)
            verticalStack.addArrangedSubview(oddView)
        } else {
            verticalStack.addArrangedSubview(createEmptyOddWeekView())
        }
    }
    
    // НОВИЙ МЕТОД для порожніх блоків у верхньому ряду
    private func createEmptyTopRowView() -> UIView {
        let theme = ThemeManager.shared
        let emptyView = UIView()
        emptyView.backgroundColor = theme.secondaryCardBackgroundColor
        emptyView.layer.cornerRadius = 12
        emptyView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner] // Тільки нижні кути
        emptyView.layer.borderColor = theme.separatorColor.cgColor
        emptyView.layer.borderWidth = 1
        emptyView.clipsToBounds = true
        
        return emptyView
    }
    
    private func createEmptyEvenWeekView() -> UIView {
        let theme = ThemeManager.shared
        let emptyView = UIView()
        emptyView.backgroundColor = theme.secondaryCardBackgroundColor
        emptyView.layer.cornerRadius = 12
        emptyView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner] // Тільки нижні кути для верхнього ряду
        emptyView.layer.borderColor = theme.separatorColor.cgColor
        emptyView.layer.borderWidth = 1
        emptyView.clipsToBounds = true
        
        return emptyView
    }
    
    private func createEmptyOddWeekView() -> UIView {
        let theme = ThemeManager.shared
        let emptyView = UIView()
        emptyView.backgroundColor = theme.cardBackgroundColor
        emptyView.layer.cornerRadius = 12
        // Нижні блоки мають всі кути заокруглені
        emptyView.layer.borderColor = theme.separatorColor.cgColor
        emptyView.layer.borderWidth = 1
        emptyView.clipsToBounds = true
        
        return emptyView
    }
    
    private func createFullWidthView(_ lessons: [Lesson]) {
        if let firstLesson = lessons.first {
            let lessonView = createLessonView(lesson: firstLesson, isFullWidth: true, isTopRow: true)
            lessonView.translatesAutoresizingMaskIntoConstraints = false
            lessonsContainerView.addSubview(lessonView)
            
            NSLayoutConstraint.activate([
                lessonView.topAnchor.constraint(equalTo: lessonsContainerView.topAnchor),
                lessonView.leadingAnchor.constraint(equalTo: lessonsContainerView.leadingAnchor),
                lessonView.trailingAnchor.constraint(equalTo: lessonsContainerView.trailingAnchor),
                lessonView.bottomAnchor.constraint(equalTo: lessonsContainerView.bottomAnchor),
                lessonView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
            ])
        }
    }
    
    private func createEmptyView() -> UIView {
        let theme = ThemeManager.shared
        let emptyView = UIView()
        emptyView.backgroundColor = theme.secondaryCardBackgroundColor
        emptyView.layer.cornerRadius = 12
        emptyView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner] // Тільки нижні кути
        emptyView.layer.borderColor = theme.separatorColor.cgColor
        emptyView.layer.borderWidth = 1
        emptyView.clipsToBounds = true
        
        return emptyView
    }
    
    private func createEmptyLessonView() {
        let theme = ThemeManager.shared
        let emptyView = UIView()
        emptyView.backgroundColor = theme.secondaryCardBackgroundColor
        emptyView.layer.cornerRadius = 12
        emptyView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        emptyView.layer.borderColor = theme.separatorColor.cgColor
        emptyView.layer.borderWidth = 1
        emptyView.clipsToBounds = true
        
        lessonsContainerView.addSubview(emptyView)
        
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyView.topAnchor.constraint(equalTo: lessonsContainerView.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: lessonsContainerView.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: lessonsContainerView.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: lessonsContainerView.bottomAnchor),
            emptyView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])
    }

    // ОНОВЛЕНИЙ МЕТОД createLessonView з новим параметром isTopRow
    private func createLessonView(lesson: Lesson, isFullWidth: Bool, isTopRow: Bool = false, hasExtraSpaceForURL: Bool = false) -> UIView {
        let theme = ThemeManager.shared
        let lessonView = UIView()
        
        // ВИПРАВЛЕНО: Налаштування corner radius
        if isFullWidth {
            if isTopRow {
                // Для повної ширини у верхньому ряду - тільки нижні кути
                lessonView.layer.cornerRadius = 12
                lessonView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            } else {
                // Для повної ширини у нижньому ряду - всі кути
                lessonView.layer.cornerRadius = 12
            }
        } else {
            if isTopRow {
                // Для розділених блоків у верхньому ряду - тільки нижні кути
                lessonView.layer.cornerRadius = 12
                lessonView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            } else {
                // Для розділених блоків у нижньому ряду - всі кути
                lessonView.layer.cornerRadius = 12
            }
        }
        
        lessonView.clipsToBounds = true
        
        // Тіні
        lessonView.layer.shadowColor = UIColor.black.cgColor
        lessonView.layer.shadowOffset = CGSize(width: 0, height: 3)
        lessonView.layer.shadowOpacity = 0.12
        lessonView.layer.shadowRadius = 6
        lessonView.layer.masksToBounds = false
        
        // Градієнт
        let gradientLayer = CAGradientLayer()
        
        // ВИПРАВЛЕНО: Налаштування corner radius для градієнту
        if isFullWidth {
            if isTopRow {
                gradientLayer.cornerRadius = 12
                gradientLayer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            } else {
                gradientLayer.cornerRadius = 12
            }
        } else {
            if isTopRow {
                gradientLayer.cornerRadius = 12
                gradientLayer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            } else {
                gradientLayer.cornerRadius = 12
            }
        }
        
        // НОВА ЛОГІКА КОЛЬОРІВ: використовуємо isActiveThisWeek
        if lesson.isActiveThisWeek {
            // Активна пара - кольоровий градієнт
            gradientLayer.colors = [
                theme.accentColor.cgColor,
                theme.primaryGradientEnd.cgColor
            ]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        } else {
            // Неактивна пара - сірий фон
            gradientLayer.colors = [
                theme.cardBackgroundColor.cgColor,
                theme.secondaryCardBackgroundColor.cgColor
            ]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            lessonView.layer.borderColor = theme.separatorColor.cgColor
            lessonView.layer.borderWidth = 1
        }
        
        lessonView.layer.insertSublayer(gradientLayer, at: 0)
        
        // Кольори тексту: НОВА ЛОГІКА
        let textColor: UIColor = lesson.isActiveThisWeek ? .white : theme.textColor
        let titleColor: UIColor = lesson.isActiveThisWeek ? .white : theme.accentColor
        
        // Основний контейнер
        let contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        lessonView.addSubview(contentContainer)
        
        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: lessonView.topAnchor, constant: 12),
            contentContainer.leadingAnchor.constraint(equalTo: lessonView.leadingAnchor, constant: 12),
            contentContainer.trailingAnchor.constraint(equalTo: lessonView.trailingAnchor, constant: -12),
            contentContainer.bottomAnchor.constraint(equalTo: lessonView.bottomAnchor, constant: -12)
        ])
        
        // Вертикальний стек
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.distribution = .fill
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])
        
        // 1. Назва предмету
        let nameLabel = UILabel()
        nameLabel.text = lesson.name.isEmpty ? "Невідомо" : lesson.name
        nameLabel.font = .systemFont(ofSize: isFullWidth ? 15 : 14, weight: .bold)
        nameLabel.textColor = titleColor
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 0
        nameLabel.lineBreakMode = .byWordWrapping
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(nameLabel)
        
        // 2. Викладач
        var cleanText = lesson.teacher
            .replacingOccurrences(of: "<br />", with: " ")
            .replacingOccurrences(of: "<br>", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !isFullWidth {
            cleanText = cleanText
                .replacingOccurrences(of: ", підгрупа 1", with: "")
                .replacingOccurrences(of: ", підгрупа 2", with: "")
        }
        
        if cleanText.isEmpty {
            cleanText = "Викладач не вказаний"
        }
        
        let teacherLabel = UILabel()
        teacherLabel.text = cleanText
        teacherLabel.font = .systemFont(ofSize: isFullWidth ? 13 : 12, weight: .medium)
        teacherLabel.textColor = textColor
        teacherLabel.textAlignment = .center
        teacherLabel.numberOfLines = 0
        teacherLabel.lineBreakMode = .byWordWrapping
        teacherLabel.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(teacherLabel)
        
        // 3. Аудиторія та тип
        var roomTypeText = ""
        if !lesson.room.isEmpty && !lesson.type.isEmpty {
            roomTypeText = "\(lesson.room), \(lesson.type)"
        } else if !lesson.room.isEmpty {
            roomTypeText = lesson.room
        } else if !lesson.type.isEmpty {
            roomTypeText = lesson.type
        }
        
        if !roomTypeText.isEmpty {
            let roomTypeLabel = UILabel()
            roomTypeLabel.text = roomTypeText
            roomTypeLabel.font = .systemFont(ofSize: isFullWidth ? 12 : 11, weight: .medium)
            roomTypeLabel.textColor = textColor.withAlphaComponent(0.8)
            roomTypeLabel.textAlignment = .center
            roomTypeLabel.numberOfLines = 0
            roomTypeLabel.lineBreakMode = .byWordWrapping
            roomTypeLabel.translatesAutoresizingMaskIntoConstraints = false
            mainStack.addArrangedSubview(roomTypeLabel)
        }
        
        // 4. URL кнопка
        if let urlString = lesson.url, !urlString.isEmpty, let url = URL(string: urlString) {
            lessonURLs.append(url)
            
            let urlButton = UIButton(type: .system)
            urlButton.translatesAutoresizingMaskIntoConstraints = false
            urlButton.setTitle(isFullWidth ? "URL онлайн-заняття" : "Посилання", for: .normal)
            urlButton.titleLabel?.font = .systemFont(ofSize: isFullWidth ? 13 : 12, weight: .semibold)
            
            if lesson.isActiveThisWeek {
                urlButton.setTitleColor(.white, for: .normal)
                urlButton.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
                urlButton.tintColor = .white
            } else {
                urlButton.setTitleColor(theme.accentColor, for: .normal)
                urlButton.backgroundColor = theme.secondaryTextColor.withAlphaComponent(0.2)
                urlButton.tintColor = theme.accentColor
            }
            
            urlButton.layer.cornerRadius = 8
            urlButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            
            if let linkImage = UIImage(systemName: "link") {
                urlButton.setImage(linkImage, for: .normal)
                urlButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
                       }
                       
                       urlButton.tag = lessonViews.count
                       urlButton.addTarget(self, action: #selector(urlButtonTapped(_:)), for: .touchUpInside)
                       
                       mainStack.addArrangedSubview(urlButton)
                       lessonURLButtons.append(urlButton)
                       
                       urlButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
                   } else if hasExtraSpaceForURL {
                       let spacerView = UIView()
                       spacerView.backgroundColor = .clear
                       spacerView.translatesAutoresizingMaskIntoConstraints = false
                       mainStack.addArrangedSubview(spacerView)
                       spacerView.heightAnchor.constraint(equalToConstant: 32).isActive = true
                   }
                   
                   lessonViews.append(lessonView)
                   
                   // Оновлюємо градієнт
                   DispatchQueue.main.async {
                       gradientLayer.frame = lessonView.bounds
                   }
                   
                   return lessonView
               }
               
               @objc private func urlButtonTapped(_ sender: UIButton) {
                   let index = sender.tag
                   if index >= 0 && index < self.lessonURLs.count {
                       UIApplication.shared.open(self.lessonURLs[index])
                   }
               }
                   
               private func clearLessons() {
                   for view in lessonViews {
                       view.removeFromSuperview()
                   }
                   
                   for button in lessonURLButtons {
                       button.removeTarget(nil, action: nil, for: .allEvents)
                       button.removeFromSuperview()
                   }
                   
                   lessonViews.removeAll()
                   lessonURLButtons.removeAll()
                   lessonURLs.removeAll()
                   
                   for subview in lessonsContainerView.subviews {
                       if subview is UIStackView {
                           for stackSubview in subview.subviews {
                               stackSubview.removeFromSuperview()
                           }
                       }
                       subview.removeFromSuperview()
                   }
               }

               override func prepareForReuse() {
                   super.prepareForReuse()
                   clearLessons()
               }
               
               override func layoutSubviews() {
                   super.layoutSubviews()
                   
                   // Оновлюємо градієнти
                   for lessonView in lessonViews {
                       if let gradientLayer = lessonView.layer.sublayers?.first as? CAGradientLayer {
                           gradientLayer.frame = lessonView.bounds
                       }
                   }
               }
            }
