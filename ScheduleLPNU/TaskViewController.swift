//
//  TaskViewController.swift
//  ScheduleLPNU
//
//  Created by Denys Brativnyk on 26.05.2025.
//

import UIKit

class TaskViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var emptyStateLabel: UILabel!
    
    private var tasks: [Task] = []
    private var filteredTasks: [Task] = []
    private var allTasks: [Task] = []
    private var showCompletedTasks = true
    private var currentSortOption: SortOption = .createdDate
    private var selectedCategory: Task.TaskCategory?
    private var searchController: UISearchController!
    
    // Змінні для множинного вибору
    private var isSelectionMode = false
    private var selectedTaskIds: Set<String> = []

    enum SortOption: String, CaseIterable {
        case createdDate = "За датою створення"
        case dueDate = "За датою виконання"
        case priority = "За пріоритетом"
        case alphabetical = "За алфавітом"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupThemeObserver()
        applyTheme()
        loadTasks()
        
        // Request notification permission
        NotificationManager.shared.requestPermission { granted in
            if granted {
                NotificationManager.shared.scheduleReminderNotifications()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTasks()
        applyTheme()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Очищуємо badge при відкритті програми
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
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
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        // Buttons in navigation bar
        navigationItem.leftBarButtonItems?.forEach { $0.tintColor = theme.accentColor }
        navigationItem.rightBarButtonItems?.forEach { $0.tintColor = theme.accentColor }
        
        // Add button
        addButton.backgroundColor = theme.accentColor
        
        // Table view
        tableView.backgroundColor = theme.backgroundColor
        
        // Empty state
        emptyStateView.backgroundColor = theme.backgroundColor
        emptyStateLabel.textColor = theme.secondaryTextColor
        
        // Search bar
        if let textField = searchController?.searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = theme.textColor
        }
        searchController?.searchBar.tintColor = theme.accentColor
        
        // Reload table to update cells
        tableView.reloadData()
    }
    
    private func setupUI() {
        // Простий заголовок
        title = "ЗАВДАННЯ"
        
        let theme = ThemeManager.shared
        
        // ЛІВА СТОРОНА: Фільтр + Множинний вибір
        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease"),
            style: .plain,
            target: self,
            action: #selector(showFilterOptions)
        )
        
        let selectButton = UIBarButtonItem(
            image: UIImage(systemName: "checkmark.square"),
            style: .plain,
            target: self,
            action: #selector(toggleSelectionMode)
        )
        
        filterButton.tintColor = theme.accentColor
        selectButton.tintColor = theme.accentColor
        navigationItem.leftBarButtonItems = [filterButton, selectButton]
        
        // ПРАВА СТОРОНА: Сортування + Статистика
        let sortButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down"),
            style: .plain,
            target: self,
            action: #selector(showSortOptions)
        )
        
        let statsButton = UIBarButtonItem(
            image: UIImage(systemName: "chart.bar"),
            style: .plain,
            target: self,
            action: #selector(showStatistics)
        )
        
        sortButton.tintColor = theme.accentColor
        statsButton.tintColor = theme.accentColor
        navigationItem.rightBarButtonItems = [statsButton, sortButton]
        
        // Setup add button
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = .white
        addButton.layer.cornerRadius = 30
        addButton.layer.shadowColor = UIColor.black.cgColor
        addButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        addButton.layer.shadowRadius = 8
        addButton.layer.shadowOpacity = 0.3
        
        // Empty state
        emptyStateLabel.text = "Список завдань пустий\nДодайте нове завдання натиснувши кнопку +"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
        
        // Setup search
        setupSearch()
    }
    
    private func setupSearch() {
        let theme = ThemeManager.shared
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Пошук завдань..."
        searchController.searchBar.tintColor = theme.accentColor
        
        // Стилізація search bar
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
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
        
        // Register custom cell
        tableView.register(TaskTableViewCell.self, forCellReuseIdentifier: "TaskCell")
    }
    
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
        
        // Спочатку застосовуємо пошук
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
        
        // Фільтруємо по категорії
        if let category = selectedCategory {
            tasksToShow = tasksToShow.filter { $0.category == category }
        }
        
        // Потім фільтруємо по статусу виконання
        if !showCompletedTasks {
            tasksToShow = tasksToShow.filter { !$0.isCompleted }
        }
        
        // Застосовуємо сортування
        filteredTasks = applySorting(to: tasksToShow)
    }
    
    private func applySorting(to tasks: [Task]) -> [Task] {
        // СПОЧАТКУ розділяємо на виконані та не виконані
        let completedTasks = tasks.filter { $0.isCompleted }
        let incompleteTasks = tasks.filter { !$0.isCompleted }
        
        // Сортуємо кожну групу окремо
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
        
        // АВТОМАТИЧНО: спочатку не виконані, потім виконані
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
            if let searchText = searchController?.searchBar.text, !searchText.isEmpty {
                emptyStateLabel.text = "Завдань за запитом '\(searchText)' не знайдено"
            } else if selectedCategory != nil {
                emptyStateLabel.text = "Завдань у цій категорії не знайдено"
            } else {
                emptyStateLabel.text = "Список завдань пустий\nДодайте нове завдання, натиснувши кнопку +"
            }
        } else {
            tableView.isHidden = false
            emptyStateView.isHidden = true
            tableView.reloadData()
        }
    }
    
    // МНОЖИННИЙ ВИБІР
    @objc private func toggleSelectionMode() {
        isSelectionMode.toggle()
        selectedTaskIds.removeAll()
        
        let theme = ThemeManager.shared
        
        if isSelectionMode {
            // В режимі вибору показуємо дії
            let cancelButton = UIBarButtonItem(title: "Скасувати", style: .plain, target: self, action: #selector(cancelSelection))
            let actionButton = UIBarButtonItem(title: "Дії", style: .done, target: self, action: #selector(showSelectionActions))
            
            cancelButton.tintColor = theme.accentColor
            actionButton.tintColor = theme.accentColor
            
            navigationItem.rightBarButtonItems = [actionButton]
            navigationItem.leftBarButtonItems = [cancelButton]
            
            title = "Виберіть завдання"
        } else {
            // Повертаємо звичайний інтерфейс
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
            // Швидкий вибір
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
            
            // Для iPad
            if let popover = alert.popoverPresentationController {
                popover.barButtonItem = navigationItem.rightBarButtonItems?.first
            }
            
            present(alert, animated: true)
        } else {
            // Дії з вибраними
            let alert = UIAlertController(title: "Дії з вибраними (\(selectedCount))", message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "✅ Позначити як виконані", style: .default) { [weak self] _ in
                self?.markSelectedTasks(completed: true)
            })
            
            alert.addAction(UIAlertAction(title: "◯ Позначити як не виконані", style: .default) { [weak self] _ in
                self?.markSelectedTasks(completed: false)
            })
            
            alert.addAction(UIAlertAction(title: "🗑 Видалити", style: .destructive) { [weak self] _ in
                self?.deleteSelectedTasks()
            })
            
            alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
            
            // Для iPad
            if let popover = alert.popoverPresentationController {
                popover.barButtonItem = navigationItem.rightBarButtonItems?.first
            }
            
            present(alert, animated: true)
        }
    }
    
    // ВИПРАВЛЕНО: Безпечне позначення завдань
    private func markSelectedTasks(completed: Bool) {
        for taskId in selectedTaskIds {
            if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                tasks[index].isCompleted = completed
                TaskManager.shared.updateTask(tasks[index])
            }
        }
        
        toggleSelectionMode()
        
        // НАЙПРОСТІШЕ: Повністю перезавантажуємо все
        loadTasks()
    }

    // ВИПРАВЛЕНО: Безпечне видалення завдань
    private func deleteSelectedTasks() {
        let alert = UIAlertController(title: "Видалити завдання", message: "Видалити \(selectedTaskIds.count) завдань?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Видалити", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // Видаляємо завдання
            for taskId in self.selectedTaskIds {
                NotificationManager.shared.cancelNotification(for: taskId)
                TaskManager.shared.deleteTask(withId: taskId)
            }
            
            // Вимикаємо режим вибору
            self.toggleSelectionMode()
            
            // НАЙПРОСТІШЕ: Повністю перезавантажуємо все
            self.loadTasks()
        })
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }
    
    // СОРТУВАННЯ - окрема кнопка
    @objc private func showSortOptions() {
        let alert = UIAlertController(title: "Сортування", message: "Поточне: \(currentSortOption.rawValue)", preferredStyle: .actionSheet)
        
        for sortOption in SortOption.allCases {
            let action = UIAlertAction(title: sortOption.rawValue, style: .default) { [weak self] _ in
                self?.currentSortOption = sortOption
                self?.applyFilter()
                self?.updateUI()
            }
            
            // Відмічаємо поточну опцію
            if sortOption == currentSortOption {
                action.setValue(UIImage(systemName: "checkmark"), forKey: "image")
            }
            
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        // Для iPad
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        
        present(alert, animated: true)
    }
    
    // ФІЛЬТРИ - окрема кнопка
    @objc private func showFilterOptions() {
        let alert = UIAlertController(title: "Фільтри", message: nil, preferredStyle: .actionSheet)
        
        // Статус завдань
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
        
        // Роздільник
        alert.addAction(UIAlertAction(title: "--- Категорії ---", style: .default) { _ in })
        
        // Категорії
        for category in Task.TaskCategory.allCases {
            let action = UIAlertAction(title: "\(getCategoryEmoji(category)) \(category.rawValue)", style: .default) { [weak self] _ in
                self?.selectedCategory = category
                self?.showCompletedTasks = true
                self?.applyFilter()
                self?.updateUI()
            }
            
            // Відмічаємо вибрану категорію
            if category == selectedCategory {
                action.setValue(UIImage(systemName: "checkmark"), forKey: "image")
            }
            
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        // Для iPad
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.leftBarButtonItems?.first
        }
        
        present(alert, animated: true)
    }
    
    private func getCategoryEmoji(_ category: Task.TaskCategory) -> String {
        switch category {
        case .personal: return "👤"
        case .work: return "💼"
        case .study: return "📚"
        case .health: return "❤️"
        case .shopping: return "🛒"
        case .other: return "📁"
        }
    }
    
    @objc private func showStatistics() {
        let statisticsVC = StatisticsViewController()
        navigationController?.pushViewController(statisticsVC, animated: true)
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        // Animate button
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                sender.transform = CGAffineTransform.identity
            }
        }
        
        // Show add task controller
        performSegue(withIdentifier: "showAddTask", sender: self)
    }
    
    private func showEditTaskViewController(task: Task) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let editTaskVC = storyboard.instantiateViewController(withIdentifier: "AddTaskViewController") as? AddTaskViewController {
            editTaskVC.taskToEdit = task
            navigationController?.pushViewController(editTaskVC, animated: true)
        }
    }
    
    // ВИПРАВЛЕНО: Безпечне перемикання статусу завдання
    private func toggleTaskCompletion(taskId: String) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[index].isCompleted.toggle()
            TaskManager.shared.updateTask(tasks[index])
            
            if let allTasksIndex = allTasks.firstIndex(where: { $0.id == taskId }) {
                allTasks[allTasksIndex].isCompleted.toggle()
            }
            
            // ОНОВЛЕНО: Плавна анімація переміщення
            let wasCompleted = !tasks[index].isCompleted // інвертуємо, бо вже змінили
            
            applyFilter()
            updateApplicationBadge()
            
            if wasCompleted {
                // Завдання стало не виконаним - переміщуємо вгору
                tableView.reloadData()
                
                // Прокручуємо до нового положення
                if let newIndex = filteredTasks.firstIndex(where: { $0.id == taskId }) {
                    let indexPath = IndexPath(row: newIndex, section: 0)
                    tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                }
            } else {
                // Завдання стало виконаним - переміщуємо вниз
                UIView.transition(with: tableView, duration: 0.3, options: .transitionCrossDissolve) {
                    self.tableView.reloadData()
                } completion: { _ in
                    // Прокручуємо до нового положення
                    if let newIndex = self.filteredTasks.firstIndex(where: { $0.id == taskId }) {
                        let indexPath = IndexPath(row: newIndex, section: 0)
                        self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                    }
                }
            }
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
        // ВИПРАВЛЕНО: Додаємо безпечну перевірку індексу
        guard indexPath.row < filteredTasks.count else {
            // Повертаємо порожню комірку якщо індекс поза межами
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskTableViewCell
        let task = filteredTasks[indexPath.row]
        
        cell.configure(with: task)
        cell.onCompletionToggle = { [weak self] taskId in
            if self?.isSelectionMode == true {
                // В режимі вибору - додаємо/видаляємо з вибраних
                if self?.selectedTaskIds.contains(taskId) == true {
                    self?.selectedTaskIds.remove(taskId)
                } else {
                    self?.selectedTaskIds.insert(taskId)
                }
                // ВИПРАВЛЕНО: Безпечне оновлення
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            } else {
                // Звичайний режим - перемикаємо статус
                self?.toggleTaskCompletion(taskId: taskId)
            }
        }
        
        // Використовуємо новий стиль виділення
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
        
        // ВИПРАВЛЕНО: Безпечна перевірка індексу
        guard indexPath.row < filteredTasks.count else {
            return
        }
        
        let task = filteredTasks[indexPath.row]
        
        if isSelectionMode {
            // В режимі множинного вибору
            if selectedTaskIds.contains(task.id) {
                selectedTaskIds.remove(task.id)
            } else {
                selectedTaskIds.insert(task.id)
            }
            // ВИПРАВЛЕНО: Безпечне оновлення
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } else {
            // Звичайний режим - редагування
            showEditTaskViewController(task: task)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // ВИПРАВЛЕНО: Безпечна перевірка індексу
            guard indexPath.row < filteredTasks.count else {
                return
            }
            
            let task = filteredTasks[indexPath.row]
            
            // Cancel notification
            NotificationManager.shared.cancelNotification(for: task.id)
            
            TaskManager.shared.deleteTask(withId: task.id)
            loadTasks()
        }
    }
}
