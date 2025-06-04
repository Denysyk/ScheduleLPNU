//
//  SavedScheduleTableViewCell.swift
//  ScheduleLPNU
//
//  Created by Denys Brativnyk on 27.05.2025.
//

import UIKit

class SavedScheduleTableViewCell: UITableViewCell {
    
    // UI Elements
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let typeLabel = UILabel()
    private let dateLabel = UILabel()
    private let iconImageView = UIImageView()
    private let arrowImageView = UIImageView()
    
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
        
        // Background
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        // Container
        containerView.backgroundColor = theme.cardBackgroundColor
        containerView.layer.borderColor = theme.savedScheduleBorderColor.cgColor
        
        // Shadow (тільки в світлій темі)
        if theme.isDarkMode {
            containerView.layer.shadowOpacity = 0
        } else {
            containerView.layer.shadowColor = UIColor.black.cgColor
            containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
            containerView.layer.shadowRadius = 4
            containerView.layer.shadowOpacity = 0.08
        }
        
        // Text colors
        titleLabel.textColor = theme.textColor
        typeLabel.textColor = theme.secondaryTextColor
        dateLabel.textColor = theme.tertiaryTextColor
        
        // Icons
        iconImageView.tintColor = theme.accentColor
        arrowImageView.tintColor = theme.tertiaryTextColor
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        // Container view
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.masksToBounds = false
        
        // Icon setup
        iconImageView.contentMode = .scaleAspectFit
        
        // Title label
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.numberOfLines = 0
        
        // Type label
        typeLabel.font = .systemFont(ofSize: 14, weight: .medium)
        typeLabel.numberOfLines = 1
        
        // Date label
        dateLabel.font = .systemFont(ofSize: 12, weight: .regular)
        dateLabel.numberOfLines = 1
        
        // Arrow
        arrowImageView.image = UIImage(systemName: "chevron.right")
        arrowImageView.contentMode = .scaleAspectFit
        
        // Add to container
        contentView.addSubview(containerView)
        
        [iconImageView, titleLabel, typeLabel, dateLabel, arrowImageView].forEach {
            containerView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            // Icon
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Arrow
            arrowImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            arrowImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 12),
            arrowImageView.heightAnchor.constraint(equalToConstant: 16),
            
            // Title
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -8),
            
            // Type
            typeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            typeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            typeLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            // Date
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 4),
            dateLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with schedule: SavedSchedule) {
        titleLabel.text = schedule.title
        
        // Type description
        let typeDescription = getTypeDescription(for: schedule.type)
        typeLabel.text = typeDescription
        
        // Icon based on type
        let iconName = getIconName(for: schedule.type)
        iconImageView.image = UIImage(systemName: iconName)
        
        // Date
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "d MMM. yyyy р., HH:mm"
        dateLabel.text = "Збережено: \(formatter.string(from: schedule.savedDate))"
    }
    
    private func getTypeDescription(for type: SavedSchedule.ScheduleType) -> String {
        switch type {
        case .student:
            return "Розклад занять для студентів"
        case .teacher:
            return "Розклад занять для викладачів зі студентами"
        case .external:
            return "Розклад занять для студентів-заочників"
        case .externalTeacher:
            return "Розклад занять для викладачів зі студентами-заочниками"
        case .externalPhd:
            return "Розклад занять для аспірантів-заочників"
        case .elective:
            return "Розклад занять вибіркових дисциплін"
        case .exam:
            return "Розклад екзаменів для студентів та аспірантів"
        case .teacherExam:
            return "Розклад екзаменів для викладачів"
        case .phd:
            return "Розклад занять для аспірантів"
        }
    }
    
    private func getIconName(for type: SavedSchedule.ScheduleType) -> String {
        switch type {
        case .student, .external:
            return "person.fill"
        case .teacher, .externalTeacher:
            return "person.2.fill"
        case .phd, .externalPhd:
            return "graduationcap.fill"
        case .elective:
            return "book.fill"
        case .exam, .teacherExam:
            return "doc.text.fill"
        }
    }
}
