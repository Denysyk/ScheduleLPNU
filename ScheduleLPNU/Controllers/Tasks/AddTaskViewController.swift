//
//  AddTaskViewController.swift
//  ScheduleLPNU
//
//  Updated with calendar permission checks
//

import UIKit

class AddTaskViewController: BaseFullScreenViewController {
    
    // UI елементи
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var mainStack: UIStackView!
    
    private var titleTextField: UITextField!
    private var descriptionTextField: UITextField!
    private var dueDateButton: UIButton!
    private var priorityButton: UIButton!
    private var scheduleButton: UIButton!
    private var categoryButton: UIButton!
    private var tagsButton: UIButton!
    private var calendarButton: UIButton!
    
    // Дані
    private var selectedDate: Date?
    private var selectedPriority: Task.TaskPriority = .medium
    private var selectedCategory: Task.TaskCategory = .other
    private var selectedTags: [String] = []
    private var selectedSchedule: String?
    private var savedSchedules: [SavedSchedule] = []
    private var shouldAddToCalendar = false
    
    private var originalTaskState: Task?
    private var originalCalendarState: Bool = false
    
    var taskToEdit: Task?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSchedules()
        
        if let task = taskToEdit {
            loadTaskForEditing(task)
            setupMultilineTitle("Редагувати завдання")
        } else {
            setupMultilineTitle("Нове завдання")
        }
    }
    
    private func setupMultilineTitle(_ text: String) {
        let titleLabel = UILabel()
        titleLabel.text = text
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = ThemeManager.shared.accentColor
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0 // Дозволяємо багато ліній
        titleLabel.lineBreakMode = .byWordWrapping
        
        // Встановлюємо розмір для titleLabel
        let maxWidth: CGFloat = UIScreen.main.bounds.width - 200 // Залишаємо місце для кнопок
        let size = titleLabel.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        titleLabel.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        navigationItem.titleView = titleLabel
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        let theme = ThemeManager.shared
        view.backgroundColor = theme.backgroundColor
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Скасувати",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Зберегти",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
        
        navigationItem.leftBarButtonItem?.tintColor = theme.accentColor
        navigationItem.rightBarButtonItem?.tintColor = theme.accentColor
        
        setupScrollView()
        setupMainStack()
        setupConstraints()
        setupKeyboardDismissal()
        setupNotifications()
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
    }
    
    private func setupMainStack() {
        mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)
        
        // Title Card
        let titleCard = createCard()
        let titleLabel = createSectionLabel(text: "Назва завдання")
        titleTextField = createStyledTextField(placeholder: "Наприклад: Здати курсову роботу")
        
        titleCard.addArrangedSubview(titleLabel)
        titleCard.addArrangedSubview(titleTextField)
        mainStack.addArrangedSubview(titleCard)
        
        // Description Card
        let descCard = createCard()
        let descLabel = createSectionLabel(text: "Опис (необов'язково)")
        descriptionTextField = createStyledTextField(placeholder: "Додайте опис завдання...")
        
        descCard.addArrangedSubview(descLabel)
        descCard.addArrangedSubview(descriptionTextField)
        mainStack.addArrangedSubview(descCard)
        
        // Buttons Card
        let buttonsCard = createCard()
        
        dueDateButton = createStyledButton(
            title: "Додати дату виконання",
            icon: "calendar",
            subtitle: "Не встановлено"
        )
        dueDateButton.addTarget(self, action: #selector(dueDateButtonTapped), for: .touchUpInside)
        
        priorityButton = createStyledButton(
            title: "Пріоритет",
            icon: "exclamationmark.triangle.fill",
            subtitle: "Середній"
        )
        priorityButton.addTarget(self, action: #selector(priorityButtonTapped), for: .touchUpInside)
        
        categoryButton = createStyledButton(
            title: "Категорія",
            icon: "folder.fill",
            subtitle: "📁 Інше"
        )
        categoryButton.addTarget(self, action: #selector(categoryButtonTapped), for: .touchUpInside)
        
        scheduleButton = createStyledButton(
            title: "Прив'язати до розкладу",
            icon: "calendar.badge.clock",
            subtitle: "Не обрано"
        )
        scheduleButton.addTarget(self, action: #selector(scheduleButtonTapped), for: .touchUpInside)
        
        calendarButton = createStyledButton(
            title: "📅 Додати в календар",
            icon: "calendar.badge.plus",
            subtitle: "Не додано"
        )
        calendarButton.addTarget(self, action: #selector(calendarButtonTapped), for: .touchUpInside)
        
        tagsButton = createStyledButton(
            title: "Теги",
            icon: "tag.fill",
            subtitle: "Додати теги"
        )
        tagsButton.addTarget(self, action: #selector(tagsButtonTapped), for: .touchUpInside)
        
        buttonsCard.addArrangedSubview(dueDateButton)
        buttonsCard.addArrangedSubview(createSeparator())
        buttonsCard.addArrangedSubview(priorityButton)
        buttonsCard.addArrangedSubview(createSeparator())
        buttonsCard.addArrangedSubview(categoryButton)
        buttonsCard.addArrangedSubview(createSeparator())
        buttonsCard.addArrangedSubview(scheduleButton)
        buttonsCard.addArrangedSubview(createSeparator())
        buttonsCard.addArrangedSubview(calendarButton)
        buttonsCard.addArrangedSubview(createSeparator())
        buttonsCard.addArrangedSubview(tagsButton)
        
        mainStack.addArrangedSubview(buttonsCard)
    }
    
    private func createCard() -> UIStackView {
        let theme = ThemeManager.shared
        let card = UIStackView()
        card.axis = .vertical
        card.spacing = 12
        card.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        card.isLayoutMarginsRelativeArrangement = true
        card.backgroundColor = theme.cardBackgroundColor
        card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 4
        card.layer.shadowOpacity = theme.isDarkMode ? 0.3 : 0.1
        return card
    }
    
    private func createSectionLabel(text: String) -> UILabel {
        let theme = ThemeManager.shared
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = theme.secondaryTextColor
        return label
    }
    
    private func createStyledTextField(placeholder: String) -> UITextField {
        let theme = ThemeManager.shared
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.font = .systemFont(ofSize: 16)
        textField.textColor = theme.textColor
        textField.delegate = self
        textField.returnKeyType = .done
        
        textField.backgroundColor = theme.isDarkMode ? UIColor(white: 0.15, alpha: 1) : UIColor(white: 0.95, alpha: 1)
        textField.layer.cornerRadius = 8
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        textField.rightViewMode = .always
        
        textField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        return textField
    }
    
    private func createStyledButton(title: String, icon: String, subtitle: String) -> UIButton {
        let theme = ThemeManager.shared
        let button = UIButton(type: .system)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        
        let container = UIView()
        container.isUserInteractionEnabled = false
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = theme.accentColor
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconImageView)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = theme.textColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = theme.secondaryTextColor
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.tag = 999
        container.addSubview(subtitleLabel)
        
        container.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(container)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            container.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 12),
            container.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -12),
            container.topAnchor.constraint(equalTo: button.topAnchor, constant: 12),
            container.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -12)
        ])
        
        return button
    }
    
    private func createSeparator() -> UIView {
        let theme = ThemeManager.shared
        let separator = UIView()
        separator.backgroundColor = theme.isDarkMode ? UIColor(white: 0.3, alpha: 1) : UIColor(white: 0.9, alpha: 1)
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = keyboardFrame.height
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    // MARK: - Data Loading
    
    private func loadTaskForEditing(_ task: Task) {
        titleTextField.text = task.title
        descriptionTextField.text = task.description ?? ""
        
        selectedDate = task.dueDate
        selectedPriority = task.priority
        selectedCategory = task.category
        selectedTags = task.tags
        selectedSchedule = task.associatedSchedule
        shouldAddToCalendar = task.isInCalendar
        
        originalTaskState = task
        originalCalendarState = task.isInCalendar
        
        updateButtonTitles()
    }
    
    private func loadSchedules() {
        savedSchedules = ScheduleManager.shared.getSavedSchedules()
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        if let originalTask = originalTaskState {
            TaskManager.shared.updateTask(originalTask)
            
            if let currentTask = taskToEdit {
                if originalCalendarState != currentTask.isInCalendar {
                    if originalCalendarState && !currentTask.isInCalendar {
                        TaskManager.shared.addTaskToCalendar(taskId: currentTask.id) { _, _ in }
                    } else if !originalCalendarState && currentTask.isInCalendar {
                        TaskManager.shared.removeTaskFromCalendar(taskId: currentTask.id) { _, _ in }
                    }
                }
            }
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func saveTapped() {
        guard let title = titleTextField.text, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "Помилка", message: "Введіть назву завдання")
            return
        }
        
        let descriptionText = descriptionTextField.text ?? ""
        let finalDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = finalDescription.isEmpty ? nil : finalDescription
        
        if let task = taskToEdit {
            var updatedTask = task
            updatedTask.title = title
            updatedTask.description = description
            updatedTask.dueDate = selectedDate
            updatedTask.priority = selectedPriority
            updatedTask.category = selectedCategory
            updatedTask.tags = selectedTags
            updatedTask.associatedSchedule = selectedSchedule
            
            TaskManager.shared.updateTask(updatedTask)
            
            if shouldAddToCalendar && !task.isInCalendar {
                TaskManager.shared.addTaskToCalendar(taskId: task.id) { _, _ in }
            } else if !shouldAddToCalendar && task.isInCalendar {
                TaskManager.shared.removeTaskFromCalendar(taskId: task.id) { _, _ in }
            } else if shouldAddToCalendar && task.isInCalendar {
                // Якщо вже в календарі, оновлюємо через CalendarManager
                CalendarManager.shared.updateTaskInCalendar(task: updatedTask) { _, _ in }
            }
            
            showToast(message: "✅ Завдання оновлено")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            let newTask = Task(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description,
                priority: selectedPriority,
                dueDate: selectedDate,
                category: selectedCategory,
                tags: selectedTags
            )
            var taskToSave = newTask
            taskToSave.associatedSchedule = selectedSchedule
            
            TaskManager.shared.addTask(taskToSave)
            
            if shouldAddToCalendar, selectedDate != nil {
                TaskManager.shared.addTaskToCalendar(taskId: taskToSave.id) { [weak self] success, error in
                    DispatchQueue.main.async {
                        let message = success ? "✅ Завдання створено і додано в календар" : "✅ Завдання створено (помилка календаря)"
                        self?.showToast(message: message)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            } else {
                // Якщо не додаємо в календар, просто повертаємося
                navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @objc private func dueDateButtonTapped() {
        let datePickerVC = UIViewController()
        datePickerVC.preferredContentSize = CGSize(width: 320, height: 300)
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = Locale(identifier: "uk_UA")
        datePicker.minimumDate = Date()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        
        if let date = selectedDate {
            datePicker.date = date
        }
        
        datePickerVC.view.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: datePickerVC.view.topAnchor),
            datePicker.leadingAnchor.constraint(equalTo: datePickerVC.view.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: datePickerVC.view.trailingAnchor),
            datePicker.bottomAnchor.constraint(equalTo: datePickerVC.view.bottomAnchor)
        ])
        
        let alert = UIAlertController(title: "Виберіть дату виконання", message: nil, preferredStyle: .actionSheet)
        alert.setValue(datePickerVC, forKey: "contentViewController")
        
        alert.addAction(UIAlertAction(title: "Підтвердити", style: .default) { [weak self] _ in
            self?.selectedDate = datePicker.date
            self?.updateButtonTitles()
        })
        
        alert.addAction(UIAlertAction(title: "Видалити дату", style: .destructive) { [weak self] _ in
            self?.selectedDate = nil
            self?.updateButtonTitles()
        })
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func priorityButtonTapped() {
        let alert = UIAlertController(title: "Виберіть пріоритет", message: nil, preferredStyle: .actionSheet)
        
        for priority in Task.TaskPriority.allCases {
            let action = UIAlertAction(title: priority.rawValue, style: .default) { [weak self] _ in
                self?.selectedPriority = priority
                self?.updateButtonTitles()
            }
            
            if priority == selectedPriority {
                action.setValue(UIImage(systemName: "checkmark"), forKey: "image")
            }
            
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = priorityButton
            popover.sourceRect = priorityButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc private func categoryButtonTapped() {
        let alert = UIAlertController(title: "Виберіть категорію", message: nil, preferredStyle: .actionSheet)
        
        for category in Task.TaskCategory.allCases {
            let emoji = getCategoryEmoji(category)
            let action = UIAlertAction(title: "\(emoji) \(category.rawValue)", style: .default) { [weak self] _ in
                self?.selectedCategory = category
                self?.updateButtonTitles()
            }
            
            if category == selectedCategory {
                action.setValue(UIImage(systemName: "checkmark"), forKey: "image")
            }
            
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = categoryButton
            popover.sourceRect = categoryButton.bounds
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
    
    @objc private func scheduleButtonTapped() {
        if savedSchedules.isEmpty {
            showAlert(title: "Немає збережених розкладів", message: "Спочатку створіть та збережіть розклад")
            return
        }
        
        let alert = UIAlertController(title: "Виберіть розклад", message: nil, preferredStyle: .actionSheet)
        
        for schedule in savedSchedules {
            let action = UIAlertAction(title: schedule.title, style: .default) { [weak self] _ in
                self?.selectedSchedule = schedule.title
                self?.updateButtonTitles()
            }
            
            if schedule.title == selectedSchedule {
                action.setValue(UIImage(systemName: "checkmark"), forKey: "image")
            }
            
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Видалити прив'язку", style: .destructive) { [weak self] _ in
            self?.selectedSchedule = nil
            self?.updateButtonTitles()
        })
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = scheduleButton
            popover.sourceRect = scheduleButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    // MARK: - Calendar Integration with Permission Check
    
    @objc private func calendarButtonTapped() {
        guard selectedDate != nil else {
            showAlert(title: "Помилка", message: "Завдання не має дати виконання")
            return
        }
        
        // Перевірка дозволів календаря
        let status = CalendarManager.shared.checkCalendarAuthorizationStatus()
        
        switch status {
        case .denied, .restricted:
            // Показуємо алерт з інструкціями як надати доступ
            showCalendarPermissionAlert()
            return
            
        case .notDetermined:
            // Запитуємо дозвіл
            CalendarManager.shared.requestCalendarAccess { [weak self] granted, error in
                DispatchQueue.main.async {
                    if granted {
                        // Після отримання дозволу виконуємо операцію
                        self?.performCalendarOperation()
                    } else {
                        self?.showCalendarPermissionAlert()
                    }
                }
            }
            return
            
        case .authorized, .fullAccess, .writeOnly:
            // Дозвіл є, виконуємо операцію
            performCalendarOperation()
            
        @unknown default:
            showCalendarPermissionAlert()
            return
        }
    }
    
    private func performCalendarOperation() {
        if let task = taskToEdit {
            // Режим редагування існуючого завдання
            if task.isInCalendar {
                // Видалення з календаря
                TaskManager.shared.removeTaskFromCalendar(taskId: task.id) { [weak self] success, error in
                    DispatchQueue.main.async {
                        if success {
                            if let editedTask = self?.taskToEdit {
                                var updatedTask = editedTask
                                updatedTask.isInCalendar = false
                                self?.taskToEdit = updatedTask
                            }
                            self?.shouldAddToCalendar = false
                            self?.updateButtonTitles()
                            self?.showToast(message: "✅ Видалено з календаря")
                        } else {
                            self?.showAlert(title: "Помилка", message: error ?? "Не вдалося видалити з календаря")
                        }
                    }
                }
            } else {
                // Додавання в календар
                if task.dueDate != selectedDate {
                    var updatedTask = task
                    updatedTask.dueDate = selectedDate
                    TaskManager.shared.updateTask(updatedTask)
                    self.taskToEdit = updatedTask
                }
                
                TaskManager.shared.addTaskToCalendar(taskId: task.id) { [weak self] success, error in
                    DispatchQueue.main.async {
                        if success {
                            if let editedTask = self?.taskToEdit {
                                var updatedTask = editedTask
                                updatedTask.isInCalendar = true
                                self?.taskToEdit = updatedTask
                            }
                            self?.shouldAddToCalendar = true
                            self?.updateButtonTitles()
                            self?.showToast(message: "✅ Додано в календар")
                        } else {
                            self?.showAlert(title: "Помилка", message: error ?? "Не вдалося додати в календар")
                        }
                    }
                }
            }
        } else {
            // Режим створення нового завдання
            shouldAddToCalendar.toggle()
            updateButtonTitles()
            
            let message = shouldAddToCalendar ? "✅ Буде додано в календар після створення" : "❌ Не буде додано в календар"
            showToast(message: message)
        }
    }
    
    private func showCalendarPermissionAlert() {
        let alert = UIAlertController(
            title: "Немає доступу до календаря",
            message: "Для синхронізації завдань з календарем потрібен доступ до календаря.\n\n⚠️ Увага: після надання доступу додаток перезапуститься автоматично (це стандартна поведінка iOS).\n\nВам потрібно буде створити завдання заново.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Відкрити налаштування", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func tagsButtonTapped() {
        let alert = UIAlertController(title: "Додати теги", message: "Введіть теги через кому", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "навчання, важливо, проект"
            textField.text = self.selectedTags.joined(separator: ", ")
        }
        
        alert.addAction(UIAlertAction(title: "Зберегти", style: .default) { [weak self] _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                self?.selectedTags = text.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            } else {
                self?.selectedTags = []
            }
            self?.updateButtonTitles()
        })
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        present(alert, animated: true)
    }
    
    // MARK: - UI Updates
    
    private func updateButtonTitles() {
        if let date = selectedDate {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "uk_UA")
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            updateButtonSubtitle(button: dueDateButton, subtitle: formatter.string(from: date))
        } else {
            updateButtonSubtitle(button: dueDateButton, subtitle: "Не встановлено")
        }
        
        updateButtonSubtitle(button: priorityButton, subtitle: selectedPriority.rawValue)
        
        let categoryEmoji = getCategoryEmoji(selectedCategory)
        updateButtonSubtitle(button: categoryButton, subtitle: "\(categoryEmoji) \(selectedCategory.rawValue)")
        
        if let schedule = selectedSchedule {
            updateButtonSubtitle(button: scheduleButton, subtitle: schedule)
        } else {
            updateButtonSubtitle(button: scheduleButton, subtitle: "Не обрано")
        }
        
        if let task = taskToEdit {
            if task.isInCalendar {
                updateButtonSubtitle(button: calendarButton, subtitle: "✅ Додано")
            } else {
                updateButtonSubtitle(button: calendarButton, subtitle: "Додати в календар")
            }
        } else {
            if shouldAddToCalendar {
                updateButtonSubtitle(button: calendarButton, subtitle: "✅ Буде додано")
            } else {
                updateButtonSubtitle(button: calendarButton, subtitle: "Не додано")
            }
        }
        
        if selectedTags.isEmpty {
            updateButtonSubtitle(button: tagsButton, subtitle: "Додати теги")
        } else {
            updateButtonSubtitle(button: tagsButton, subtitle: selectedTags.joined(separator: ", "))
        }
    }
    
    private func updateButtonSubtitle(button: UIButton, subtitle: String) {
        func findSubtitleLabel(in view: UIView) -> UILabel? {
            for subview in view.subviews {
                if let label = subview as? UILabel, label.tag == 999 {
                    return label
                }
                if let foundLabel = findSubtitleLabel(in: subview) {
                    return foundLabel
                }
            }
            return nil
        }
        
        if let subtitleLabel = findSubtitleLabel(in: button) {
            subtitleLabel.text = subtitle
            
            if button == calendarButton {
                let theme = ThemeManager.shared
                if subtitle.contains("✅") {
                    subtitleLabel.textColor = theme.accentColor
                } else {
                    subtitleLabel.textColor = theme.secondaryTextColor
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.tintColor = ThemeManager.shared.accentColor
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }
    
    private func showToast(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITextFieldDelegate
extension AddTaskViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == titleTextField {
            descriptionTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
