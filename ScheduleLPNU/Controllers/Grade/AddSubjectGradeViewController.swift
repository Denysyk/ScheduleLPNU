import UIKit

class AddSubjectGradeViewController: BaseFullScreenViewController {
    
    // UI елементи (програмно)
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var subjectNameTextField: UITextField!
    private var creditsTextField: UITextField!
    private var gradeTextField: UITextField!
    private var saveButton: UIButton!
    
    // Labels для тематизації
    private var subjectNameLabel: UILabel!
    private var creditsLabel: UILabel!
    private var gradeLabel: UILabel!
    
    // Дані
    private var selectedCredits = 3
    private var selectedGrade = 94.0 // Відмінно за замовчуванням
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupThemeObserver()
        applyTheme()
        setupNotificationObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotificationObserver() {
        // Додаємо спостерігача для оновлення списку предметів
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(gradeWasAdded),
            name: NSNotification.Name("GradeWasAdded"),
            object: nil
        )
    }
    
    @objc private func gradeWasAdded() {
        // Можна додати тут додаткову логіку якщо потрібно
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
        
        // Navigation Bar
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: theme.accentColor,
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)
        ]
        navigationController?.navigationBar.tintColor = theme.accentColor
        
        // Scroll view
        scrollView.backgroundColor = theme.backgroundColor
        contentView.backgroundColor = theme.backgroundColor
        
        // Labels
        subjectNameLabel.textColor = theme.accentColor
        creditsLabel.textColor = theme.accentColor
        gradeLabel.textColor = theme.accentColor
        
        // Text fields
        let textFields = [subjectNameTextField, creditsTextField, gradeTextField]
        textFields.forEach { textField in
            textField?.backgroundColor = theme.cardBackgroundColor
            textField?.textColor = theme.textColor
            textField?.layer.borderColor = theme.separatorColor.cgColor
        }
        
        // Update placeholders
        updatePlaceholders()
        
        // Save button
        saveButton.backgroundColor = theme.accentColor
    }
    
    private func updatePlaceholders() {
        let theme = ThemeManager.shared
        let placeholderColor = theme.secondaryTextColor
        
        if let placeholder = subjectNameTextField.placeholder {
            subjectNameTextField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [NSAttributedString.Key.foregroundColor: placeholderColor]
            )
        }
        
        if let placeholder = creditsTextField.placeholder {
            creditsTextField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [NSAttributedString.Key.foregroundColor: placeholderColor]
            )
        }
        
        if let placeholder = gradeTextField.placeholder {
            gradeTextField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [NSAttributedString.Key.foregroundColor: placeholderColor]
            )
        }
    }
    
    private func setupUI() {
        title = "ДОДАТИ ПРЕДМЕТ"
        
        // Navigation buttons
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Скасувати",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
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
        
        createSubjectNameField()
        createCreditsField()
        createGradeField()
        createSaveButton()
    }
    
    private func createSubjectNameField() {
        subjectNameLabel = UILabel()
        subjectNameLabel.text = "Назва предмету"
        subjectNameLabel.font = .systemFont(ofSize: 16, weight: .regular)
        contentView.addSubview(subjectNameLabel)
        
        subjectNameTextField = UITextField()
        subjectNameTextField.layer.cornerRadius = 12
        subjectNameTextField.layer.borderWidth = 1
        subjectNameTextField.placeholder = "Введіть назву предмету"
        subjectNameTextField.font = UIFont.systemFont(ofSize: 17)
        
        // Левий padding
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 44))
        subjectNameTextField.leftView = leftPaddingView
        subjectNameTextField.leftViewMode = .always
        
        // Правий padding
        let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 44))
        subjectNameTextField.rightView = rightPaddingView
        subjectNameTextField.rightViewMode = .always
        
        contentView.addSubview(subjectNameTextField)
        
        // Додаємо кнопку для імпорту з розкладу
        let importButton = UIButton(type: .system)
        importButton.setTitle("Імпортувати з розкладу", for: .normal)
        importButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        importButton.addTarget(self, action: #selector(importFromScheduleTapped), for: .touchUpInside)
        contentView.addSubview(importButton)
        
        // Apply theme to import button
        DispatchQueue.main.async {
            let theme = ThemeManager.shared
            importButton.setTitleColor(theme.accentColor, for: .normal)
        }
        
        importButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            importButton.topAnchor.constraint(equalTo: subjectNameTextField.bottomAnchor, constant: 8),
            importButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    private func createCreditsField() {
        creditsLabel = UILabel()
        creditsLabel.text = "Кількість кредитів"
        creditsLabel.font = .systemFont(ofSize: 16, weight: .regular)
        contentView.addSubview(creditsLabel)
        
        creditsTextField = UITextField()
        creditsTextField.layer.cornerRadius = 12
        creditsTextField.layer.borderWidth = 1
        creditsTextField.placeholder = "Введіть кількість кредитів (1-9)"
        creditsTextField.font = UIFont.systemFont(ofSize: 17)
        creditsTextField.keyboardType = .numberPad
        creditsTextField.text = "" // Порожнє поле за замовчуванням
        
        // Левий padding
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 44))
        creditsTextField.leftView = leftPaddingView
        creditsTextField.leftViewMode = .always
        
        // Правий padding
        let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 44))
        creditsTextField.rightView = rightPaddingView
        creditsTextField.rightViewMode = .always
        
        contentView.addSubview(creditsTextField)
    }
    
    private func createGradeField() {
        gradeLabel = UILabel()
        gradeLabel.text = "Оцінка (0-100 балів)"
        gradeLabel.font = .systemFont(ofSize: 16, weight: .regular)
        contentView.addSubview(gradeLabel)
        
        gradeTextField = UITextField()
        gradeTextField.layer.cornerRadius = 12
        gradeTextField.layer.borderWidth = 1
        gradeTextField.placeholder = "Введіть оцінку (0-100)"
        gradeTextField.font = UIFont.systemFont(ofSize: 17)
        gradeTextField.keyboardType = .numberPad
        gradeTextField.text = "" // Порожнє поле за замовчуванням
        
        // Левий padding
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 44))
        gradeTextField.leftView = leftPaddingView
        gradeTextField.leftViewMode = .always
        
        // Правий padding
        let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 44))
        gradeTextField.rightView = rightPaddingView
        gradeTextField.rightViewMode = .always
        
        contentView.addSubview(gradeTextField)
        
        // Додаємо підказку про діапазони оцінок
        let hintLabel = UILabel()
        hintLabel.text = "88-100: Відмінно • 80-87: Дуже добре • 71-79: Добре"
        hintLabel.font = .systemFont(ofSize: 12)
        hintLabel.numberOfLines = 0
        hintLabel.textAlignment = .center
        contentView.addSubview(hintLabel)
        
        // Apply theme to hint
        DispatchQueue.main.async {
            let theme = ThemeManager.shared
            hintLabel.textColor = theme.secondaryTextColor
        }
        
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hintLabel.topAnchor.constraint(equalTo: gradeTextField.bottomAnchor, constant: 8),
            hintLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            hintLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    private func createSaveButton() {
        saveButton = UIButton(type: .system)
        saveButton.setTitle("Зберегти", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        saveButton.layer.cornerRadius = 12
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        contentView.addSubview(saveButton)
    }
    
    private func setupConstraints() {
        [scrollView, contentView, subjectNameLabel, subjectNameTextField,
         creditsLabel, creditsTextField, gradeLabel, gradeTextField, saveButton].forEach {
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
            
            // Subject name
            subjectNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            subjectNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            subjectNameTextField.topAnchor.constraint(equalTo: subjectNameLabel.bottomAnchor, constant: 8),
            subjectNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            subjectNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            subjectNameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Credits
            creditsLabel.topAnchor.constraint(equalTo: subjectNameTextField.bottomAnchor, constant: 44),
            creditsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            creditsTextField.topAnchor.constraint(equalTo: creditsLabel.bottomAnchor, constant: 8),
            creditsTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            creditsTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            creditsTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Grade
            gradeLabel.topAnchor.constraint(equalTo: creditsTextField.bottomAnchor, constant: 24),
            gradeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            gradeTextField.topAnchor.constraint(equalTo: gradeLabel.bottomAnchor, constant: 8),
            gradeTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            gradeTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            gradeTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Save button
            saveButton.topAnchor.constraint(equalTo: gradeTextField.bottomAnchor, constant: 60),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
        
        // Додаємо constraint для мінімальної висоти content view
        let contentHeightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor)
        contentHeightConstraint.priority = UILayoutPriority(250)
        contentHeightConstraint.isActive = true
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func importFromScheduleTapped() {
        // Спочатку показуємо збережені розклади
        let savedSchedules = ScheduleManager.shared.getSavedSchedules()
        
        guard !savedSchedules.isEmpty else {
            showAlert(title: "Немає розкладів", message: "Спочатку завантажте та збережіть розклад")
            return
        }
        
        let alert = UIAlertController(title: "Виберіть розклад", message: nil, preferredStyle: .actionSheet)
        
        for schedule in savedSchedules {
            let action = UIAlertAction(title: schedule.title, style: .default) { [weak self] _ in
                self?.showSubjectsFromSchedule(schedule)
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        // Для iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    private func showSubjectsFromSchedule(_ schedule: SavedSchedule) {
        var subjectNames: Set<String> = []
        
        // Збираємо всі предмети з вибраного розкладу
        for day in schedule.scheduleDays {
            for lesson in day.lessons {
                if !lesson.name.isEmpty && lesson.name != "Невідомо" {
                    subjectNames.insert(lesson.name)
                }
            }
        }
        
        let subjects = Array(subjectNames).sorted()
        
        guard !subjects.isEmpty else {
            showAlert(title: "Немає предметів", message: "У вибраному розкладі немає предметів")
            return
        }
        
        let alert = UIAlertController(title: "Виберіть предмет", message: "Розклад: \(schedule.title)", preferredStyle: .actionSheet)
        
        for subject in subjects {
            // НЕ перевіряємо чи вже є оцінка - дозволяємо додавати один предмет кілька разів
            let action = UIAlertAction(title: subject, style: .default) { [weak self] _ in
                self?.subjectNameTextField.text = subject
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        // Для iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    @objc private func saveButtonTapped() {
        guard let subjectName = subjectNameTextField.text, !subjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "Помилка", message: "Введіть назву предмету")
            return
        }
        
        guard let creditsText = creditsTextField.text, let credits = Int(creditsText), credits >= 1 && credits <= 9 else {
            showAlert(title: "Помилка", message: "Введіть коректну кількість кредитів (1-8)")
            return
        }
        
        guard let gradeText = gradeTextField.text, let grade = Double(gradeText), grade >= 0 && grade <= 100 else {
            showAlert(title: "Помилка", message: "Введіть коректну оцінку (0-100)")
            return
        }
        
        let trimmedName = subjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // НЕ перевіряємо на дублікати - дозволяємо додавати один предмет кілька разів
        
        let newGrade = SubjectGrade(
            name: trimmedName,
            credits: credits,
            grade: grade
        )
        
        GradeManager.shared.addGrade(newGrade)
        
        // Відправляємо notification про додавання оцінки
        NotificationCenter.default.post(name: NSNotification.Name("GradeWasAdded"), object: nil)
        
        dismiss(animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.tintColor = ThemeManager.shared.accentColor
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }
}
