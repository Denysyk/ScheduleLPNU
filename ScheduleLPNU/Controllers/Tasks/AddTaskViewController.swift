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
    private var descriptionTextView: UITextView!
    private var dueDateButton: UIButton!
    private var priorityButton: UIButton!
    private var scheduleButton: UIButton!
    private var categoryButton: UIButton!
    private var tagsButton: UIButton!
    
    // Дані
    private var selectedDate: Date?
    private var selectedPriority: Task.TaskPriority = .medium
    private var selectedCategory: Task.TaskCategory = .other
    private var selectedTags: [String] = []
    private var selectedSchedule: String?
    private var savedSchedules: [SavedSchedule] = []
    
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
        
        // Navigation buttons
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
        let theme = ThemeManager.shared
        
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
        descriptionTextView = createStyledTextView()
        
        descCard.addArrangedSubview(descLabel)
        descCard.addArrangedSubview(descriptionTextView)
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
    
    private func createStyledTextView() -> UITextView {
        let theme = ThemeManager.shared
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = theme.backgroundColor
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 1
        textView.layer.borderColor = theme.separatorColor.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.delegate = self
        
        if taskToEdit == nil {
            textView.text = "Додайте деталі завдання..."
            textView.textColor = theme.secondaryTextColor
        } else {
            textView.textColor = theme.textColor
        }
        
        textView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        return textView
    }
    
    private func createStyledButton(title: String, icon: String, subtitle: String) -> UIButton {
        let theme = ThemeManager.shared
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .left
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true
        
        // Container for layout
        let container = UIView()
        container.isUserInteractionEnabled = false
        button.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = theme.accentColor
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconView)
        
        // Title stack
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
        subtitleLabel.tag = 999 // Для оновлення
        
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)
        
        // Chevron
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = theme.secondaryTextColor
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(chevron)
        
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            container.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            chevron.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            chevron.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 16),
            chevron.leadingAnchor.constraint(greaterThanOrEqualTo: textStack.trailingAnchor, constant: 8)
        ])
        
        return button
    }
    
    private func createSeparator() -> UIView {
        let theme = ThemeManager.shared
        let separator = UIView()
        separator.backgroundColor = theme.separatorColor
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return separator
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
        
        if let description = task.description, !description.isEmpty {
            descriptionTextView.text = description
            descriptionTextView.textColor = ThemeManager.shared.textColor
        }
        
        selectedDate = task.dueDate
        selectedPriority = task.priority
        selectedCategory = task.category
        selectedTags = task.tags
        selectedSchedule = task.associatedSchedule
        
        updateButtonTitles()
    }
    
    private func loadSchedules() {
        savedSchedules = ScheduleManager.shared.getSavedSchedules()
    }
    
    // MARK: - Button Actions
    
    @objc private func cancelTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func saveTapped() {
        guard let title = titleTextField.text, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "Помилка", message: "Введіть назву завдання")
            return
        }
        
        // ВИПРАВЛЕНО: правильна перевірка опису
        var finalDescription: String? = nil
        if let text = descriptionTextView.text,
           text != "Додайте деталі завдання...",
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            finalDescription = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if let existingTask = taskToEdit {
            // Редагування
            var updatedTask = existingTask
            updatedTask.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedTask.description = finalDescription
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
            // Створення нового
            var task = Task(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: finalDescription,
                priority: selectedPriority,
                dueDate: selectedDate,
                category: selectedCategory,
                tags: selectedTags
            )
            
            task.associatedSchedule = selectedSchedule
            TaskManager.shared.addTask(task)
            
            if selectedDate != nil {
                NotificationManager.shared.scheduleNotification(for: task)
                showAddToCalendarPrompt(for: task)
            } else {
                navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // MARK: - Calendar Integration
    
    private func showAddToCalendarPrompt(for task: Task) {
        let alert = UIAlertController(
            title: "📅 Додати в календар?",
            message: "Хочете додати це завдання до вашого iOS календаря?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Так, додати", style: .default) { [weak self] _ in
            self?.addTaskToCalendar(task: task)
        })
        
        alert.addAction(UIAlertAction(title: "Ні, дякую", style: .cancel) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func addTaskToCalendar(task: Task) {
        let status = CalendarManager.shared.checkCalendarAuthorizationStatus()
        
        switch status {
        case .notDetermined:
            CalendarManager.shared.requestCalendarAccess { [weak self] granted, error in
                if granted {
                    self?.performAddToCalendar(task: task)
                } else {
                    self?.showCalendarPermissionDenied()
                }
            }
        case .authorized, .fullAccess:
            performAddToCalendar(task: task)
        case .denied, .restricted, .writeOnly:
            showCalendarPermissionDenied()
        @unknown default:
            showCalendarPermissionDenied()
        }
    }
    
    private func performAddToCalendar(task: Task) {
        TaskManager.shared.addTaskToCalendar(taskId: task.id) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    let successAlert = UIAlertController(
                        title: "✅ Готово!",
                        message: "Завдання додано до календаря",
                        preferredStyle: .alert
                    )
                    successAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self?.navigationController?.popViewController(animated: true)
                    })
                    self?.present(successAlert, animated: true)
                } else {
                    let errorAlert = UIAlertController(
                        title: "⚠️ Помилка",
                        message: error ?? "Не вдалося додати до календаря",
                        preferredStyle: .alert
                    )
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self?.navigationController?.popViewController(animated: true)
                    })
                    self?.present(errorAlert, animated: true)
                }
            }
        }
    }
    
    private func showCalendarPermissionDenied() {
        let alert = UIAlertController(
            title: "🔒 Доступ заборонено",
            message: "Щоб додавати завдання в календар, увімкніть доступ у Налаштуваннях iOS.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Відкрити налаштування", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Pickers
    
    @objc private func dueDateButtonTapped() {
        showDatePicker()
    }
    
    @objc private func priorityButtonTapped() {
        showPriorityPicker()
    }
    
    @objc private func scheduleButtonTapped() {
        showSchedulePicker()
    }
    
    @objc private func categoryButtonTapped() {
        showCategoryPicker()
    }
    
    @objc private func tagsButtonTapped() {
        showTagsPicker()
    }
    
    private func showDatePicker() {
        let alert = UIAlertController(title: "Виберіть дату виконання", message: "\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = Locale(identifier: "uk_UA")
        datePicker.minimumDate = Date()
        
        if let currentDate = selectedDate {
            datePicker.date = currentDate
        }
        
        alert.view.addSubview(datePicker)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            datePicker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            datePicker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 50)
        ])
        
        alert.addAction(UIAlertAction(title: "Встановити", style: .default) { [weak self] _ in
            self?.selectedDate = datePicker.date
            self?.updateButtonTitles()
        })
        
        alert.addAction(UIAlertAction(title: "Очистити", style: .destructive) { [weak self] _ in
            self?.selectedDate = nil
            self?.updateButtonTitles()
        })
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showPriorityPicker() {
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
    
    private func showCategoryPicker() {
        let alert = UIAlertController(title: "Виберіть категорію", message: nil, preferredStyle: .actionSheet)
        
        for category in Task.TaskCategory.allCases {
            let action = UIAlertAction(title: "\(getCategoryEmoji(category)) \(category.rawValue)", style: .default) { [weak self] _ in
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
        case .personal: return "👤"
        case .work: return "💼"
        case .study: return "📚"
        case .health: return "❤️"
        case .shopping: return "🛒"
        case .other: return "📁"
        }
    }
    
    private func showSchedulePicker() {
        let alert = UIAlertController(title: "Прив'язати до розкладу", message: nil, preferredStyle: .actionSheet)
        
        if savedSchedules.isEmpty {
            alert.message = "У вас ще немає збережених розкладів"
        } else {
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
            
            let clearAction = UIAlertAction(title: "Очистити", style: .destructive) { [weak self] _ in
                self?.selectedSchedule = nil
                self?.updateButtonTitles()
            }
            alert.addAction(clearAction)
        }
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = scheduleButton
            popover.sourceRect = scheduleButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func showTagsPicker() {
        let alert = UIAlertController(title: "Додайте теги", message: "Розділіть теги комами", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "тег1, тег2, тег3"
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
        // Update date button
        if let date = selectedDate {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "uk_UA")
            formatter.dateFormat = "dd MMMM yyyy 'о' HH:mm"
            updateButtonSubtitle(dueDateButton, subtitle: formatter.string(from: date))
        } else {
            updateButtonSubtitle(dueDateButton, subtitle: "Не встановлено")
        }
        
        // Update priority button
        updateButtonSubtitle(priorityButton, subtitle: selectedPriority.rawValue)
        
        // Update category button
        updateButtonSubtitle(categoryButton, subtitle: "\(getCategoryEmoji(selectedCategory)) \(selectedCategory.rawValue)")
        
        // Update tags button
        if selectedTags.isEmpty {
            updateButtonSubtitle(tagsButton, subtitle: "Додати теги")
        } else {
            updateButtonSubtitle(tagsButton, subtitle: selectedTags.joined(separator: ", "))
        }
        
        // Update schedule button
        if let schedule = selectedSchedule {
            updateButtonSubtitle(scheduleButton, subtitle: schedule)
        } else {
            updateButtonSubtitle(scheduleButton, subtitle: "Не обрано")
        }
    }
    
    private func updateButtonSubtitle(_ button: UIButton, subtitle: String) {
        for subview in button.subviews {
            if let label = subview.viewWithTag(999) as? UILabel {
                label.text = subtitle
                return
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.tintColor = ThemeManager.shared.accentColor
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITextFieldDelegate
extension AddTaskViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UITextViewDelegate
extension AddTaskViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        let theme = ThemeManager.shared
        if textView.text == "Додайте деталі завдання..." {
            textView.text = ""
            textView.textColor = theme.textColor
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        let theme = ThemeManager.shared
        if textView.text.isEmpty {
            textView.text = "Додайте деталі завдання..."
            textView.textColor = theme.secondaryTextColor
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // Забезпечуємо видимість тексту
        let theme = ThemeManager.shared
        if !textView.text.isEmpty && textView.text != "Додайте деталі завдання..." {
            textView.textColor = theme.textColor
        }
    }
}
