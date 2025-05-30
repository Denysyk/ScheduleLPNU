import UIKit

class StatisticsViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupThemeObserver()
        applyTheme()
        loadStatistics()
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Застосовуємо тему кожного разу при появі контролера
        let theme = ThemeManager.shared
        navigationController?.navigationBar.tintColor = theme.accentColor
        
        loadStatistics()
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
        
        view.backgroundColor = theme.backgroundColor
        
        // Navigation Bar налаштування
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: theme.accentColor,
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)
        ]
        
        // Колір кнопки "Назад" та інших елементів навігації
        navigationController?.navigationBar.tintColor = theme.accentColor
        
        // Для iOS 15+ додаткові налаштування
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = theme.backgroundColor
            appearance.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: theme.accentColor,
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)
            ]
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            navigationController?.navigationBar.compactAppearance = appearance
        }
        
        // Reload statistics to apply theme to cards
        loadStatistics()
    }
    
    private func setupUI() {
        title = "СТАТИСТИКА"
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        
        NSLayoutConstraint.activate([
            // ВИПРАВЛЕНО: ScrollView прив'язуємо до safe area
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // ДОДАНО: Constraint для мінімальної висоти content view
        let contentHeightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor)
        contentHeightConstraint.priority = UILayoutPriority(250)
        contentHeightConstraint.isActive = true
    }
    
    private func loadStatistics() {
        let tasks = TaskManager.shared.loadTasks()
        let stats = TaskStatistics(tasks: tasks)
        
        // Clear existing views
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add statistics cards
        addOverviewCard(stats: stats)
        addProgressCard(stats: stats)
        addCategoryCard(stats: stats)
        addPriorityCard(stats: stats)
    }
    
    private func addOverviewCard(stats: TaskStatistics) {
        let card = createCard(title: "Загальна статистика")
        
        let totalLabel = createStatLabel(title: "Всього завдань", value: "\(stats.totalTasks)")
        let completedLabel = createStatLabel(title: "Виконано", value: "\(stats.completedTasks)")
        let pendingLabel = createStatLabel(title: "В процесі", value: "\(stats.pendingTasks)")
        
        card.addArrangedSubview(totalLabel)
        card.addArrangedSubview(completedLabel)
        card.addArrangedSubview(pendingLabel)
        
        stackView.addArrangedSubview(card)
    }
    
    private func addProgressCard(stats: TaskStatistics) {
        let card = createCard(title: "Прогрес")
        
        let completionLabel = createStatLabel(title: "Відсоток виконання", value: "\(String(format: "%.1f", stats.completionRate))%")
        let todayLabel = createStatLabel(title: "Завдань на сьогодні", value: "\(stats.todayTasks)")
        let weekLabel = createStatLabel(title: "Завдань на тиждень", value: "\(stats.thisWeekTasks)")
        
        card.addArrangedSubview(completionLabel)
        card.addArrangedSubview(todayLabel)
        card.addArrangedSubview(weekLabel)
        
        // Progress bar
        let progressContainer = UIView()
        let progressBar = UIProgressView(progressViewStyle: .default)
        progressBar.progress = Float(stats.completionRate / 100)
        progressBar.progressTintColor = ThemeManager.shared.accentColor
        
        progressContainer.addSubview(progressBar)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressBar.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: progressContainer.trailingAnchor),
            progressBar.centerYAnchor.constraint(equalTo: progressContainer.centerYAnchor),
            progressContainer.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        card.addArrangedSubview(progressContainer)
        stackView.addArrangedSubview(card)
    }
    
    private func addCategoryCard(stats: TaskStatistics) {
        let card = createCard(title: "За категоріями")
        
        for (category, count) in stats.categoryStats.sorted(by: { $0.value > $1.value }) {
            if count > 0 {
                let label = createStatLabel(title: category.rawValue, value: "\(count)", icon: category.icon)
                card.addArrangedSubview(label)
            }
        }
        
        stackView.addArrangedSubview(card)
    }
    
    private func addPriorityCard(stats: TaskStatistics) {
        let card = createCard(title: "За пріоритетом")
        
        for (priority, count) in stats.priorityStats.sorted(by: { getPriorityValue($0.key) > getPriorityValue($1.key) }) {
            if count > 0 {
                let label = createStatLabel(title: priority.rawValue, value: "\(count)")
                card.addArrangedSubview(label)
            }
        }
        
        stackView.addArrangedSubview(card)
    }
    
    private func createCard(title: String) -> UIStackView {
        let theme = ThemeManager.shared
        
        let container = UIView()
        container.backgroundColor = theme.cardBackgroundColor
        container.layer.cornerRadius = 12
        
        // Shadow only for light theme
        if !theme.isDarkMode {
            container.layer.shadowColor = UIColor.black.cgColor
            container.layer.shadowOffset = CGSize(width: 0, height: 2)
            container.layer.shadowRadius = 4
            container.layer.shadowOpacity = 0.08
        }
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = theme.accentColor
        
        container.addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        
        let wrapperStack = UIStackView()
        wrapperStack.addArrangedSubview(container)
        wrapperStack.axis = .vertical
        
        return stackView
    }
    
    private func createStatLabel(title: String, value: String, icon: String? = nil) -> UIView {
        let theme = ThemeManager.shared
        let container = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = theme.secondaryTextColor
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .boldSystemFont(ofSize: 16)
        valueLabel.textColor = theme.accentColor
        valueLabel.textAlignment = .right
        
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        
        if let iconName = icon {
            let iconView = UIImageView(image: UIImage(systemName: iconName))
            iconView.tintColor = theme.accentColor
            iconView.contentMode = .scaleAspectFit
            container.addSubview(iconView)
            
            iconView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 20),
                iconView.heightAnchor.constraint(equalToConstant: 20),
                titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8)
            ])
        } else {
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        }
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: valueLabel.leadingAnchor, constant: -8),
            
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            container.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return container
    }
    
    private func getPriorityValue(_ priority: Task.TaskPriority) -> Int {
        switch priority {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}
