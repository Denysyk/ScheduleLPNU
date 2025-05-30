//
//  AddTaskViewController.swift
//  ScheduleLPNU
//
//  Created by Denys Brativnyk on 26.05.2025.
//

import UIKit

class AddTaskViewController: UIViewController {
    
    // UI елементи - програмні
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
    
    // Додана змінна для редагування
    var taskToEdit: Task?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupThemeObserver()
        loadSchedules()
        applyTheme()
        
        // Request notification permission
        NotificationManager.shared.requestPermission { granted in
            // Notification permission handled
        }
        
        // Якщо редагуємо існуюче завдання
        if let task = taskToEdit {
            loadTaskForEditing(task)
        }
        
        // Налаштування закриття клавіатури
        setupKeyboardDismissal()
        setupNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        view.backgroundColor = theme.backgroundColor
        
        // Navigation
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: theme.accentColor,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navigationController?.navigationBar.tintColor = theme.accentColor
        
        // Text fields and text views
        titleTextField?.backgroundColor = theme.cardBackgroundColor
        titleTextField?.textColor = theme.textColor
        titleTextField?.layer.borderColor = theme.separatorColor.cgColor
        
        descriptionTextView?.backgroundColor = theme.cardBackgroundColor
        descriptionTextView?.textColor = theme.textColor
        descriptionTextView?.layer.borderColor = theme.separatorColor.cgColor
        
        // Update placeholder color for text view
        if descriptionTextView?.text == "Введіть опис завдання..." {
            descriptionTextView?.textColor = theme.secondaryTextColor
        }
        
        // Buttons
        let buttons = [dueDateButton, priorityButton, scheduleButton, categoryButton, tagsButton]
        buttons.forEach { button in
            button?.backgroundColor = theme.cardBackgroundColor
            button?.setTitleColor(theme.accentColor, for: .normal)
            button?.tintColor = theme.accentColor
            button?.layer.borderColor = theme.separatorColor.cgColor
        }
        
        // Labels
        for view in mainStack.arrangedSubviews {
            if let label = view as? UILabel {
                label.textColor = theme.textColor
            }
        }
        
        // Update toolbar
        if let toolbar = descriptionTextView?.inputAccessoryView as? UIToolbar {
            toolbar.items?.forEach { $0.tintColor = theme.accentColor }
        }
    }
    
    private func setupUI() {
        if taskToEdit == nil {
            title = "НОВЕ ЗАВДАННЯ"
        } else {
            // Створюємо кастомний title label для багаторядкового заголовка
            let titleLabel = UILabel()
            titleLabel.text = "РЕДАГУВАТИ\nЗАВДАННЯ"
            titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 0
            titleLabel.textColor = ThemeManager.shared.accentColor
            titleLabel.sizeToFit()
            
            navigationItem.titleView = titleLabel
        }
        
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
        
        createScrollView()
        createFormElements()
    }
    
    private func createScrollView() {
        scrollView = UIScrollView()
        contentView = UIView()
        mainStack = UIStackView()
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(mainStack)
        
        // Налаштування Stack View
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.distribution = .fill
    }
    
    private func createFormElements() {
        let theme = ThemeManager.shared
        
        // Назва завдання
        let titleLabel = createLabel(text: "Назва завдання")
        titleTextField = createTextField(placeholder: "Введіть назву завдання")
        
        // Опис завдання
        let descriptionLabel = createLabel(text: "Опис завдання")
        descriptionTextView = createTextView()
        
        // Дата і час
        let dateLabel = createLabel(text: "Дата і час")
        dueDateButton = createButton(title: "Вибрати дату", icon: "calendar", action: #selector(dueDateButtonTapped))
        
        // Пріоритет
        let priorityLabel = createLabel(text: "Пріоритет")
        priorityButton = createButton(title: selectedPriority.rawValue, icon: "flag.fill", action: #selector(priorityButtonTapped))
        
        // Зв'язати з розкладом
        let scheduleLabel = createLabel(text: "Зв'язати з розкладом")
        scheduleButton = createButton(title: "Вибрати розклад", icon: "book.fill", action: #selector(scheduleButtonTapped))
        
        // Категорія
        let categoryLabel = createLabel(text: "Категорія")
        categoryButton = createButton(title: selectedCategory.rawValue, icon: selectedCategory.icon, action: #selector(categoryButtonTapped))
        
        // Теги
        let tagsLabel = createLabel(text: "Теги")
        tagsButton = createButton(title: "Додати теги", icon: "tag.fill", action: #selector(tagsButtonTapped))
        
        // Додаємо все до Stack View
        mainStack.addArrangedSubview(titleLabel)
        mainStack.addArrangedSubview(titleTextField)
        mainStack.addArrangedSubview(descriptionLabel)
        mainStack.addArrangedSubview(descriptionTextView)
        mainStack.addArrangedSubview(dateLabel)
        mainStack.addArrangedSubview(dueDateButton)
        mainStack.addArrangedSubview(priorityLabel)
        mainStack.addArrangedSubview(priorityButton)
        mainStack.addArrangedSubview(scheduleLabel)
        mainStack.addArrangedSubview(scheduleButton)
        mainStack.addArrangedSubview(categoryLabel)
        mainStack.addArrangedSubview(categoryButton)
        mainStack.addArrangedSubview(tagsLabel)
        mainStack.addArrangedSubview(tagsButton)
    }
    
    private func createLabel(text: String) -> UILabel {
        let theme = ThemeManager.shared
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = theme.textColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createTextField(placeholder: String) -> UITextField {
        let theme = ThemeManager.shared
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = placeholder
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.layer.cornerRadius = 8
        textField.layer.borderWidth = 1
        textField.layer.borderColor = theme.separatorColor.cgColor
        textField.backgroundColor = theme.cardBackgroundColor
        textField.textColor = theme.textColor
        textField.delegate = self
        
        // Placeholder color
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: theme.secondaryTextColor]
        )
        
        // Padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        
        textField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        return textField
    }
    
    private func createTextView() -> UITextView {
        let theme = ThemeManager.shared
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 1
        textView.layer.borderColor = theme.separatorColor.cgColor
        textView.backgroundColor = theme.cardBackgroundColor
        textView.textColor = theme.textColor
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.delegate = self
        
        if taskToEdit == nil {
            textView.text = "Введіть опис завдання..."
            textView.textColor = theme.secondaryTextColor
        }
        
        textView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        // Додаємо toolbar з кнопкою "Готово"
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(dismissKeyboard))
        doneButton.tintColor = theme.accentColor
        toolbar.items = [flexSpace, doneButton]
        textView.inputAccessoryView = toolbar
        
        return textView
    }
    
    private func createButton(title: String, icon: String, action: Selector) -> UIButton {
        let theme = ThemeManager.shared
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.setTitle(title, for: .normal)
        button.setTitleColor(theme.accentColor, for: .normal)
        button.backgroundColor = theme.cardBackgroundColor
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = theme.separatorColor.cgColor
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        
        // Іконка зліва з правильним відступом
        if let image = UIImage(systemName: icon) {
            button.setImage(image, for: .normal)
            button.tintColor = theme.accentColor
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        }
        
        button.addTarget(self, action: action, for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        return button
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView з Safe Area
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Main Stack
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
        
        let description = descriptionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDescription = (description.isEmpty || description == "Введіть опис завдання...") ? nil : description
        
        if let existingTask = taskToEdit {
            // Редагуємо існуюче завдання
            var updatedTask = existingTask
            updatedTask.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedTask.description = finalDescription
            updatedTask.priority = selectedPriority
            updatedTask.category = selectedCategory
            updatedTask.tags = selectedTags
            updatedTask.dueDate = selectedDate
            updatedTask.associatedSchedule = selectedSchedule
            
            TaskManager.shared.updateTask(updatedTask)
            
            // Update notification
            if selectedDate != nil {
                NotificationManager.shared.cancelNotification(for: updatedTask.id)
                NotificationManager.shared.scheduleNotification(for: updatedTask)
            }
        } else {
            // Створюємо нове завдання
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
            
            // Schedule notification
            if selectedDate != nil {
                NotificationManager.shared.scheduleNotification(for: task)
            }
        }
        
        navigationController?.popViewController(animated: true)
    }
    
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
    
    // MARK: - Picker Methods
    private func showDatePicker() {
        let alert = UIAlertController(title: "Вибрати дату", message: nil, preferredStyle: .actionSheet)
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.minimumDate = Date()
        datePicker.locale = Locale(identifier: "uk_UA")
        
        let pickerContainer = UIViewController()
        pickerContainer.view = datePicker
        pickerContainer.preferredContentSize = CGSize(width: 320, height: 200)
        
        alert.setValue(pickerContainer, forKey: "contentViewController")
        
        let selectAction = UIAlertAction(title: "Вибрати", style: .default) { [weak self] _ in
            self?.selectedDate = datePicker.date
            self?.updateButtonTitles()
        }
        
        let clearAction = UIAlertAction(title: "Очистити", style: .destructive) { [weak self] _ in
            self?.selectedDate = nil
            self?.updateButtonTitles()
        }
        
        let cancelAction = UIAlertAction(title: "Скасувати", style: .cancel)
        
        alert.addAction(selectAction)
        alert.addAction(clearAction)
        alert.addAction(cancelAction)
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = dueDateButton
            popover.sourceRect = dueDateButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func showPriorityPicker() {
        let alert = UIAlertController(title: "Пріоритет", message: nil, preferredStyle: .actionSheet)
        
        for priority in Task.TaskPriority.allCases {
            let action = UIAlertAction(title: priority.rawValue, style: .default) { [weak self] _ in
                self?.selectedPriority = priority
                self?.updateButtonTitles()
            }
            alert.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Скасувати", style: .cancel)
        alert.addAction(cancelAction)
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = priorityButton
            popover.sourceRect = priorityButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func showCategoryPicker() {
        let alert = UIAlertController(title: "Категорія", message: nil, preferredStyle: .actionSheet)
        
        for category in Task.TaskCategory.allCases {
            let action = UIAlertAction(title: category.rawValue, style: .default) { [weak self] _ in
                self?.selectedCategory = category
                self?.updateButtonTitles()
            }
            alert.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Скасувати", style: .cancel)
        alert.addAction(cancelAction)
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = categoryButton
            popover.sourceRect = categoryButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func showTagsPicker() {
        let alert = UIAlertController(title: "Додати тег", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Введіть тег"
        }
        
        let addAction = UIAlertAction(title: "Додати", style: .default) { [weak self] _ in
            if let text = alert.textFields?.first?.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let tag = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !(self?.selectedTags.contains(tag) ?? false) {
                    self?.selectedTags.append(tag)
                    self?.updateButtonTitles()
                }
            }
        }
        
        let clearAction = UIAlertAction(title: "Очистити всі", style: .destructive) { [weak self] _ in
            self?.selectedTags.removeAll()
            self?.updateButtonTitles()
        }
        
        let cancelAction = UIAlertAction(title: "Скасувати", style: .cancel)
        
        alert.addAction(addAction)
        if !selectedTags.isEmpty {
            alert.addAction(clearAction)
        }
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func showSchedulePicker() {
        let alert = UIAlertController(title: "Зв'язати з розкладом", message: nil, preferredStyle: .actionSheet)
        
        for schedule in savedSchedules {
            let action = UIAlertAction(title: schedule.title, style: .default) { [weak self] _ in
                self?.selectedSchedule = schedule.title
                self?.updateButtonTitles()
            }
            alert.addAction(action)
        }
        
        let clearAction = UIAlertAction(title: "Не зв'язувати", style: .destructive) { [weak self] _ in
            self?.selectedSchedule = nil
            self?.updateButtonTitles()
        }
        
        let cancelAction = UIAlertAction(title: "Скасувати", style: .cancel)
        
        alert.addAction(clearAction)
        alert.addAction(cancelAction)
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = scheduleButton
            popover.sourceRect = scheduleButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func updateButtonTitles() {
        // Update date button
        if let date = selectedDate {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "uk_UA")
            formatter.dateFormat = "dd MMMM yyyy 'о' HH:mm"
            dueDateButton.setTitle(formatter.string(from: date), for: .normal)
        } else {
            dueDateButton.setTitle("Вибрати дату", for: .normal)
        }
        
        // Update priority button
        priorityButton.setTitle(selectedPriority.rawValue, for: .normal)
        
        // Update category button
        categoryButton.setTitle(selectedCategory.rawValue, for: .normal)
        if let image = UIImage(systemName: selectedCategory.icon) {
            categoryButton.setImage(image, for: .normal)
        }
        
        // Update tags button
        if selectedTags.isEmpty {
            tagsButton.setTitle("Додати теги", for: .normal)
        } else {
            let tagsText = selectedTags.joined(separator: ", ")
            tagsButton.setTitle(tagsText, for: .normal)
        }
        
        // Update schedule button
        if let schedule = selectedSchedule {
            scheduleButton.setTitle(schedule, for: .normal)
        } else {
            scheduleButton.setTitle("Вибрати розклад", for: .normal)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.tintColor = ThemeManager.shared.accentColor
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
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
        if textView.textColor == theme.secondaryTextColor {
            textView.text = ""
            textView.textColor = theme.textColor
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        let theme = ThemeManager.shared
        if textView.text.isEmpty {
            textView.text = "Введіть опис завдання..."
            textView.textColor = theme.secondaryTextColor
        }
    }
}
