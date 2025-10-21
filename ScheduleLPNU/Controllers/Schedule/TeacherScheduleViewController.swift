//
//  TeacherScheduleViewController.swift
//  ScheduleLPNU
//
//  Created by Denys Brativnyk on 01.05.2025.
//

import UIKit

class TeacherScheduleViewController: UIViewController {
    
    // UI елементи
    private var teacherTextField: UITextField!
    private var semesterButton: UIButton!
    private var halfButton: UIButton!
    private var downloadButton: UIButton!
    
    // Labels для тематизації
    private var teacherLabel: UILabel!
    private var semesterLabel: UILabel!
    private var halfLabel: UILabel!
    
    // Додаємо прапорець для відстеження стану переходу
    private var isTransitioning = false
    
    // Дані
    private var selectedSemester = "1 семестр"
    private var selectedHalf = "перша половина" // ЗМІНЕНО
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupCustomTitleView()
        setupThemeObserver()
        applyTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isTransitioning = false
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
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)
        ]
        navigationController?.navigationBar.tintColor = theme.accentColor
        
        // Update title view
        if let titleLabel = navigationItem.titleView as? UILabel {
            titleLabel.textColor = theme.accentColor
        }
        
        // Text fields
        teacherTextField?.textColor = theme.textColor
        teacherTextField?.backgroundColor = theme.cardBackgroundColor
        teacherTextField?.layer.borderColor = theme.separatorColor.cgColor
        
        if let attributedPlaceholder = teacherTextField?.attributedPlaceholder {
            teacherTextField?.attributedPlaceholder = NSAttributedString(
                string: attributedPlaceholder.string,
                attributes: [NSAttributedString.Key.foregroundColor: theme.secondaryTextColor]
            )
        }
        
        // Icon tint
        if let leftView = teacherTextField?.leftView {
            for subview in leftView.subviews {
                if let imageView = subview as? UIImageView {
                    imageView.tintColor = theme.secondaryTextColor
                }
            }
        }
        
        // Buttons
        let buttons = [semesterButton, halfButton]
        buttons.forEach { button in
            button?.backgroundColor = theme.cardBackgroundColor
            button?.setTitleColor(theme.textColor, for: .normal)
            button?.layer.borderColor = theme.separatorColor.cgColor
        }
        
        // Download button
        downloadButton?.backgroundColor = theme.accentColor
    }
    
    private func setupUI() {
        createTeacherTextField()
        createSemesterButton()
        createHalfButton()
        createDownloadButton()
    }
    
    private func createTeacherTextField() {
        teacherTextField = UITextField()
        teacherTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Стиль
        teacherTextField.layer.cornerRadius = 12
        teacherTextField.layer.borderWidth = 1
        teacherTextField.placeholder = "Введіть ПІБ викладача повністю"
        teacherTextField.font = UIFont.systemFont(ofSize: 17)
        
        // Іконка пошуку зліва
        let searchIcon = UIImageView(frame: CGRect(x: 12, y: 7, width: 20, height: 20))
        searchIcon.image = UIImage(systemName: "magnifyingglass")
        searchIcon.contentMode = .scaleAspectFit
        
        let iconContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 34))
        iconContainerView.addSubview(searchIcon)
        teacherTextField.leftView = iconContainerView
        teacherTextField.leftViewMode = .always
        
        // Правий padding
        let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 34))
        teacherTextField.rightView = rightPaddingView
        teacherTextField.rightViewMode = .always
        
        view.addSubview(teacherTextField)
    }
    
    private func createSemesterButton() {
        semesterButton = UIButton(type: .system)
        semesterButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Стиль
        semesterButton.layer.cornerRadius = 12
        semesterButton.layer.borderWidth = 1
        
        // Тінь
        semesterButton.layer.shadowColor = UIColor.black.cgColor
        semesterButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        semesterButton.layer.shadowOpacity = 0.05
        semesterButton.layer.shadowRadius = 2
        
        // Текст
        semesterButton.setTitle(selectedSemester, for: .normal)
        semesterButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        
        // Дія
        semesterButton.addTarget(self, action: #selector(semesterButtonTapped), for: .touchUpInside)
        
        view.addSubview(semesterButton)
    }
    
    private func createHalfButton() {
        halfButton = UIButton(type: .system)
        halfButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Стиль
        halfButton.layer.cornerRadius = 12
        halfButton.layer.borderWidth = 1
        
        // Тінь
        halfButton.layer.shadowColor = UIColor.black.cgColor
        halfButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        halfButton.layer.shadowOpacity = 0.05
        halfButton.layer.shadowRadius = 2
        
        // Текст
        halfButton.setTitle(selectedHalf, for: .normal)
        halfButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        
        // Дія
        halfButton.addTarget(self, action: #selector(halfButtonTapped), for: .touchUpInside)
        
        view.addSubview(halfButton)
    }
    
    private func createDownloadButton() {
        downloadButton = UIButton(type: .system)
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Стиль
        downloadButton.setTitleColor(.white, for: .normal)
        downloadButton.layer.cornerRadius = 12
        downloadButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        
        // Легка тінь
        downloadButton.layer.shadowColor = UIColor.black.cgColor
        downloadButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        downloadButton.layer.shadowOpacity = 0.1
        downloadButton.layer.shadowRadius = 4
        
        // Текст
        downloadButton.setTitle("Завантажити", for: .normal)
        
        // Дія
        downloadButton.addTarget(self, action: #selector(downloadButtonTapped), for: .touchUpInside)
        
        view.addSubview(downloadButton)
    }
    
    private func setupConstraints() {
        // Лейбл "Викладач"
        teacherLabel = UILabel()
        teacherLabel.text = "Викладач"
        teacherLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        teacherLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(teacherLabel)
        
        // Контейнер для кнопок семестру та половини
        let buttonsContainer = UIView()
        buttonsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonsContainer)
        
        // Лейбл "Семестр"
        semesterLabel = UILabel()
        semesterLabel.text = "Семестр"
        semesterLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        semesterLabel.translatesAutoresizingMaskIntoConstraints = false
        buttonsContainer.addSubview(semesterLabel)
        
        // Лейбл "Половина"
        halfLabel = UILabel()
        halfLabel.text = "Половина"
        halfLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        halfLabel.translatesAutoresizingMaskIntoConstraints = false
        buttonsContainer.addSubview(halfLabel)
        
        // Додаємо кнопки в контейнер
        buttonsContainer.addSubview(semesterButton)
        buttonsContainer.addSubview(halfButton)
        
        NSLayoutConstraint.activate([
            // Лейбл викладача - висота 21
            teacherLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            teacherLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            teacherLabel.heightAnchor.constraint(equalToConstant: 21),
            
            // Текстове поле викладача - висота 34, відстань 8 від лейбла
            teacherTextField.topAnchor.constraint(equalTo: teacherLabel.bottomAnchor, constant: 8),
            teacherTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            teacherTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            teacherTextField.heightAnchor.constraint(equalToConstant: 34),
            
            // Контейнер кнопок - відстань 20 від текстового поля
            buttonsContainer.topAnchor.constraint(equalTo: teacherTextField.bottomAnchor, constant: 20),
            buttonsContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            buttonsContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            buttonsContainer.heightAnchor.constraint(equalToConstant: 63), // 21 + 8 + 34
            
            // Лейбл семестру - висота 21
            semesterLabel.topAnchor.constraint(equalTo: buttonsContainer.topAnchor),
            semesterLabel.leadingAnchor.constraint(equalTo: buttonsContainer.leadingAnchor),
            semesterLabel.heightAnchor.constraint(equalToConstant: 21),
            
            // Лейбл половини - висота 21, вирівнюється по лівому краю центральної частини
            halfLabel.topAnchor.constraint(equalTo: buttonsContainer.topAnchor),
            halfLabel.leadingAnchor.constraint(equalTo: buttonsContainer.centerXAnchor, constant: 6),
            halfLabel.heightAnchor.constraint(equalToConstant: 21),
            
            // Кнопка семестру - висота 34, відстань 8 від лейбла
            semesterButton.topAnchor.constraint(equalTo: semesterLabel.bottomAnchor, constant: 8),
            semesterButton.leadingAnchor.constraint(equalTo: buttonsContainer.leadingAnchor),
            semesterButton.trailingAnchor.constraint(equalTo: buttonsContainer.centerXAnchor, constant: -6),
            semesterButton.heightAnchor.constraint(equalToConstant: 34),
            
            // Кнопка половини - висота 34, відстань 8 від лейбла
            halfButton.topAnchor.constraint(equalTo: halfLabel.bottomAnchor, constant: 8),
            halfButton.leadingAnchor.constraint(equalTo: buttonsContainer.centerXAnchor, constant: 6),
            halfButton.trailingAnchor.constraint(equalTo: buttonsContainer.trailingAnchor),
            halfButton.heightAnchor.constraint(equalToConstant: 34),
            
            // Кнопка завантаження - висота 50, відстань 20 від кнопок
            downloadButton.topAnchor.constraint(equalTo: buttonsContainer.bottomAnchor, constant: 20),
            downloadButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            downloadButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            downloadButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupCustomTitleView() {
        let title = "РОЗКЛАД ЗАНЯТЬ ДЛЯ ВИКЛАДАЧІВ ЗІ СТУДЕНТАМИ"
        let labelWidth: CGFloat = 280
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: labelWidth, height: 50))
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.5
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.preferredMaxLayoutWidth = labelWidth
        titleLabel.sizeToFit()
        
        var frame = titleLabel.frame
        frame.size.width = labelWidth
        titleLabel.frame = frame
        
        self.navigationItem.titleView = titleLabel
    }
    
    // MARK: - Дії кнопок
    @objc private func semesterButtonTapped() {
        let alert = UIAlertController(title: "Оберіть семестр", message: nil, preferredStyle: .actionSheet)
        alert.view.tintColor = ThemeManager.shared.accentColor
        
        let semester1 = UIAlertAction(title: "1 семестр", style: .default) { [weak self] _ in
            self?.selectedSemester = "1 семестр"
            self?.semesterButton.setTitle("1 семестр", for: .normal)
        }
        
        let semester2 = UIAlertAction(title: "2 семестр", style: .default) { [weak self] _ in
            self?.selectedSemester = "2 семестр"
            self?.semesterButton.setTitle("2 семестр", for: .normal)
        }
        
        let cancel = UIAlertAction(title: "Скасувати", style: .cancel)
        
        alert.addAction(semester1)
        alert.addAction(semester2)
        alert.addAction(cancel)
        
        // Для iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = semesterButton
            popover.sourceRect = semesterButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc private func halfButtonTapped() {
        let alert = UIAlertController(title: "Оберіть тривалість", message: nil, preferredStyle: .actionSheet)
        alert.view.tintColor = ThemeManager.shared.accentColor
        
        // ЗМІНЕНО: нові опції
        let firstHalf = UIAlertAction(title: "Весь семестр та перша половина", style: .default) { [weak self] _ in
            self?.selectedHalf = "Весь семестр та перша половина"
            self?.halfButton.setTitle("перша половина", for: .normal)
        }
        
        let secondHalf = UIAlertAction(title: "Весь семестр та друга половина", style: .default) { [weak self] _ in
            self?.selectedHalf = "Весь семестр та друга половина"
            self?.halfButton.setTitle("друга половина", for: .normal)
        }
        
        let cancel = UIAlertAction(title: "Скасувати", style: .cancel)
        
        alert.addAction(firstHalf)
        alert.addAction(secondHalf)
        alert.addAction(cancel)
        
        // Для iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = halfButton
            popover.sourceRect = halfButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc private func downloadButtonTapped() {
        guard !isTransitioning else { return }
        
        // Анімація кнопки
        UIView.animate(withDuration: 0.1, animations: {
            self.downloadButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.downloadButton.transform = CGAffineTransform.identity
            } completion: { _ in
                self.validateAndNavigate()
            }
        }
    }
    
    private func validateAndNavigate() {
        guard !isTransitioning else { return }
        
        guard let teacherText = teacherTextField.text, !teacherText.isEmpty else {
            showAlert(title: "Помилка", message: "Введіть ПІБ викладача повністю")
            return
        }
        
        isTransitioning = true
        
        // Програмна навігація або segue
        navigateToResults()
    }
    
    private func navigateToResults() {
        // Якщо у вас є segue:
        // performSegue(withIdentifier: "showTeacherScheduleResult", sender: self)
        
        // Або програмна навігація:
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let resultVC = storyboard.instantiateViewController(withIdentifier: "ResultTeacherScheduleViewController") as? ResultTeacherScheduleViewController {
            resultVC.teacherName = teacherTextField.text ?? ""
            resultVC.semester = selectedSemester
            resultVC.semesterDuration = selectedHalf
            navigationController?.pushViewController(resultVC, animated: true)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.tintColor = ThemeManager.shared.accentColor
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }
}
