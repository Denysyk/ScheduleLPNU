//
//  TaskTableViewCell.swift
//  ScheduleLPNU
//

import UIKit

class TaskTableViewCell: UITableViewCell {
    // UI Elements
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let priorityView = UIView()
    private let priorityLabel = UILabel()
    private let dueDateLabel = UILabel()
    private let completionButton = UIButton()
    private let scheduleLabel = UILabel()
    private let categoryView = UIView()
    private let categoryIconView = UIImageView()
    private let categoryLabel = UILabel()
    private let tagsStackView = UIStackView()
    private let tagsScrollView = UIScrollView()
    private let calendarIndicator = UIImageView() // НОВЕ
    
    var onCompletionToggle: ((String) -> Void)?
    private var taskId: String?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupThemeObserver()
        applyTheme()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
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
    }
    
    private func applyTheme() {
        let theme = ThemeManager.shared
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        containerView.backgroundColor = theme.cardBackgroundColor
        
        if theme.isDarkMode {
            containerView.layer.shadowOpacity = 0
        } else {
            containerView.layer.shadowColor = UIColor.black.cgColor
            containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
            containerView.layer.shadowRadius = 4
            containerView.layer.shadowOpacity = 0.08
        }
        
        titleLabel.textColor = theme.textColor
        descriptionLabel.textColor = theme.secondaryTextColor
        dueDateLabel.textColor = theme.secondaryTextColor
        scheduleLabel.textColor = theme.accentColor
        categoryLabel.textColor = theme.accentColor
        categoryIconView.tintColor = theme.accentColor
        
        categoryView.backgroundColor = theme.accentColor.withAlphaComponent(0.1)
        
        completionButton.layer.borderColor = theme.secondaryTextColor.cgColor
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        containerView.layer.cornerRadius = 12
        containerView.layer.masksToBounds = false
        
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.numberOfLines = 0
        
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.numberOfLines = 2
        
        priorityView.layer.cornerRadius = 10
        priorityLabel.font = .systemFont(ofSize: 12, weight: .medium)
        priorityLabel.textColor = .white
        priorityLabel.textAlignment = .center
        
        categoryView.layer.cornerRadius = 8
        categoryIconView.contentMode = .scaleAspectFit
        categoryLabel.font = .systemFont(ofSize: 12, weight: .medium)
        
        dueDateLabel.font = .systemFont(ofSize: 12)
        scheduleLabel.font = .systemFont(ofSize: 12)
        
        tagsScrollView.showsHorizontalScrollIndicator = false
        tagsScrollView.showsVerticalScrollIndicator = false
        
        tagsStackView.axis = .horizontal
        tagsStackView.spacing = 6
        tagsStackView.alignment = .center
        
        completionButton.layer.cornerRadius = 12
        completionButton.layer.borderWidth = 2
        completionButton.addTarget(self, action: #selector(completionButtonTapped), for: .touchUpInside)
        
        // НОВЕ: Налаштування індикатора календаря
        calendarIndicator.image = UIImage(systemName: "calendar.badge.clock")
        calendarIndicator.contentMode = .scaleAspectFit
        calendarIndicator.tintColor = .systemBlue
        calendarIndicator.isHidden = true
        
        contentView.addSubview(containerView)
        
        [titleLabel, descriptionLabel, priorityView, dueDateLabel, completionButton,
         scheduleLabel, categoryView, tagsScrollView, calendarIndicator].forEach {
            containerView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        priorityView.addSubview(priorityLabel)
        categoryView.addSubview(categoryIconView)
        categoryView.addSubview(categoryLabel)
        tagsScrollView.addSubview(tagsStackView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        priorityLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryIconView.translatesAutoresizingMaskIntoConstraints = false
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        tagsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            completionButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            completionButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            completionButton.widthAnchor.constraint(equalToConstant: 24),
            completionButton.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: completionButton.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: calendarIndicator.leadingAnchor, constant: -8),
            
            // НОВЕ: Індикатор календаря
            calendarIndicator.trailingAnchor.constraint(equalTo: priorityView.leadingAnchor, constant: -8),
            calendarIndicator.centerYAnchor.constraint(equalTo: priorityView.centerYAnchor),
            calendarIndicator.widthAnchor.constraint(equalToConstant: 20),
            calendarIndicator.heightAnchor.constraint(equalToConstant: 20),
            
            priorityView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            priorityView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            priorityView.widthAnchor.constraint(equalToConstant: 70),
            priorityView.heightAnchor.constraint(equalToConstant: 20),
            
            priorityLabel.centerXAnchor.constraint(equalTo: priorityView.centerXAnchor),
            priorityLabel.centerYAnchor.constraint(equalTo: priorityView.centerYAnchor),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            categoryView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            categoryView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8),
            categoryView.heightAnchor.constraint(equalToConstant: 24),
            
            categoryIconView.leadingAnchor.constraint(equalTo: categoryView.leadingAnchor, constant: 6),
            categoryIconView.centerYAnchor.constraint(equalTo: categoryView.centerYAnchor),
            categoryIconView.widthAnchor.constraint(equalToConstant: 16),
            categoryIconView.heightAnchor.constraint(equalToConstant: 16),
            
            categoryLabel.leadingAnchor.constraint(equalTo: categoryIconView.trailingAnchor, constant: 4),
            categoryLabel.centerYAnchor.constraint(equalTo: categoryView.centerYAnchor),
            categoryLabel.trailingAnchor.constraint(equalTo: categoryView.trailingAnchor, constant: -6),
            
            tagsScrollView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            tagsScrollView.topAnchor.constraint(equalTo: categoryView.bottomAnchor, constant: 8),
            tagsScrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            tagsScrollView.heightAnchor.constraint(equalToConstant: 20),
            
            tagsStackView.topAnchor.constraint(equalTo: tagsScrollView.topAnchor),
            tagsStackView.leadingAnchor.constraint(equalTo: tagsScrollView.leadingAnchor),
            tagsStackView.trailingAnchor.constraint(equalTo: tagsScrollView.trailingAnchor),
            tagsStackView.bottomAnchor.constraint(equalTo: tagsScrollView.bottomAnchor),
            tagsStackView.heightAnchor.constraint(equalTo: tagsScrollView.heightAnchor),
            
            dueDateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dueDateLabel.topAnchor.constraint(equalTo: tagsScrollView.bottomAnchor, constant: 8),
            
            scheduleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            scheduleLabel.centerYAnchor.constraint(equalTo: dueDateLabel.centerYAnchor),
            scheduleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: dueDateLabel.trailingAnchor, constant: 8),
            
            containerView.bottomAnchor.constraint(greaterThanOrEqualTo: dueDateLabel.bottomAnchor, constant: 16)
        ])
    }
    
    func configure(with task: Task) {
        taskId = task.id
        titleLabel.text = task.title
        
        if let description = task.description, !description.isEmpty {
            descriptionLabel.text = description
            descriptionLabel.isHidden = false
        } else {
            descriptionLabel.isHidden = true
        }
        
        priorityLabel.text = task.priority.rawValue
        priorityView.backgroundColor = task.priority.color
        
        categoryLabel.text = task.category.rawValue
        categoryIconView.image = UIImage(systemName: task.category.icon)
        
        setupTags(task.tags)
        
        // НОВЕ: Показуємо індикатор календаря
        calendarIndicator.isHidden = !task.isInCalendar
        
        if let dueDate = task.dueDate {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "uk_UA")
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            formatter.dateFormat = "dd MMMM yyyy 'о' HH:mm"
            
            dueDateLabel.text = "📅 \(formatter.string(from: dueDate))"
            dueDateLabel.textColor = ThemeManager.shared.secondaryTextColor
        } else {
            dueDateLabel.text = ""
        }
        
        if let schedule = task.associatedSchedule {
            scheduleLabel.text = "🗓 \(schedule)"
        } else {
            scheduleLabel.text = ""
        }
        
        updateCompletionState(task.isCompleted)
    }
    
    func setSelectionMode(_ isSelected: Bool) {
        let theme = ThemeManager.shared
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut) {
            if isSelected {
                let selectionColor = theme.accentColor
                
                self.containerView.backgroundColor = selectionColor.withAlphaComponent(0.08)
                self.containerView.layer.shadowColor = selectionColor.cgColor
                self.containerView.layer.shadowOffset = CGSize(width: 0, height: 6)
                self.containerView.layer.shadowRadius = 12
                self.containerView.layer.shadowOpacity = 0.25
                
                self.containerView.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
                
                self.containerView.layer.borderWidth = 1.5
                self.containerView.layer.borderColor = selectionColor.withAlphaComponent(0.4).cgColor
                
                self.containerView.subviews.first(where: { $0.tag == 999 })?.removeFromSuperview()
                
                let checkIcon = UIView()
                checkIcon.tag = 999
                checkIcon.backgroundColor = selectionColor
                checkIcon.layer.cornerRadius = 15
                checkIcon.layer.shadowColor = selectionColor.cgColor
                checkIcon.layer.shadowOffset = CGSize(width: 0, height: 2)
                checkIcon.layer.shadowRadius = 4
                checkIcon.layer.shadowOpacity = 0.3
                
                let checkmark = UIImageView(image: UIImage(systemName: "checkmark"))
                checkmark.tintColor = .white
                checkmark.contentMode = .scaleAspectFit
                
                checkIcon.addSubview(checkmark)
                self.containerView.addSubview(checkIcon)
                
                checkIcon.translatesAutoresizingMaskIntoConstraints = false
                checkmark.translatesAutoresizingMaskIntoConstraints = false
                
                NSLayoutConstraint.activate([
                    checkIcon.topAnchor.constraint(equalTo: self.containerView.topAnchor, constant: 12),
                    checkIcon.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor, constant: -12),
                    checkIcon.widthAnchor.constraint(equalToConstant: 30),
                    checkIcon.heightAnchor.constraint(equalToConstant: 30),
                    
                    checkmark.centerXAnchor.constraint(equalTo: checkIcon.centerXAnchor),
                    checkmark.centerYAnchor.constraint(equalTo: checkIcon.centerYAnchor),
                    checkmark.widthAnchor.constraint(equalToConstant: 16),
                    checkmark.heightAnchor.constraint(equalToConstant: 16)
                ])
                
                checkIcon.alpha = 0
                checkIcon.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                
                UIView.animate(withDuration: 0.4, delay: 0.1, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: .curveEaseOut) {
                    checkIcon.alpha = 1
                    checkIcon.transform = CGAffineTransform.identity
                }
                
            } else {
                self.containerView.backgroundColor = theme.cardBackgroundColor
                
                if theme.isDarkMode {
                    self.containerView.layer.shadowOpacity = 0
                } else {
                    self.containerView.layer.shadowColor = UIColor.black.cgColor
                    self.containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
                    self.containerView.layer.shadowRadius = 4
                    self.containerView.layer.shadowOpacity = 0.08
                }
                
                self.containerView.transform = CGAffineTransform.identity
                self.containerView.layer.borderWidth = 0
                
                if let checkIcon = self.containerView.subviews.first(where: { $0.tag == 999 }) {
                    UIView.animate(withDuration: 0.2, animations: {
                        checkIcon.alpha = 0
                        checkIcon.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                    }) { _ in
                        checkIcon.removeFromSuperview()
                    }
                }
            }
        }
    }
    
    private func setupTags(_ tags: [String]) {
        tagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if tags.isEmpty {
            tagsScrollView.isHidden = true
            return
        }
        
        tagsScrollView.isHidden = false
        
        for tag in tags {
            let tagView = createTagView(with: tag)
            tagsStackView.addArrangedSubview(tagView)
        }
        
        DispatchQueue.main.async {
            self.tagsScrollView.contentSize = self.tagsStackView.frame.size
        }
    }
    
    private func createTagView(with text: String) -> UIView {
        let theme = ThemeManager.shared
        let container = UIView()
        container.backgroundColor = theme.accentColor.withAlphaComponent(0.1)
        container.layer.cornerRadius = 10
        container.layer.borderWidth = 1
        container.layer.borderColor = theme.accentColor.withAlphaComponent(0.3).cgColor
        
        let label = UILabel()
        label.text = "#\(text)"
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = theme.accentColor
        label.textAlignment = .center
        
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -6),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -2),
            container.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        return container
    }
    
    private func updateCompletionState(_ isCompleted: Bool) {
        let theme = ThemeManager.shared
        
        if isCompleted {
            completionButton.backgroundColor = theme.accentColor
            completionButton.layer.borderColor = theme.accentColor.cgColor
            completionButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
            completionButton.tintColor = .white
            
            titleLabel.textColor = theme.secondaryTextColor
            titleLabel.alpha = 0.6
            descriptionLabel.alpha = 0.6
            categoryView.alpha = 0.6
            tagsScrollView.alpha = 0.6
        } else {
            completionButton.backgroundColor = .clear
            completionButton.layer.borderColor = theme.secondaryTextColor.cgColor
            completionButton.setImage(nil, for: .normal)
            
            titleLabel.textColor = theme.textColor
            titleLabel.alpha = 1.0
            descriptionLabel.alpha = 1.0
            categoryView.alpha = 1.0
            tagsScrollView.alpha = 1.0
        }
    }
    
    @objc private func completionButtonTapped() {
        guard let taskId = taskId else { return }
        
        UIView.animate(withDuration: 0.1, animations: {
            self.completionButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.completionButton.transform = CGAffineTransform.identity
            }
        }
        
        onCompletionToggle?(taskId)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        taskId = nil
        titleLabel.text = nil
        descriptionLabel.text = nil
        dueDateLabel.text = nil
        scheduleLabel.text = nil
        categoryLabel.text = nil
        categoryIconView.image = nil
        calendarIndicator.isHidden = true
        
        tagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        tagsScrollView.isHidden = true
        
        setSelectionMode(false)
        updateCompletionState(false)
    }
}
