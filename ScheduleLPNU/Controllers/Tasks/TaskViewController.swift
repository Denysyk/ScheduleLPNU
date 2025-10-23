import UIKit

class TaskViewController: BaseFullScreenViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var emptyStateView: UIView!
    
    private var tasks: [Task] = []
    private var allTasks: [Task] = []
    private var filteredTasks: [Task] = []
    private var searchController: UISearchController!
    
    private var isSelectionMode = false
    private var selectedTaskIds = Set<String>()
    
    private var selectedCategory: Task.TaskCategory?
    private var showCompletedTasks = true
    
    enum SortOption: String, CaseIterable {
        case createdDate = "За датою створення"
        case dueDate = "За терміном виконання"
        case priority = "За пріоритетом"
        case alphabetical = "За алфавітом"
    }
    
    private var currentSortOption: SortOption = .createdDate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupSearchController()
        setupThemeObserver()
        loadTasks()
        applyTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTasks()
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
        tableView.backgroundColor = theme.backgroundColor
        
        emptyStateView.backgroundColor = .clear
        
        addButton.backgroundColor = theme.accentColor
        
        // ДОДАЙТЕ ЦЮ ЧАСТИНУ - оновлення кольорів навігаційних кнопок
        navigationController?.navigationBar.tintColor = theme.accentColor
        navigationItem.rightBarButtonItems?.forEach { barButton in
            barButton.tintColor = theme.accentColor
        }
        navigationItem.leftBarButtonItems?.forEach { barButton in
            barButton.tintColor = theme.accentColor
        }
        
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = theme.cardBackgroundColor
            textField.textColor = theme.textColor
        }
        
        tableView.reloadData()
    }
    
    private func setupUI() {
        title = "ЗАВДАННЯ"
        
        let theme = ThemeManager.shared
        
        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            style: .plain,
            target: self,
            action: #selector(showFilterOptions)
        )
        
        let sortButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down"),
            style: .plain,
            target: self,
            action: #selector(showSortOptions)
        )
        
        let selectButton = UIBarButtonItem(
            image: UIImage(systemName: "checkmark.circle"),
            style: .plain,
            target: self,
            action: #selector(toggleSelectionMode)
        )
        
        let statsButton = UIBarButtonItem(
            image: UIImage(systemName: "chart.bar"),
            style: .plain,
            target: self,
            action: #selector(showStatistics)
        )
        
        filterButton.tintColor = theme.accentColor
        sortButton.tintColor = theme.accentColor
        selectButton.tintColor = theme.accentColor
        statsButton.tintColor = theme.accentColor
        
        navigationItem.rightBarButtonItems = [selectButton, sortButton, filterButton]
        navigationItem.leftBarButtonItems = [statsButton]
        
        addButton.layer.cornerRadius = 28
        addButton.layer.shadowColor = theme.accentColor.cgColor
        addButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        addButton.layer.shadowRadius = 8
        addButton.layer.shadowOpacity = 0.3
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Пошук завдань..."
        searchController.searchBar.tintColor = theme.accentColor
        
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = theme.cardBackgroundColor
            textField.textColor = theme.textColor
        }
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(TaskTableViewCell.self, forCellReuseIdentifier: "TaskCell")
    }
    
    // MARK: - Data Management
    
    private func loadTasks() {
        tasks = TaskManager.shared.loadTasks()
        allTasks = tasks
        applyFilter()
        updateUI()
        updateApplicationBadge()
    }
    
    private func updateApplicationBadge() {
        let calendar = Calendar.current
        let todayTasksCount = allTasks.filter { task in
            guard let dueDate = task.dueDate, !task.isCompleted else { return false }
            return calendar.isDateInToday(dueDate)
        }.count
        
        UIApplication.shared.applicationIconBadgeNumber = todayTasksCount
    }
    
    private func applyFilter() {
        var tasksToShow: [Task]
        
        if let searchText = searchController?.searchBar.text, !searchText.isEmpty {
            tasksToShow = allTasks.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.description?.localizedCaseInsensitiveContains(searchText) == true ||
                task.associatedSchedule?.localizedCaseInsensitiveContains(searchText) == true ||
                task.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        } else {
            tasksToShow = allTasks
        }
        
        if let category = selectedCategory {
            tasksToShow = tasksToShow.filter { $0.category == category }
        }
        
        if !showCompletedTasks {
            tasksToShow = tasksToShow.filter { !$0.isCompleted }
        }
        
        filteredTasks = applySorting(to: tasksToShow)
    }
    
    private func applySorting(to tasks: [Task]) -> [Task] {
        let completedTasks = tasks.filter { $0.isCompleted }
        let incompleteTasks = tasks.filter { !$0.isCompleted }
        
        let sortedIncomplete: [Task]
        let sortedCompleted: [Task]
        
        switch currentSortOption {
        case .createdDate:
            sortedIncomplete = incompleteTasks.sorted { $0.createdDate > $1.createdDate }
            sortedCompleted = completedTasks.sorted { $0.createdDate > $1.createdDate }
        case .dueDate:
            sortedIncomplete = incompleteTasks.sorted { task1, task2 in
                switch (task1.dueDate, task2.dueDate) {
                case (nil, nil): return task1.createdDate > task2.createdDate
                case (nil, _): return false
                case (_, nil): return true
                case (let date1?, let date2?): return date1 < date2
                }
            }
            sortedCompleted = completedTasks.sorted { task1, task2 in
                switch (task1.dueDate, task2.dueDate) {
                case (nil, nil): return task1.createdDate > task2.createdDate
                case (nil, _): return false
                case (_, nil): return true
                case (let date1?, let date2?): return date1 < date2
                }
            }
        case .priority:
            sortedIncomplete = incompleteTasks.sorted { task1, task2 in
                let priority1 = getPriorityValue(task1.priority)
                let priority2 = getPriorityValue(task2.priority)
                if priority1 == priority2 {
                    return task1.createdDate > task2.createdDate
                }
                return priority1 > priority2
            }
            sortedCompleted = completedTasks.sorted { task1, task2 in
                let priority1 = getPriorityValue(task1.priority)
                let priority2 = getPriorityValue(task2.priority)
                if priority1 == priority2 {
                    return task1.createdDate > task2.createdDate
                }
                return priority1 > priority2
            }
        case .alphabetical:
            sortedIncomplete = incompleteTasks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            sortedCompleted = completedTasks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
        
        return sortedIncomplete + sortedCompleted
    }

    private func getPriorityValue(_ priority: Task.TaskPriority) -> Int {
        switch priority {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    private func updateUI() {
        if filteredTasks.isEmpty {
            tableView.isHidden = true
            emptyStateView.isHidden = false
            
            setupEmptyState()
        } else {
            tableView.isHidden = false
            emptyStateView.isHidden = true
            tableView.reloadData()
        }
    }
    
    // ВИПРАВЛЕННЯ 1: Empty State без білої рамки
    private func setupEmptyState() {
        let theme = ThemeManager.shared
        
        // Видаляємо старі subviews
        emptyStateView.subviews.forEach { $0.removeFromSuperview() }
        
        // ВИПРАВЛЕНО: прибираємо backgroundColor
        emptyStateView.backgroundColor = .clear
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(stackView)
        
        // Іконка
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let iconImageView = UIImageView(image: UIImage(systemName: "list.bullet.clipboard"))
        iconImageView.tintColor = theme.secondaryTextColor.withAlphaComponent(0.4)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconImageView)
        
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 100),
            iconImageView.heightAnchor.constraint(equalToConstant: 100),
            iconContainer.widthAnchor.constraint(equalToConstant: 120),
            iconContainer.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        // Заголовок
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = theme.secondaryTextColor
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        // Підзаголовок
        let subtitleLabel = UILabel()
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.textColor = theme.secondaryTextColor.withAlphaComponent(0.7)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        if let searchText = searchController?.searchBar.text, !searchText.isEmpty {
            titleLabel.text = "Нічого не знайдено"
            subtitleLabel.text = "Спробуйте змінити запит пошуку"
        } else if selectedCategory != nil {
            titleLabel.text = "Список порожній"
            subtitleLabel.text = "У цій категорії ще немає завдань"
        } else {
            titleLabel.text = "Список завдань пустий"
            subtitleLabel.text = "Натисніть + щоб додати нове завдання\nта почати організовувати свій день"
        }
        
        stackView.addArrangedSubview(iconContainer)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: emptyStateView.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: emptyStateView.trailingAnchor, constant: -40)
        ])
    }
    
    private func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Пошук завдань..."
        searchController.searchBar.tintColor = ThemeManager.shared.accentColor
        
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = ThemeManager.shared.cardBackgroundColor
            textField.textColor = ThemeManager.shared.textColor
        }
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    // MARK: - Selection Mode
    
    @objc private func toggleSelectionMode() {
        isSelectionMode.toggle()
        selectedTaskIds.removeAll()
        
        let theme = ThemeManager.shared
        
        if isSelectionMode {
            let cancelButton = UIBarButtonItem(title: "Скасувати", style: .plain, target: self, action: #selector(cancelSelection))
            let actionButton = UIBarButtonItem(title: "Дії", style: .done, target: self, action: #selector(showSelectionActions))
            
            cancelButton.tintColor = theme.accentColor
            actionButton.tintColor = theme.accentColor
            
            navigationItem.rightBarButtonItems = [actionButton]
            navigationItem.leftBarButtonItems = [cancelButton]
            
            title = "Виберіть завдання"
        } else {
            title = "ЗАВДАННЯ"
            setupUI()
        }
        
        tableView.allowsMultipleSelection = isSelectionMode
        tableView.reloadData()
    }

    @objc private func cancelSelection() {
        toggleSelectionMode()
    }

    @objc private func showSelectionActions() {
        let selectedCount = selectedTaskIds.count
        
        if selectedCount == 0 {
            let alert = UIAlertController(title: "Швидкий вибір", message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Вибрати всі", style: .default) { [weak self] _ in
                self?.selectedTaskIds = Set(self?.filteredTasks.map { $0.id } ?? [])
                self?.tableView.reloadData()
            })
            
            alert.addAction(UIAlertAction(title: "Вибрати не виконані", style: .default) { [weak self] _ in
                self?.selectedTaskIds = Set(self?.filteredTasks.filter { !$0.isCompleted }.map { $0.id } ?? [])
                self?.tableView.reloadData()
            })
            
            alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
            
            if let popover = alert.popoverPresentationController {
                popover.barButtonItem = navigationItem.rightBarButtonItems?.first
            }
            
            present(alert, animated: true)
            return
        }
        
        let alert = UIAlertController(
            title: "Дії з \(selectedCount) завданнями",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Позначити виконаними", style: .default) { [weak self] _ in
            self?.completeSelectedTasks()
        })
        
        alert.addAction(UIAlertAction(title: "Позначити невиконаними", style: .default) { [weak self] _ in
            self?.uncompleteSelectedTasks()
        })
        
        alert.addAction(UIAlertAction(title: "Видалити", style: .destructive) { [weak self] _ in
            self?.showDeleteConfirmation()
        })
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.first
        }
        
        present(alert, animated: true)
    }

    private func completeSelectedTasks() {
        for taskId in selectedTaskIds {
            TaskManager.shared.completeTask(withId: taskId)
        }
        toggleSelectionMode()
        loadTasks()
    }

    private func uncompleteSelectedTasks() {
        for taskId in selectedTaskIds {
            TaskManager.shared.uncompleteTask(withId: taskId)
        }
        toggleSelectionMode()
        loadTasks()
    }

    private func showDeleteConfirmation() {
        let alert = UIAlertController(
            title: "Видалити завдання?",
            message: "Ви впевнені, що хочете видалити \(selectedTaskIds.count) завдань?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Видалити", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            for taskId in self.selectedTaskIds {
                NotificationManager.shared.cancelNotification(for: taskId)
                TaskManager.shared.deleteTask(withId: taskId)
            }
            
            self.toggleSelectionMode()
            self.loadTasks()
        })
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    
    @objc private func showSortOptions() {
        let alert = UIAlertController(title: "Сортування", message: "Поточне: \(currentSortOption.rawValue)", preferredStyle: .actionSheet)
        
        for sortOption in SortOption.allCases {
            let action = UIAlertAction(title: sortOption.rawValue, style: .default) { [weak self] _ in
                self?.currentSortOption = sortOption
                self?.applyFilter()
                self?.updateUI()
            }
            
            if sortOption == currentSortOption {
                action.setValue(UIImage(systemName: "checkmark"), forKey: "image")
            }
            
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        
        present(alert, animated: true)
    }
    
    @objc private func showFilterOptions() {
        let alert = UIAlertController(title: "Фільтри", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Показати всі завдання", style: .default) { [weak self] _ in
            self?.showCompletedTasks = true
            self?.selectedCategory = nil
            self?.applyFilter()
            self?.updateUI()
        })
        
        alert.addAction(UIAlertAction(title: "Тільки не виконані", style: .default) { [weak self] _ in
            self?.showCompletedTasks = false
            self?.selectedCategory = nil
            self?.applyFilter()
            self?.updateUI()
        })
        
        alert.addAction(UIAlertAction(title: "--- Категорії ---", style: .default) { _ in })
        
        for category in Task.TaskCategory.allCases {
            let action = UIAlertAction(title: "\(getCategoryEmoji(category)) \(category.rawValue)", style: .default) { [weak self] _ in
                self?.selectedCategory = category
                self?.showCompletedTasks = true
                self?.applyFilter()
                self?.updateUI()
            }
            
            if category == selectedCategory {
                action.setValue(UIImage(systemName: "checkmark"), forKey: "image")
            }
            
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?[2]
        }
        
        present(alert, animated: true)
    }
    
    private func getCategoryEmoji(_ category: Task.TaskCategory) -> String {
        switch category {
        case .work: return "💼"
        case .personal: return "👤"
        case .study: return "📚"
        case .health: return "❤️"
        case .shopping: return "🛒"
        case .other: return "📁"
        }
    }
    
    @objc private func showStatistics() {
        let statsVC = StatisticsViewController()
        navigationController?.pushViewController(statsVC, animated: true)
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        if let addTaskVC = storyboard?.instantiateViewController(withIdentifier: "AddTaskViewController") as? AddTaskViewController {
            navigationController?.pushViewController(addTaskVC, animated: true)
        }
    }
    
    private func showEditTaskViewController(task: Task) {
        if let editTaskVC = storyboard?.instantiateViewController(withIdentifier: "AddTaskViewController") as? AddTaskViewController {
            editTaskVC.taskToEdit = task
            navigationController?.pushViewController(editTaskVC, animated: true)
        }
    }
    
    private func toggleTaskCompletion(taskId: String) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            let wasCompleted = tasks[index].isCompleted
            
            if wasCompleted {
                TaskManager.shared.uncompleteTask(withId: taskId)
            } else {
                TaskManager.shared.completeTask(withId: taskId)
            }
            
            tasks[index].isCompleted = !wasCompleted
            if let allTasksIndex = allTasks.firstIndex(where: { $0.id == taskId }) {
                allTasks[allTasksIndex].isCompleted = !wasCompleted
            }
            
            applyFilter()
            updateApplicationBadge()
            
            if !wasCompleted {
                UIView.transition(with: tableView, duration: 0.3, options: .transitionCrossDissolve) {
                    self.tableView.reloadData()
                } completion: { _ in
                    if let newIndex = self.filteredTasks.firstIndex(where: { $0.id == taskId }) {
                        let indexPath = IndexPath(row: newIndex, section: 0)
                        self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                    }
                }
            } else {
                tableView.reloadData()
                
                if let newIndex = filteredTasks.firstIndex(where: { $0.id == taskId }) {
                    let indexPath = IndexPath(row: newIndex, section: 0)
                    tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                }
            }
        }
    }
    
    // MARK: - Calendar Integration

    private func addTaskToCalendar(task: Task) {
        print("🔵 Starting addTaskToCalendar for task: \(task.title)")
        
        let status = CalendarManager.shared.checkCalendarAuthorizationStatus()
        print("🔵 Current calendar status: \(status.rawValue)")
        
        switch status {
        case .notDetermined:
            print("🔵 Status is notDetermined - requesting access")
            // ВАЖЛИВО: Запитуємо дозвіл ПЕРЕД спробою додати
            CalendarManager.shared.requestCalendarAccess { [weak self] granted, error in
                print("🔵 Request result - granted: \(granted), error: \(String(describing: error))")
                
                if granted {
                    // Тільки після отримання дозволу додаємо в календар
                    self?.performAddToCalendar(task: task)
                } else {
                    self?.showCalendarPermissionAlert()
                }
            }
            
        case .authorized:
            print("🔵 Status is authorized (iOS <17)")
            performAddToCalendar(task: task)
            
        case .fullAccess:
            print("🔵 Status is fullAccess (iOS 17+)")
            performAddToCalendar(task: task)
            
        case .writeOnly:
            print("🔵 Status is writeOnly (iOS 17+)")
            performAddToCalendar(task: task)
            
        case .denied, .restricted:
            print("🔵 Status is denied/restricted")
            showCalendarPermissionAlert()
            
        @unknown default:
            print("🔵 Unknown status")
            showCalendarPermissionAlert()
        }
    }

    private func performAddToCalendar(task: Task) {
        print("🔵 Performing add to calendar for task: \(task.title)")
        
        TaskManager.shared.addTaskToCalendar(taskId: task.id) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ Successfully added to calendar")
                    self?.showToast(message: "✅ Додано в календар")
                    self?.loadTasks()
                } else {
                    print("❌ Failed to add to calendar: \(error ?? "Unknown error")")
                    
                    let errorMessage = error ?? "Невідома помилка"
                    self?.showToast(message: "❌ Помилка: \(errorMessage)")
                }
            }
        }
    }
    
    private func removeTaskFromCalendar(task: Task) {
        TaskManager.shared.removeTaskFromCalendar(taskId: task.id) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.showToast(message: "✅ Видалено з календаря")
                    self?.loadTasks()
                } else {
                    self?.showToast(message: "❌ Помилка видалення")
                }
            }
        }
    }
    
    private func showCalendarPermissionAlert() {
        let alert = UIAlertController(
            title: "Доступ до календаря",
            message: "Для синхронізації завдань з календарем потрібен доступ. Увімкніть його в Налаштуваннях.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Налаштування", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showToast(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}

// MARK: - UISearchResultsUpdating
extension TaskViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applyFilter()
        updateUI()
    }
}

// MARK: - UITableViewDataSource
extension TaskViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < filteredTasks.count else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskTableViewCell
        let task = filteredTasks[indexPath.row]
        
        cell.configure(with: task)
        cell.onCompletionToggle = { [weak self] taskId in
            if self?.isSelectionMode == true {
                if self?.selectedTaskIds.contains(taskId) == true {
                    self?.selectedTaskIds.remove(taskId)
                } else {
                    self?.selectedTaskIds.insert(taskId)
                }
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            } else {
                self?.toggleTaskCompletion(taskId: taskId)
            }
        }
        
        if isSelectionMode {
            cell.setSelectionMode(selectedTaskIds.contains(task.id))
            cell.accessoryType = .none
        } else {
            cell.setSelectionMode(false)
            cell.accessoryType = .none
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension TaskViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath.row < filteredTasks.count else {
            return
        }
        
        let task = filteredTasks[indexPath.row]
        
        if isSelectionMode {
            if selectedTaskIds.contains(task.id) {
                selectedTaskIds.remove(task.id)
            } else {
                selectedTaskIds.insert(task.id)
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } else {
            showEditTaskViewController(task: task)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard indexPath.row < filteredTasks.count else {
                return
            }
            
            let task = filteredTasks[indexPath.row]
            
            NotificationManager.shared.cancelNotification(for: task.id)
            TaskManager.shared.deleteTask(withId: task.id)
            loadTasks()
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard indexPath.row < filteredTasks.count else { return nil }
        let task = filteredTasks[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            var actions: [UIMenuElement] = []
            
            let editAction = UIAction(
                title: "Редагувати",
                image: UIImage(systemName: "pencil")
            ) { _ in
                self?.showEditTaskViewController(task: task)
            }
            actions.append(editAction)
            
            // Календар
            if task.dueDate != nil {
                if task.isInCalendar {
                    let removeFromCalendarAction = UIAction(
                        title: "Видалити з календаря",
                        image: UIImage(systemName: "calendar.badge.minus"),
                        attributes: []
                    ) { [weak self] _ in
                        self?.removeTaskFromCalendar(task: task)
                    }
                    actions.append(removeFromCalendarAction)
                } else {
                    let addToCalendarAction = UIAction(
                        title: "Додати в календар",
                        image: UIImage(systemName: "calendar.badge.plus")
                    ) { [weak self] _ in
                        self?.addTaskToCalendar(task: task)
                    }
                    actions.append(addToCalendarAction)
                }
            }
            
            let completionTitle = task.isCompleted ? "Позначити невиконаним" : "Позначити виконаним"
            let completionIcon = task.isCompleted ? "circle" : "checkmark.circle.fill"
            let completionAction = UIAction(
                title: completionTitle,
                image: UIImage(systemName: completionIcon)
            ) { [weak self] _ in
                self?.toggleTaskCompletion(taskId: task.id)
            }
            actions.append(completionAction)
            
            let deleteAction = UIAction(
                title: "Видалити",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { [weak self] _ in
                NotificationManager.shared.cancelNotification(for: task.id)
                TaskManager.shared.deleteTask(withId: task.id)
                self?.loadTasks()
            }
            actions.append(deleteAction)
            
            return UIMenu(title: "", children: actions)
        }
    }
}
