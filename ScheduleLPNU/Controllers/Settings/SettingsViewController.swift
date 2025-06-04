import UIKit
import PassKit

class SettingsViewController: UIViewController, PKPaymentAuthorizationViewControllerDelegate {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private var appThemeSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupThemeObserver()
        applyTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
        updateThemeControls()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // ДОДАТКОВО: Примусово оновлюємо Navigation Bar при появі view
        DispatchQueue.main.async {
            self.updateNavigationBarAppearance()
        }
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
        DispatchQueue.main.async {
            self.applyTheme()
            self.updateThemeControls()
        }
    }
    
    private func updateNavigationBarAppearance() {
        guard let navigationController = navigationController else { return }
        
        let theme = ThemeManager.shared
        
        // Оновлюємо tint color
        navigationController.navigationBar.tintColor = theme.accentColor
        
        // Оновлюємо title attributes
        navigationController.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: theme.accentColor,
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)
        ]
        
        // Для iOS 15+ оновлюємо appearance
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = theme.backgroundColor
            appearance.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: theme.accentColor,
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)
            ]
            
            navigationController.navigationBar.standardAppearance = appearance
            navigationController.navigationBar.scrollEdgeAppearance = appearance
            navigationController.navigationBar.compactAppearance = appearance
        }
        
        // Примусово оновлюємо layout
        navigationController.navigationBar.setNeedsLayout()
        navigationController.navigationBar.layoutIfNeeded()
    }
    
    private func applyTheme() {
        let theme = ThemeManager.shared
        
        view.backgroundColor = theme.backgroundColor
        
        // ВИПРАВЛЕНО: Оновлення Navigation Bar
        updateNavigationBarAppearance()
        
        // Tab Bar
        setupTabBar()
        
        // Recreate settings items to apply new theme
        recreateSettingsItems()
    }
    
    private func setupTabBar() {
        if let tabBar = tabBarController?.tabBar {
            let theme = ThemeManager.shared
            
            tabBar.backgroundColor = theme.backgroundColor
            tabBar.barTintColor = theme.backgroundColor
            
            if #available(iOS 15.0, *) {
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = theme.backgroundColor
                
                tabBar.standardAppearance = appearance
                tabBar.scrollEdgeAppearance = appearance
            }
            
            tabBar.tintColor = theme.accentColor
            tabBar.unselectedItemTintColor = theme.secondaryTextColor
        }
    }
    
    private func setupUI() {
        title = "НАЛАШТУВАННЯ"
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.axis = .vertical
        stackView.spacing = 20
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
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        // ДОДАНО: Constraint для мінімальної висоти content view
        let contentHeightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor)
        contentHeightConstraint.priority = UILayoutPriority(250)
        contentHeightConstraint.isActive = true
        
        createSettingsItems()
    }
    
    private func createSettingsItems() {
        // Theme Section
        let themeSection = createSectionCard(title: "Вигляд")
        
        let systemThemeItem = createSystemThemeItem()
        themeSection.addArrangedSubview(systemThemeItem)
        
        let appThemeItem = createAppThemeToggleItem()
        themeSection.addArrangedSubview(appThemeItem)
        
        let accentColorItem = createAccentColorItem()
        themeSection.addArrangedSubview(accentColorItem)
        
        stackView.addArrangedSubview(themeSection)
        
        // Academic Section
        let academicSection = createSectionCard(title: "Академічна статистика")
        
        // ВИПРАВЛЕНО: Додано action для кнопки обрахунку середнього балу
        let averageGradeItem = createSettingItem(
            title: "Обрахунок середнього балу",
            icon: "chart.bar.fill",
            action: #selector(gradeCalculatorTapped)
        )
        academicSection.addArrangedSubview(averageGradeItem)
        
        stackView.addArrangedSubview(academicSection)
        
        // Support Section
        let supportSection = createSectionCard(title: "Підтримка")
        
        let contactItem = createSettingItem(
            title: "Написати лист розробнику",
            icon: "envelope.fill",
            action: #selector(contactDeveloperTapped)
        )
        supportSection.addArrangedSubview(contactItem)
        
        let supportItem = createSettingItem(
            title: "Підтримати розробника",
            icon: "heart.fill",
            action: #selector(supportDeveloperTapped)
        )
        supportSection.addArrangedSubview(supportItem)
        
        let aboutItem = createSettingItem(
            title: "Про додаток",
            icon: "info.circle.fill",
            action: #selector(aboutAppTapped)
        )
        supportSection.addArrangedSubview(aboutItem)
        
        stackView.addArrangedSubview(supportSection)
    }
    
    private func recreateSettingsItems() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        createSettingsItems()
    }
    
    private func createSectionCard(title: String) -> UIStackView {
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
    
    private func createSystemThemeItem() -> UIView {
        let theme = ThemeManager.shared
        let container = UIView()
        
        let iconView = UIImageView(image: UIImage(systemName: "gear"))
        iconView.tintColor = theme.accentColor
        iconView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = "Слідувати системі"
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = theme.textColor
        
        let valueLabel = UILabel()
        valueLabel.text = theme.currentTheme == .system ? "Увімкнено" : "Вимкнено"
        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.textColor = theme.secondaryTextColor
        valueLabel.textAlignment = .right
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(systemThemeTapped))
        container.addGestureRecognizer(tapGesture)
        container.isUserInteractionEnabled = true
        
        container.addSubview(iconView)
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: valueLabel.leadingAnchor, constant: -12),
            
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            container.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return container
    }
    
    private func createAppThemeToggleItem() -> UIView {
        let theme = ThemeManager.shared
        let container = UIView()
        
        let iconView = UIImageView(image: UIImage(systemName: "moon.circle.fill"))
        iconView.tintColor = theme.accentColor
        iconView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = "Темна тема додатку"
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = theme.textColor
        
        appThemeSwitch = UISwitch()
        appThemeSwitch.isOn = theme.currentTheme == .dark || (theme.currentTheme == .system && theme.isDarkMode)
        appThemeSwitch.onTintColor = theme.accentColor
        appThemeSwitch.addTarget(self, action: #selector(appThemeSwitchChanged), for: .valueChanged)
        
        // Disable switch if following system
        appThemeSwitch.isEnabled = theme.currentTheme != .system
        appThemeSwitch.alpha = theme.currentTheme != .system ? 1.0 : 0.5
        
        container.addSubview(iconView)
        container.addSubview(titleLabel)
        container.addSubview(appThemeSwitch)
        
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        appThemeSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: appThemeSwitch.leadingAnchor, constant: -12),
            
            appThemeSwitch.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            appThemeSwitch.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            container.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return container
    }
    
    private func createAccentColorItem() -> UIView {
        let theme = ThemeManager.shared
        let container = UIView()
        
        let iconView = UIImageView(image: UIImage(systemName: "paintpalette.fill"))
        iconView.tintColor = theme.accentColor
        iconView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = "Кольоровий акцент"
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = theme.textColor
        
        let valueLabel = UILabel()
        // ВИПРАВЛЕНО: Показуємо правильну назву кольору
        if hasCustomColor() {
            valueLabel.text = "Власний"
        } else {
            valueLabel.text = theme.currentAccentColor.displayName
        }
        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.textColor = theme.accentColor
        valueLabel.textAlignment = .right
        
        let colorCircle = UIView()
        colorCircle.backgroundColor = theme.accentColor
        colorCircle.layer.cornerRadius = 10
        colorCircle.layer.borderWidth = 2
        colorCircle.layer.borderColor = theme.separatorColor.cgColor
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(accentColorTapped))
        container.addGestureRecognizer(tapGesture)
        container.isUserInteractionEnabled = true
        
        container.addSubview(iconView)
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        container.addSubview(colorCircle)
        
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        colorCircle.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            colorCircle.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            colorCircle.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            colorCircle.widthAnchor.constraint(equalToConstant: 20),
            colorCircle.heightAnchor.constraint(equalToConstant: 20),
            
            valueLabel.trailingAnchor.constraint(equalTo: colorCircle.leadingAnchor, constant: -8),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12),
            
            container.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return container
    }
    
    private func createSettingItem(title: String, icon: String, action: Selector?) -> UIView {
        let theme = ThemeManager.shared
        let container = UIView()
        
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = theme.accentColor
        iconView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = theme.textColor
        
        container.addSubview(iconView)
        container.addSubview(titleLabel)
        
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            container.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        if let action = action {
            let tapGesture = UITapGestureRecognizer(target: self, action: action)
            container.addGestureRecognizer(tapGesture)
            container.isUserInteractionEnabled = true
        }
        
        return container
    }
    
    private func createInfoLabel(title: String, value: String) -> UIView {
        let theme = ThemeManager.shared
        let container = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = theme.textColor
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 16)
        valueLabel.textColor = theme.accentColor
        valueLabel.textAlignment = .right
        
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: valueLabel.leadingAnchor, constant: -12),
            
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            
            container.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return container
    }
    
    // НОВИЙ: Метод для перевірки наявності власного кольору
    private func hasCustomColor() -> Bool {
        return UserDefaults.standard.array(forKey: "customAccentColor") != nil
    }
    
    // MARK: - Actions
    
    @objc private func systemThemeTapped() {
        let alert = UIAlertController(
            title: "Слідувати системі",
            message: "Коли увімкнено, тема додатку автоматично змінюється разом із системною темою.",
            preferredStyle: .alert
        )
        
        if ThemeManager.shared.currentTheme == .system {
            alert.addAction(UIAlertAction(title: "Вимкнути", style: .default) { _ in
                // Switch to current system appearance
                let isDark = ThemeManager.shared.isDarkMode
                ThemeManager.shared.currentTheme = isDark ? .dark : .light
            })
        } else {
            alert.addAction(UIAlertAction(title: "Увімкнути", style: .default) { _ in
                ThemeManager.shared.currentTheme = .system
            })
        }
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func appThemeSwitchChanged() {
        if ThemeManager.shared.currentTheme != .system {
            ThemeManager.shared.currentTheme = appThemeSwitch.isOn ? .dark : .light
        }
    }
    
    @objc private func accentColorTapped() {
        showCustomColorPicker()
    }
    
    // НОВИЙ: Метод для переходу до калькулятора середнього балу
    @objc private func gradeCalculatorTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let gradeVC = storyboard.instantiateViewController(withIdentifier: "GradeCalculatorViewController") as? GradeCalculatorViewController {
            navigationController?.pushViewController(gradeVC, animated: true)
        }
    }
    
    // ВИПРАВЛЕНО: Оновлений метод для вибору кольору
    private func showCustomColorPicker() {
        let alert = UIAlertController(title: "Виберіть кольоровий акцент", message: nil, preferredStyle: .actionSheet)
        
        // Додаємо стандартні кольори як дії
        for accentColor in AccentColor.allCases {
            let action = UIAlertAction(title: accentColor.displayName, style: .default) { _ in
                // ВИПРАВЛЕНО: Використовуємо setter для правильного оновлення
                ThemeManager.shared.currentAccentColor = accentColor
            }
            
            // ВИПРАВЛЕНО: Показуємо галочку для поточного кольору
            if accentColor == ThemeManager.shared.currentAccentColor && !self.hasCustomColor() {
                action.setValue(UIImage(systemName: "checkmark"), forKey: "image")
            }
            
            alert.addAction(action)
        }
        
        // Додаємо опцію вибору власного кольору
        let customAction = UIAlertAction(title: "Власний колір...", style: .default) { _ in
            self.showSystemColorPicker()
        }
        
        // ВИПРАВЛЕНО: Показуємо галочку для власного кольору
        if self.hasCustomColor() {
            customAction.setValue(UIImage(systemName: "checkmark"), forKey: "image")
        }
        
        alert.addAction(customAction)
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        // Для iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    // ВИПРАВЛЕНО: Оновлений метод для системного color picker
    private func showSystemColorPicker() {
        if #available(iOS 14.0, *) {
            let colorPicker = UIColorPickerViewController()
            colorPicker.selectedColor = ThemeManager.shared.accentColor
            colorPicker.delegate = self
            colorPicker.title = "Виберіть колір"
            
            // ВИПРАВЛЕНО: Показуємо як modal
            colorPicker.modalPresentationStyle = .formSheet
            present(colorPicker, animated: true)
        } else {
            let alert = UIAlertController(
                title: "Власний колір",
                message: "Вибір кольору доступний з iOS 14+",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    @objc private func contactDeveloperTapped() {
        // Створюємо mailto URL з правильним кодуванням
        let email = "den.brtvnk@gmail.com"
        let subject = "ScheduleLPNU Feedback"
        let body = """
                   Привіт!
                   
                   Хочу залишити відгук про додаток ScheduleLPNU:
                   
                   
                   """
        
        // Кодуємо параметри для URL
        guard let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            showEmailFallback()
            return
        }
        
        let mailtoString = "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)"
        
        guard let mailtoURL = URL(string: mailtoString) else {
            showEmailFallback()
            return
        }
        
        // Перевіряємо чи можна відкрити mailto URL
        if UIApplication.shared.canOpenURL(mailtoURL) {
            UIApplication.shared.open(mailtoURL, options: [:]) { success in
                if !success {
                    DispatchQueue.main.async {
                        self.showEmailFallback()
                    }
                }
            }
        } else {
            // Якщо mailto не працює, пробуємо альтернативні способи
            tryAlternativeEmailMethods(email: email, subject: subject, body: body)
        }
    }
    
    private func tryAlternativeEmailMethods(email: String, subject: String, body: String) {
        // Пробуємо різні email клієнти
        let emailClients = [
            "googlegmail://co?to=\(email)&subject=\(subject)&body=\(body)", // Gmail
            "ms-outlook://compose?to=\(email)&subject=\(subject)&body=\(body)", // Outlook
            "ymail://mail/compose?to=\(email)&subject=\(subject)&body=\(body)" // Yahoo Mail
        ]
        
        var clientOpened = false
        
        for clientURLString in emailClients {
            if let encodedURLString = clientURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let clientURL = URL(string: encodedURLString),
               UIApplication.shared.canOpenURL(clientURL) {
                UIApplication.shared.open(clientURL)
                clientOpened = true
                break
            }
        }
        
        if !clientOpened {
            showEmailFallback()
        }
    }
    
    private func showEmailFallback() {
        let alert = UIAlertController(
            title: "Написати листа",
            message: "Електронна пошта:\nden.brtvnk@gmail.com\n\nТема: ScheduleLPNU Feedback",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Копіювати email", style: .default) { _ in
            UIPasteboard.general.string = "den.brtvnk@gmail.com"
            
            let successAlert = UIAlertController(
                title: "Скопійовано!",
                message: "Email адресу скопійовано в буфер обміну",
                preferredStyle: .alert
            )
            successAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(successAlert, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func supportDeveloperTapped() {
        showDonationOptions()
    }
    
    private func showDonationOptions() {
        let alert = UIAlertController(
            title: "Підтримати розробника",
            message: "Дякую за використання ScheduleLPNU! Оберіть суму підтримки:",
            preferredStyle: .alert
        )
        
        // Додаємо кнопки з різними сумами
        let amounts = ["50", "100"]
        
        for amount in amounts {
            alert.addAction(UIAlertAction(title: "\(amount) грн", style: .default) { _ in
                self.processApplePayDonation(amount: amount)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Інша сума", style: .default) { _ in
            self.showCustomAmountInput()
        })
        
        alert.addAction(UIAlertAction(title: "Банківська карта", style: .default) { _ in
            self.showBankCardInfo()
        })
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showCustomAmountInput() {
        let alert = UIAlertController(title: "Сума підтримки", message: "Введіть суму в гривнях:", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Наприклад: 50"
            textField.keyboardType = .numberPad
        }
        
        alert.addAction(UIAlertAction(title: "Підтримати", style: .default) { _ in
            if let amount = alert.textFields?.first?.text, !amount.isEmpty {
                self.processApplePayDonation(amount: amount)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func processApplePayDonation(amount: String) {
        guard let amountValue = Double(amount), amountValue > 0 else {
            showAlert(title: "Помилка", message: "Введіть коректну суму")
            return
        }
        
        // Перевіряємо чи доступний Apple Pay
        guard PKPaymentAuthorizationViewController.canMakePayments() else {
            showAlert(title: "Apple Pay недоступний", message: "Apple Pay не налаштований на цьому пристрої")
            return
        }
        
        // Створюємо запит на оплату
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.denysbrativnyk.schedulelpnu" // Замініть на ваш merchant ID
        request.supportedNetworks = [.visa, .masterCard, .amex]
        request.merchantCapabilities = .capability3DS
        request.countryCode = "UA"
        request.currencyCode = "UAH"
        
        // Створюємо item для оплати
        let donationItem = PKPaymentSummaryItem(label: "Підтримка розробника ScheduleLPNU", amount: NSDecimalNumber(value: amountValue))
        request.paymentSummaryItems = [donationItem]
        
        // Показуємо Apple Pay контролер
        if let paymentController = PKPaymentAuthorizationViewController(paymentRequest: request) {
            paymentController.delegate = self
            present(paymentController, animated: true)
        } else {
            showAlert(title: "Помилка", message: "Не вдалося створити запит на оплату")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showBankCardInfo() {
        let alert = UIAlertController(
            title: "Підтримка розробника",
            message: "Карта Mono:\n4441 1110 6876 6264\n\nDenys Brativnyk",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Копіювати номер карти", style: .default) { _ in
            UIPasteboard.general.string = "4441111068766264"
            
            let successAlert = UIAlertController(
                title: "Скопійовано!",
                message: "Номер карти скопійовано в буфер обміну",
                preferredStyle: .alert
            )
            successAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(successAlert, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Закрити", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func aboutAppTapped() {
        let aboutVC = AboutAppViewController()
        let navController = UINavigationController(rootViewController: aboutVC)
        
        // Налаштовуємо презентацію
        navController.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = navController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }
        
        present(navController, animated: true)
    }
    
    private func updateThemeControls() {
        // This method updates the UI when theme changes
        let theme = ThemeManager.shared
        
        if let switchControl = appThemeSwitch {
            switchControl.isOn = theme.currentTheme == .dark || (theme.currentTheme == .system && theme.isDarkMode)
            switchControl.isEnabled = theme.currentTheme != .system
            switchControl.alpha = theme.currentTheme != .system ? 1.0 : 0.5
        }
    }
    
    // MARK: - Academic Statistics
    
    private func calculateAverageGrade() -> String {
        let tasks = TaskManager.shared.loadTasks()
        let completedTasks = tasks.filter { $0.isCompleted }
        
        guard !completedTasks.isEmpty else {
            return "Немає оцінок"
        }
        
        let totalGrade = completedTasks.reduce(0.0) { sum, task in
            return sum + getGradeFromTask(task)
        }
        
        let average = totalGrade / Double(completedTasks.count)
        return String(format: "%.2f", average)
    }
    
    private func getGradeFromTask(_ task: Task) -> Double {
        // Використовуємо priority як оцінку:
        switch task.priority {
        case .high:
            return 5.0
        case .medium:
            return 4.0
        case .low:
            return 3.0
        }
    }
    
    private func saveCustomColor(_ color: UIColor) {
        // Використовуємо новий метод ThemeManager
        ThemeManager.shared.setCustomAccentColor(color)
    }
    
    // MARK: - PKPaymentAuthorizationViewControllerDelegate
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        // Тут ви обробляєте платіж
        // У реальному додатку ви б відправили платіжні дані на ваш сервер
        
        // Для демонстрації просто підтверджуємо успішний платіж
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
        
        // Показуємо повідомлення про успішну підтримку
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let alert = UIAlertController(
                title: "Дякую!",
                message: "Дуже дякую за підтримку! Це допомагає розвивати додаток.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - UIColorPickerViewControllerDelegate
@available(iOS 14.0, *)
extension SettingsViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        let selectedColor = viewController.selectedColor
        
        // ВИПРАВЛЕНО: Використовуємо правильний метод для збереження
        ThemeManager.shared.setCustomAccentColor(selectedColor)
        
        viewController.dismiss(animated: true) {
            // ДОДАТКОВО: Примусово оновлюємо UI після закриття
            DispatchQueue.main.async {
                self.applyTheme()
                self.recreateSettingsItems()
            }
        }
    }
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        // Викликається при зміні кольору в реальному часі (опційно)
        // Можна використовувати для preview, але краще залишити порожнім
    }
    
    private func findClosestAccentColor(to color: UIColor) -> AccentColor {
        var closestColor = AccentColor.default
        var minDistance = CGFloat.greatestFiniteMagnitude
        
        for accentColor in AccentColor.allCases {
            let distance = colorDistance(color, accentColor.color)
            if distance < minDistance {
                minDistance = distance
                closestColor = accentColor
            }
        }
        
        return closestColor
    }
    
    private func colorDistance(_ color1: UIColor, _ color2: UIColor) -> CGFloat {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return sqrt(pow(r1 - r2, 2) + pow(g1 - g2, 2) + pow(b1 - b2, 2))
    }
}

// MARK: - AboutAppViewController

class AboutAppViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        DispatchQueue.main.async {
            self.applyTheme()
        }
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
        
        // Для iOS 15+ оновлюємо appearance
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
    }
    
    private func setupUI() {
        title = "ПРО ДОДАТОК"
        
        let theme = ThemeManager.shared
        view.backgroundColor = theme.backgroundColor
        
        // Кнопка закриття
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(dismissTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = theme.accentColor
        
        // Створюємо scroll view
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Контент
        let contentLabel = UILabel()
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.numberOfLines = 0
        contentLabel.font = UIFont.systemFont(ofSize: 16)
        contentLabel.textColor = theme.textColor
        contentLabel.textAlignment = .center
        
        // Оригінальний текст з файлу
        let message = """
        ScheduleLPNU 1.0
        
        © Денис Братівник 2025
        
        Додаток здійснює парсинг розкладу з офіційного сайту Львівської Політехніки та надає зручний інтерфейс для перегляду занять.
        
        При виникненні проблем з роботою додатку зверніться з деталями на пошту (Налаштування -> Написати лист розробнику).
        """
        
        contentLabel.text = message
        scrollView.addSubview(contentLabel)
        
        // Констрейнти
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }
    
    @objc private func dismissTapped() {
        dismiss(animated: true)
    }
}
