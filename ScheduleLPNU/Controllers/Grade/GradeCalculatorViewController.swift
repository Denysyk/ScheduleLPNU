import UIKit

class GradeCalculatorViewController: UIViewController {
    
    // UI елементи (програмно)
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var statsContainerView: UIView!
    private var gpaLabel: UILabel!
    private var totalCreditsLabel: UILabel!
    private var completedSubjectsLabel: UILabel!
    private var tableView: UITableView!
    private var emptyStateView: UIView!
    private var emptyStateLabel: UILabel!
    
    private var grades: [SubjectGrade] = []
    private var tableViewHeightConstraint: NSLayoutConstraint?
    private var tableViewBottomConstraint: NSLayoutConstraint?
    private var emptyStateBottomConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupThemeObserver()
        applyTheme()
        loadGrades()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadGrades()
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
        
        // Додаємо спостерігача для оновлення списку оцінок
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(gradesDidUpdate),
            name: NSNotification.Name("GradeWasAdded"),
            object: nil
        )
    }
    
    @objc private func gradesDidUpdate() {
        // Оновлюємо дані одразу після додавання/редагування/видалення
        loadGrades()
    }
    
    @objc private func themeDidChange() {
        applyTheme()
    }
    
    private func applyTheme() {
        let theme = ThemeManager.shared
        
        view.backgroundColor = theme.backgroundColor
        
        // Navigation Bar
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: theme.accentColor,
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)
        ]
        navigationController?.navigationBar.tintColor = theme.accentColor
        
        // Scroll view
        scrollView.backgroundColor = theme.backgroundColor
        contentView.backgroundColor = theme.backgroundColor
        
        // Stats container
        statsContainerView.backgroundColor = theme.cardBackgroundColor
        
        // Stats labels
        gpaLabel.textColor = theme.accentColor
        totalCreditsLabel.textColor = theme.textColor
        completedSubjectsLabel.textColor = theme.textColor
        
        // Table view
        tableView.backgroundColor = theme.backgroundColor
        
        // Empty state
        emptyStateView.backgroundColor = theme.backgroundColor
        emptyStateLabel.textColor = theme.secondaryTextColor
        
        tableView.reloadData()
    }
    
    private func setupUI() {
        title = "СЕРЕДНІЙ БАЛ"
        
        // Add button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addGradeTapped)
        )
        
        // Scroll view
        scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        // Content view
        contentView = UIView()
        scrollView.addSubview(contentView)
        
        // Stats container
        createStatsSection()
        
        // Table view
        createTableView()
        
        // Empty state
        createEmptyState()
    }
    
    private func createStatsSection() {
        statsContainerView = UIView()
        statsContainerView.layer.cornerRadius = 16
        statsContainerView.layer.shadowColor = UIColor.black.cgColor
        statsContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        statsContainerView.layer.shadowOpacity = 0.08
        statsContainerView.layer.shadowRadius = 6
        contentView.addSubview(statsContainerView)
        
        // GPA Section
        let gpaContainerView = UIView()
        statsContainerView.addSubview(gpaContainerView)
        
        let gpaTitle = UILabel()
        gpaTitle.text = "Середній бал"
        gpaTitle.font = .systemFont(ofSize: 16, weight: .medium)
        gpaContainerView.addSubview(gpaTitle)
        
        gpaLabel = UILabel()
        gpaLabel.text = "0.00"
        gpaLabel.font = .systemFont(ofSize: 36, weight: .bold)
        gpaLabel.textAlignment = .center
        gpaContainerView.addSubview(gpaLabel)
        
        // Stats Section
        let statsStackView = UIStackView()
        statsStackView.axis = .vertical
        statsStackView.spacing = 8
        statsStackView.distribution = .fillEqually
        statsContainerView.addSubview(statsStackView)
        
        totalCreditsLabel = UILabel()
        totalCreditsLabel.text = "Загальна кількість кредитів: 0"
        totalCreditsLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statsStackView.addArrangedSubview(totalCreditsLabel)
        
        completedSubjectsLabel = UILabel()
        completedSubjectsLabel.text = "Завершених предметів: 0"
        completedSubjectsLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statsStackView.addArrangedSubview(completedSubjectsLabel)
        
        // Constraints for stats section
        [gpaContainerView, gpaTitle, gpaLabel, statsStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            gpaContainerView.topAnchor.constraint(equalTo: statsContainerView.topAnchor, constant: 20),
            gpaContainerView.leadingAnchor.constraint(equalTo: statsContainerView.leadingAnchor, constant: 20),
            gpaContainerView.trailingAnchor.constraint(equalTo: statsContainerView.trailingAnchor, constant: -20),
            gpaContainerView.heightAnchor.constraint(equalToConstant: 80),
            
            gpaTitle.topAnchor.constraint(equalTo: gpaContainerView.topAnchor),
            gpaTitle.centerXAnchor.constraint(equalTo: gpaContainerView.centerXAnchor),
            
            gpaLabel.bottomAnchor.constraint(equalTo: gpaContainerView.bottomAnchor),
            gpaLabel.centerXAnchor.constraint(equalTo: gpaContainerView.centerXAnchor),
            
            statsStackView.topAnchor.constraint(equalTo: gpaContainerView.bottomAnchor, constant: 16),
            statsStackView.leadingAnchor.constraint(equalTo: statsContainerView.leadingAnchor, constant: 20),
            statsStackView.trailingAnchor.constraint(equalTo: statsContainerView.trailingAnchor, constant: -20),
            statsStackView.bottomAnchor.constraint(equalTo: statsContainerView.bottomAnchor, constant: -20),
            statsStackView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func createTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.isScrollEnabled = false // Вимикаємо власний скрол таблиці
        tableView.bounces = false
        
        // Register custom cell
        tableView.register(SubjectGradeTableViewCell.self, forCellReuseIdentifier: "SubjectGradeCell")
        
        contentView.addSubview(tableView)
    }
    
    private func createEmptyState() {
        emptyStateView = UIView()
        emptyStateView.backgroundColor = .clear
        emptyStateView.isHidden = true
        contentView.addSubview(emptyStateView)
        
        let iconView = UIImageView(image: UIImage(systemName: "chart.bar.doc.horizontal"))
        iconView.contentMode = .scaleAspectFit
        iconView.alpha = 0.3
        emptyStateView.addSubview(iconView)
        
        emptyStateLabel = UILabel()
        emptyStateLabel.text = "Список порожній\nДодайте предмети для обрахунку середнього балу"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
        emptyStateView.addSubview(emptyStateLabel)
        
        let addButton = UIButton(type: .system)
        addButton.setTitle("Додати предмет", for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        addButton.layer.cornerRadius = 12
        addButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        addButton.addTarget(self, action: #selector(addGradeTapped), for: .touchUpInside)
        emptyStateView.addSubview(addButton)
        
        [iconView, emptyStateLabel, addButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            iconView.topAnchor.constraint(equalTo: emptyStateView.topAnchor, constant: 40),
            iconView.widthAnchor.constraint(equalToConstant: 80),
            iconView.heightAnchor.constraint(equalToConstant: 80),
            
            emptyStateLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 20),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -40),
            
            addButton.topAnchor.constraint(equalTo: emptyStateLabel.bottomAnchor, constant: 24),
            addButton.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            addButton.bottomAnchor.constraint(lessThanOrEqualTo: emptyStateView.bottomAnchor, constant: -40)
        ])
        
        // Apply theme to empty state button
        DispatchQueue.main.async {
            let theme = ThemeManager.shared
            iconView.tintColor = theme.secondaryTextColor
            addButton.backgroundColor = theme.accentColor
            addButton.setTitleColor(.white, for: .normal)
        }
    }
    
    private func setupConstraints() {
        [scrollView, contentView, statsContainerView, tableView, emptyStateView].forEach {
            $0?.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // Scroll view - прив'язуємо до safe area
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Stats container
            statsContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            statsContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsContainerView.heightAnchor.constraint(equalToConstant: 164),
            
            // Table view - базові constraints
            tableView.topAnchor.constraint(equalTo: statsContainerView.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Empty state view - базові constraints
            emptyStateView.topAnchor.constraint(equalTo: statsContainerView.bottomAnchor, constant: 16),
            emptyStateView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            emptyStateView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300)
        ])
        
        // Створюємо constraint для висоти таблиці
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableViewHeightConstraint?.isActive = true
        
        // Створюємо constraints для нижньої частини (спочатку неактивні)
        tableViewBottomConstraint = tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        emptyStateBottomConstraint = emptyStateView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        
        // Додаємо constraint для мінімальної висоти content view
        let contentHeightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor)
        contentHeightConstraint.priority = UILayoutPriority(250)
        contentHeightConstraint.isActive = true
    }
    
    @objc private func addGradeTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let addVC = storyboard.instantiateViewController(withIdentifier: "AddSubjectGradeViewController") as? AddSubjectGradeViewController {
            let navController = UINavigationController(rootViewController: addVC)
            present(navController, animated: true)
        }
    }
    
    private func loadGrades() {
        grades = GradeManager.shared.loadGrades()
        updateStatistics()
        updateUI()
    }
    
    private func updateStatistics() {
        let stats = GradeManager.shared.getGradeStatistics()
        
        // Показуємо 100-бальну шкалу з 4 знаками після коми
        gpaLabel.text = String(format: "%.4f", stats.gpa)
        totalCreditsLabel.text = "Загальна кількість кредитів: \(stats.totalCredits)"
        
        // Для 5-бальної системи відкидаємо все після першого знаку після коми
        let gpa5Truncated = floor(stats.gpa5Scale * 10) / 10
        completedSubjectsLabel.text = "Завершених предметів: \(stats.completedSubjects) • 5-бальна: \(String(format: "%.1f", gpa5Truncated))"
    }
    
    private func updateUI() {
        // Спочатку деактивуємо всі bottom constraints
        tableViewBottomConstraint?.isActive = false
        emptyStateBottomConstraint?.isActive = false
        
        if grades.isEmpty {
            // Показуємо empty state
            tableView.isHidden = true
            emptyStateView.isHidden = false
            
            // Налаштовуємо constraints для empty state
            tableViewHeightConstraint?.constant = 0
            emptyStateBottomConstraint?.isActive = true
        } else {
            // Показуємо таблицю
            tableView.isHidden = false
            emptyStateView.isHidden = true
            
            // Обчислюємо висоту таблиці
            let rowHeight: CGFloat = 86
            let totalHeight = CGFloat(grades.count) * rowHeight
            tableViewHeightConstraint?.constant = totalHeight
            
            // Активуємо constraint для нижньої частини таблиці
            tableViewBottomConstraint?.isActive = true
            
            tableView.reloadData()
        }
        
        // Примусово оновлюємо layout
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // Оновлюємо scroll view content size
        DispatchQueue.main.async {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
    
    private func deleteGrade(at indexPath: IndexPath) {
        let grade = grades[indexPath.row]
        
        let alert = UIAlertController(
            title: "Видалити предмет",
            message: "Ви впевнені, що хочете видалити \(grade.name)?",
            preferredStyle: .alert
        )
        alert.view.tintColor = ThemeManager.shared.accentColor
        
        alert.addAction(UIAlertAction(title: "Видалити", style: .destructive) { [weak self] _ in
            GradeManager.shared.deleteGrade(withId: grade.id)
            self?.loadGrades()
        })
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func editGrade(at indexPath: IndexPath) {
        let grade = grades[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let editVC = storyboard.instantiateViewController(withIdentifier: "EditSubjectGradeViewController") as? EditSubjectGradeViewController {
            editVC.gradeToEdit = grade
            let navController = UINavigationController(rootViewController: editVC)
            present(navController, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource
extension GradeCalculatorViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return grades.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SubjectGradeCell", for: indexPath) as! SubjectGradeTableViewCell
        let grade = grades[indexPath.row]
        cell.configure(with: grade)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension GradeCalculatorViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 86
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        editGrade(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteGrade(at: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}
