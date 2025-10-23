//
//  SearchViewController.swift
//  ScheduleLPNU
//
//  Created by Denys Brativnyk on 30.04.2025.
//

import UIKit

class SearchViewController: BaseFullScreenViewController {
    
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
        applyTheme()
        // Оновлюємо градієнти кнопок
        view.subviews.forEach { subview in
            updateGradientLayers(in: subview)
        }
    }
    
    private func applyTheme() {
        let theme = ThemeManager.shared
        
        title = "ПОШУК"
        view.backgroundColor = theme.backgroundColor
    }
    
    private func setupUI() {
        // Створюємо ScrollView
        let scrollView = UIScrollView()
        let contentView = UIView()
        let mainStack = UIStackView()
        
        // Налаштування ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(mainStack)
        
        // Налаштування головного Stack
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.distribution = .fill
        
        // Створюємо кнопки
        createButtons(in: mainStack)
        
        // Constraints
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
            
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            mainStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    private func createButtons(in stackView: UIStackView) {
        // Ряд 1
        let row1 = createRow(
            button1: ("Розклад занять для студентів", #selector(btn1Tapped)),
            button2: ("Розклад занять для викладачів зі студентами", #selector(btn2Tapped))
        )
        stackView.addArrangedSubview(row1)
        
        // Ряд 2
        let row2 = createRow(
            button1: ("Розклад занять для аспірантів", #selector(btn3Tapped)),
            button2: ("Розклад занять вибіркових дисциплін", #selector(btn4Tapped))
        )
        stackView.addArrangedSubview(row2)
        
        // Ряд 3
        let row3 = createRow(
            button1: ("Розклад екзаменів для студентів та аспірантів", #selector(btn5Tapped)),
            button2: ("Розклад екзаменів для викладачів", #selector(btn6Tapped))
        )
        stackView.addArrangedSubview(row3)
        
        // Ряд 4
        let row4 = createRow(
            button1: ("Розклад занять для студентів-заочників", #selector(btn7Tapped)),
            button2: ("Розклад занять для викладачів зі студентами-заочниками", #selector(btn8Tapped))
        )
        stackView.addArrangedSubview(row4)
        
        // Ряд 5 (одна широка кнопка)
        let wideButton = createButton(
            title: "Розклад занять для аспірантів-заочників",
            action: #selector(btn9Tapped)
        )
        stackView.addArrangedSubview(wideButton)
    }
    
    private func createRow(button1: (String, Selector), button2: (String, Selector)) -> UIStackView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.spacing = 8
        rowStack.distribution = .fillEqually
        
        let btn1 = createButton(title: button1.0, action: button1.1)
        let btn2 = createButton(title: button2.0, action: button2.1)
        
        rowStack.addArrangedSubview(btn1)
        rowStack.addArrangedSubview(btn2)
        
        return rowStack
    }
    
    private func createButton(title: String, action: Selector) -> UIButton {
        let theme = ThemeManager.shared
        let button = UIButton(type: .system)
        
        // Текст
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.setTitleColor(.white, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        
        // Сучасний стиль
        button.backgroundColor = theme.accentColor
        button.layer.cornerRadius = 14
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.08
        button.layer.shadowRadius = 6
        
        // Градієнт
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            theme.primaryGradientStart.cgColor,
            theme.primaryGradientEnd.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 14
        button.layer.insertSublayer(gradientLayer, at: 0)
        
        // Анімація натискання
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        // Дія
        button.addTarget(self, action: action, for: .touchUpInside)
        
        // Розмір
        button.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        // Оновлення градієнту при зміні розміру
        DispatchQueue.main.async {
            gradientLayer.frame = button.bounds
        }
        
        return button
    }
    
    // MARK: - Анімації кнопок
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            sender.alpha = 0.8
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform.identity
            sender.alpha = 1.0
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Оновлюємо градієнти після зміни розміру
        view.subviews.forEach { subview in
            updateGradientLayers(in: subview)
        }
    }
    
    private func updateGradientLayers(in view: UIView) {
        if let button = view as? UIButton {
            if let gradientLayer = button.layer.sublayers?.first as? CAGradientLayer {
                gradientLayer.frame = button.bounds
                
                // Оновлюємо кольори градієнту відповідно до поточної теми
                let theme = ThemeManager.shared
                gradientLayer.colors = [
                    theme.primaryGradientStart.cgColor,
                    theme.primaryGradientEnd.cgColor
                ]
            }
        }
        
        view.subviews.forEach { subview in
            updateGradientLayers(in: subview)
        }
    }
    
    // MARK: - Дії кнопок
    @objc private func btn1Tapped() {
        print("Кнопка 1: Розклад студентів")
        performSegue(withIdentifier: "showStudentSchedule", sender: self)
    }
    
    @objc private func btn2Tapped() {
        print("Кнопка 2: Розклад викладачів зі студентами")
        performSegue(withIdentifier: "showTeacherSchedule", sender: self)
    }
    
    @objc private func btn3Tapped() {
        print("Кнопка 3: Розклад аспірантів")
        performSegue(withIdentifier: "showPhdSchedule", sender: self)
    }
    
    @objc private func btn4Tapped() {
        print("Кнопка 4: Розклад вибіркових")
        performSegue(withIdentifier: "showElectiveSchedule", sender: self)
    }
    
    @objc private func btn5Tapped() {
        print("Кнопка 5: Екзамени студентів")
        performSegue(withIdentifier: "showStudentExams", sender: self)
    }
    
    @objc private func btn6Tapped() {
        print("Кнопка 6: Екзамени викладачів")
        performSegue(withIdentifier: "showTeacherExams", sender: self)
    }
    
    @objc private func btn7Tapped() {
        print("Кнопка 7: Розклад заочників")
        performSegue(withIdentifier: "showExternalStudents", sender: self)
    }
    
    @objc private func btn8Tapped() {
        print("Кнопка 8: Викладачі із заочниками")
        performSegue(withIdentifier: "showExternalTeachers", sender: self)
    }
    
    @objc private func btn9Tapped() {
        print("Кнопка 9: Аспіранти-заочники")
        performSegue(withIdentifier: "showExternalPhd", sender: self)
    }
}
