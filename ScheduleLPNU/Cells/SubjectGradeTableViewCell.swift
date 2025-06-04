import UIKit

class SubjectGradeTableViewCell: UITableViewCell {
    
    private var containerView: UIView!
    private var subjectNameLabel: UILabel!
    private var gradeLabel: UILabel!
    private var creditsLabel: UILabel!
    private var gradePointsLabel: UILabel!
    
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
        
        containerView?.backgroundColor = theme.cardBackgroundColor
        subjectNameLabel?.textColor = theme.textColor
        gradeLabel?.textColor = theme.accentColor
        creditsLabel?.textColor = theme.secondaryTextColor
        gradePointsLabel?.textColor = theme.secondaryTextColor
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        // Container
        containerView = UIView()
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowOpacity = 0.08
        containerView.layer.shadowRadius = 6
        contentView.addSubview(containerView)
        
        // Subject name
        subjectNameLabel = UILabel()
        subjectNameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        subjectNameLabel.numberOfLines = 2
        subjectNameLabel.lineBreakMode = .byWordWrapping
        containerView.addSubview(subjectNameLabel)
        
        // Grade
        gradeLabel = UILabel()
        gradeLabel.font = .systemFont(ofSize: 20, weight: .bold)
        gradeLabel.textAlignment = .center
        containerView.addSubview(gradeLabel)
        
        // Credits
        creditsLabel = UILabel()
        creditsLabel.font = .systemFont(ofSize: 14, weight: .medium)
        creditsLabel.textAlignment = .right
        containerView.addSubview(creditsLabel)
        
        // Grade points
        gradePointsLabel = UILabel()
        gradePointsLabel.font = .systemFont(ofSize: 12, weight: .regular)
        gradePointsLabel.textAlignment = .right
        containerView.addSubview(gradePointsLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        [containerView, subjectNameLabel, gradeLabel, creditsLabel, gradePointsLabel].forEach {
            $0?.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            // Subject name
            subjectNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            subjectNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            subjectNameLabel.trailingAnchor.constraint(equalTo: gradeLabel.leadingAnchor, constant: -12),
            
            // Grade
            gradeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            gradeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            gradeLabel.widthAnchor.constraint(equalToConstant: 60),
            gradeLabel.heightAnchor.constraint(equalToConstant: 32),
            
            // Credits
            creditsLabel.topAnchor.constraint(equalTo: gradeLabel.bottomAnchor, constant: 4),
            creditsLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            creditsLabel.widthAnchor.constraint(equalToConstant: 60),
            
            // Grade points - підвищуємо трохи вгору
            gradePointsLabel.topAnchor.constraint(equalTo: creditsLabel.bottomAnchor, constant: 2),
            gradePointsLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            gradePointsLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12),
            gradePointsLabel.widthAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func configure(with grade: SubjectGrade) {
        subjectNameLabel.text = grade.name
        gradeLabel.text = grade.formattedGrade // Показуємо 100-бальну оцінку
        creditsLabel.text = "\(grade.credits) кред."
        
        // Просто показуємо число без "б." або "балів"
        gradePointsLabel.text = String(format: "%.0f", grade.gradePoints)
        
        // Update appearance based on LPNU grade system
        gradeLabel.textColor = grade.gradeColor
        
        // Примусово оновлюємо layout для правильного відображення
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        subjectNameLabel.text = nil
        gradeLabel.text = nil
        creditsLabel.text = nil
        gradePointsLabel.text = nil
    }
}
