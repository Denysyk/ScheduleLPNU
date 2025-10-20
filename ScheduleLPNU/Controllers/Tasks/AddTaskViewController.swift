//
//  AddTaskViewController.swift
//  ScheduleLPNU
//
//  Created by Denys Brativnyk on 26.05.2025.
//

import UIKit

class AddTaskViewController: UIViewController {
    
    // UI елементи
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var mainStack: UIStackView!
    
    private var titleTextField: UITextField!
    private var descriptionTextField: UITextField! // Замінено TextView на TextField
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
            title = "Редагувати завдання"
        } else {
            title = "Нове завдання"
        }
    }
    
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
        card.layer.shadowOpacity = theme.isDarkMode ? 0 : 0.05
        return card
    }
    
    private func createSeparator() -> UIView {
        let theme = ThemeManager.shared
        let separator = UIView()
        separator.backgroundColor = theme.separatorColor
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }
    
    private func createSectionLabel(text: String) -> UILabel {
        let theme = ThemeManager.shared
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = theme.secondaryTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createStyledTextField(placeholder: String) -> UITextField {
        let theme = ThemeManager.shared
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = placeholder
        textField.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        textField.textColor = theme.textColor
        textField.delegate = self
        
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: theme.secondaryTextColor.withAlphaComponent(0.5)]
        )
        
        textField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        return textField
    }
    
    private func createStyledButton(title: String, icon: String, subtitle: String) -> UIButton {
        let theme = ThemeManager.shared
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .left
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true
        
        let container = UIView()
        container.isUserInteractionEnabled = false
        button.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = theme.accentColor
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconView)
        
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textStack)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = theme.textColor
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = theme.secondaryTextColor
        subtitleLabel.tag = 999
        
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)
        
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = theme.secondaryTextColor
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(chevron)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: button.topAnchor),
            container.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),
            
            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            chevron.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            chevron.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevron.leadingAnchor.constraint(greaterThanOrEqualTo: textStack.trailingAnchor, constant: 8),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        return button
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
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
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.scrollIndicatorInsets.bottom = keyboardHeight
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets.bottom = 0
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
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
    
    @objc private func cancelTapped() {
        // Якщо це режим редагування
        if let originalTask = originalTaskState {
            // Відновлюємо оригінальний стан завдання
            TaskManager.shared.updateTask(originalTask)
            
            // Відновлюємо оригінальний стан календаря
            if let currentTask = taskToEdit {
                if originalCalendarState != currentTask.isInCalendar {
                    if originalCalendarState && !currentTask.isInCalendar {
                        // Було в календарі, але видалили - повертаємо назад
                        TaskManager.shared.addTaskToCalendar(taskId: currentTask.id) { _, _ in }
                    } else if !originalCalendarState && currentTask.isInCalendar {
                        // Не було в календарі, але додали - видаляємо
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
        
        if let existingTask = taskToEdit {
            var updatedTask = existingTask
            updatedTask.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedTask.description = description
            updatedTask.priority = selectedPriority
            updatedTask.category = selectedCategory
            updatedTask.tags = selectedTags
            updatedTask.dueDate = selectedDate
            updatedTask.associatedSchedule = selectedSchedule
            
            TaskManager.shared.updateTask(updatedTask)
            
            if selectedDate != nil {
                NotificationManager.shared.cancelNotification(for: updatedTask.id)
                NotificationManager.shared.scheduleNotification(for: updatedTask)
            }
            
            navigationController?.popViewController(animated: true)
        } else {
            var task = Task(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description,
                priority: selectedPriority,
                dueDate: selectedDate,
                category: selectedCategory,
                tags: selectedTags
            )
            
            task.associatedSchedule = selectedSchedule
            TaskManager.shared.addTask(task)
            
            if selectedDate != nil {
                NotificationManager.shared.scheduleNotification(for: task)
                
                if shouldAddToCalendar {
                    TaskManager.shared.addTaskToCalendar(taskId: task.id) { [weak self] success, error in
                        DispatchQueue.main.async {
                            let message = success ?
                                "✅ Завдання створено і додано в календар" : "✅ Завдання створено (помилка календаря)"
                            self?.showToast(message: message)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self?.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                    return
                }
            }
            
            navigationController?.popViewController(animated: true)
        }
    }
    
    @objc private func dueDateButtonTapped() {
        let alert = UIAlertController(title: "Виберіть дату виконання", message: nil, preferredStyle: .actionSheet)
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = Locale(identifier: "uk_UA")
        datePicker.minimumDate = Date()
        
        if let date = selectedDate {
            datePicker.date = date
        }
        
        let pickerContainer = UIViewController()
        pickerContainer.preferredContentSize = CGSize(width: 0, height: 250)
        pickerContainer.view = datePicker
        alert.setValue(pickerContainer, forKey: "contentViewController")
        
        alert.addAction(UIAlertAction(title: "Підтвердити", style: .default) { [weak self] _ in
            self?.selectedDate = datePicker.date
            self?.updateButtonTitles()
        })
        
        alert.addAction(UIAlertAction(title: "Видалити дату", style: .destructive) { [weak self] _ in
            self?.selectedDate = nil
            self?.shouldAddToCalendar = false
            self?.updateButtonTitles()
        })
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = dueDateButton
            popover.sourceRect = dueDateButton.bounds
        }
        
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
    
    @objc private func scheduleButtonTapped() {
        let alert = UIAlertController(title: "Прив'язати до розкладу", message: nil, preferredStyle: .actionSheet)
        
        for schedule in savedSchedules {
            let action = UIAlertAction(title: schedule.title, style: .default) { [weak self] _ in
                self?.selectedSchedule = schedule.title
                self?.updateButtonTitles()
            }
            
            if selectedSchedule == schedule.title {
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
    
    @objc private func calendarButtonTapped() {
        guard selectedDate != nil else {
            showAlert(title: "Помилка", message: "Завдання не має дати виконання")
            return
        }
        
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
                // ВИПРАВЛЕННЯ: Спочатку оновлюємо дату завдання, якщо вона змінилась
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
    
    private func updateButtonTitles() {
        // Оновлення дати виконання
        if let date = selectedDate {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "uk_UA")
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            formatter.dateFormat = "dd MMMM yyyy 'о' HH:mm"
            
            updateButtonSubtitle(button: dueDateButton, subtitle: formatter.string(from: date))
        } else {
            updateButtonSubtitle(button: dueDateButton, subtitle: "Не встановлено")
        }
        
        // Оновлення пріоритету
        updateButtonSubtitle(button: priorityButton, subtitle: selectedPriority.rawValue)
        
        // Оновлення категорії
        let emoji = getCategoryEmoji(selectedCategory)
        updateButtonSubtitle(button: categoryButton, subtitle: "\(emoji) \(selectedCategory.rawValue)")
        
        // Оновлення розкладу
        if let schedule = selectedSchedule {
            updateButtonSubtitle(button: scheduleButton, subtitle: schedule)
        } else {
            updateButtonSubtitle(button: scheduleButton, subtitle: "Не обрано")
        }
        
        // ВИПРАВЛЕННЯ: Покращена логіка для кнопки календаря
        let isInCalendar: Bool
        let hasDate = selectedDate != nil
        
        if let task = taskToEdit {
            // В режимі редагування перевіряємо реальний стан завдання
            isInCalendar = task.isInCalendar
        } else {
            // В режимі створення використовуємо shouldAddToCalendar
            isInCalendar = shouldAddToCalendar
        }
        
        // Оновлюємо кнопку календаря
        if hasDate {
            if isInCalendar {
                updateButtonSubtitle(button: calendarButton, subtitle: "Додано")
            } else {
                updateButtonSubtitle(button: calendarButton, subtitle: "Не додано")
            }
            calendarButton.isEnabled = true
            calendarButton.alpha = 1.0
        } else {
            updateButtonSubtitle(button: calendarButton, subtitle: "Потрібна дата")
            calendarButton.isEnabled = false
            calendarButton.alpha = 0.5
        }
        
        // Оновлення тегів
        if !selectedTags.isEmpty {
            updateButtonSubtitle(button: tagsButton, subtitle: selectedTags.joined(separator: ", "))
        } else {
            updateButtonSubtitle(button: tagsButton, subtitle: "Додати теги")
        }
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
