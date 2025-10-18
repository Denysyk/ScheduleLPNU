//
//  CustomTabBarController.swift
//  ScheduleLPNU
//
//  Custom Tab Bar with iOS 18 style - expandable buttons
//

import UIKit

class CustomTabBarController: UITabBarController {
    
    // MARK: - Properties
    private let customTabBarView = CustomTabBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomTabBar()
        
        // ВАЖЛИВО: Дозволяємо контенту розтягуватися під таб бар
        additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: -49, right: 0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Приховуємо стандартний таб бар
        tabBar.isHidden = true
        
        // Позиціонуємо кастомний таб бар внизу екрану
        let tabBarHeight: CGFloat = 70
        let bottomSafeArea = view.safeAreaInsets.bottom
        let bottomPadding: CGFloat = 30
        let yPosition = view.bounds.height - tabBarHeight - bottomSafeArea - bottomPadding
        
        customTabBarView.frame = CGRect(
            x: 16,
            y: yPosition,
            width: view.bounds.width - 32,
            height: tabBarHeight
        )
        
        // Підносимо таб бар на передній план
        view.bringSubviewToFront(customTabBarView)
        
        // Застосовуємо padding для всіх ScrollView
        applyTabBarPaddingToAllScrollViews()
    }
    
    private func setupCustomTabBar() {
        customTabBarView.delegate = self
        view.addSubview(customTabBarView)
    }
    
    // MARK: - Tab Bar Padding для ScrollViews
    private func applyTabBarPaddingToAllScrollViews() {
        guard let selectedVC = selectedViewController else { return }
        
        let targetVC: UIViewController
        if let navController = selectedVC as? UINavigationController {
            targetVC = navController.topViewController ?? selectedVC
        } else {
            targetVC = selectedVC
        }
        
        // Знаходимо всі ScrollView і додаємо padding
        findScrollViews(in: targetVC.view).forEach { scrollView in
            scrollView.contentInset.bottom = 100
            scrollView.scrollIndicatorInsets.bottom = 100
        }
    }
    
    private func findScrollViews(in view: UIView) -> [UIScrollView] {
        var scrollViews: [UIScrollView] = []
        
        for subview in view.subviews {
            if let scrollView = subview as? UIScrollView {
                scrollViews.append(scrollView)
            }
            scrollViews.append(contentsOf: findScrollViews(in: subview))
        }
        
        return scrollViews
    }
}

// MARK: - CustomTabBarDelegate
extension CustomTabBarController: CustomTabBarDelegate {
    func didSelectTab(at index: Int) {
        selectedIndex = index
        
        // Застосовуємо padding після зміни табу
        DispatchQueue.main.async {
            self.applyTabBarPaddingToAllScrollViews()
        }
    }
}

// MARK: - CustomTabBar
class CustomTabBar: UIView {
    
    // MARK: - Properties
    weak var delegate: CustomTabBarDelegate?
    
    private var buttons: [TabBarButton] = []
    private var selectedIndex: Int = 0
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupThemeObserver()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        layer.cornerRadius = 25
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12
        
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.layer.cornerRadius = 25
        blurView.clipsToBounds = true
        addSubview(blurView)
        
        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        setupButtons()
    }
    
    private func setupButtons() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 0
        
        // Іконки для табів
        let tabItems = [
            ("house.fill", "house.fill", "ГОЛОВНА"),
            ("map", "map.fill", "МАПА"),
            ("checklist", "checklist", "ЗАВДАННЯ"),
            ("gear", "gearshape.fill", "НАЛАШТУВАННЯ")
        ]
        
        for (index, item) in tabItems.enumerated() {
            let button = TabBarButton(
                icon: item.0,
                selectedIcon: item.1,
                title: item.2
            )
            button.tag = index
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        // Встановлюємо перший таб як вибраний
        buttons[0].setSelected(true)
    }
    
    @objc private func buttonTapped(_ sender: TabBarButton) {
        let index = sender.tag
        
        if index == selectedIndex { return }
        
        selectButtonInternal(at: index)
        delegate?.didSelectTab(at: index)
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func selectButtonInternal(at index: Int) {
        guard index < buttons.count else { return }
        
        if selectedIndex < buttons.count && selectedIndex != index {
            buttons[selectedIndex].setSelected(false)
        }
        
        selectedIndex = index
        buttons[index].setSelected(true)
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
        // Оновлюємо кольори кнопок при зміні теми
        buttons.forEach { button in
            button.updateColors()
        }
    }
}

// MARK: - CustomTabBarDelegate Protocol
protocol CustomTabBarDelegate: AnyObject {
    func didSelectTab(at index: Int)
}

// MARK: - TabBarButton
class TabBarButton: UIButton {
    
    // MARK: - UI Elements
    private let iconImageView = UIImageView()
    private let customTitleLabel = UILabel()
    private let backgroundView = UIView()
    private let contentContainer = UIView()
    private let stackView = UIStackView()
    
    // MARK: - Properties
    private var isSelectedState = false
    private let buttonTitle: String
    private let normalIcon: String
    private let selectedIcon: String
    
    private var widthConstraint: NSLayoutConstraint!
    
    // MARK: - Initialization
    init(icon: String, selectedIcon: String, title: String) {
        self.buttonTitle = title
        self.normalIcon = icon
        self.selectedIcon = selectedIcon
        super.init(frame: .zero)
        setupButton(icon: icon, title: title)
    }
    
    required init?(coder: NSCoder) {
        self.buttonTitle = ""
        self.normalIcon = ""
        self.selectedIcon = ""
        super.init(coder: coder)
    }
    
    // MARK: - Setup
    private func setupButton(icon: String, title: String) {
        // Background view
        backgroundView.isUserInteractionEnabled = false
        backgroundView.backgroundColor = .clear
        backgroundView.layer.cornerRadius = 20
        addSubview(backgroundView)
        
        // Container
        contentContainer.isUserInteractionEnabled = false
        addSubview(contentContainer)
        
        // Stack view
        stackView.axis = .horizontal
        stackView.spacing = 5
        stackView.alignment = .center
        stackView.distribution = .fill
        contentContainer.addSubview(stackView)
        
        // Icon
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = getUnselectedIconColor()
        stackView.addArrangedSubview(iconImageView)
        
        // Title
        customTitleLabel.text = title
        customTitleLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        customTitleLabel.textColor = getSelectedTextColor()
        customTitleLabel.alpha = 0
        customTitleLabel.textAlignment = .left
        stackView.addArrangedSubview(customTitleLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 48)
        ])
        
        widthConstraint = widthAnchor.constraint(equalToConstant: 60)
        widthConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            backgroundView.centerXAnchor.constraint(equalTo: centerXAnchor),
            backgroundView.centerYAnchor.constraint(equalTo: centerYAnchor),
            backgroundView.widthAnchor.constraint(equalTo: widthAnchor, constant: -6),
            backgroundView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        NSLayoutConstraint.activate([
            contentContainer.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            contentContainer.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
            contentContainer.leadingAnchor.constraint(greaterThanOrEqualTo: backgroundView.leadingAnchor, constant: 8),
            contentContainer.trailingAnchor.constraint(lessThanOrEqualTo: backgroundView.trailingAnchor, constant: -8)
        ])
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        customTitleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        customTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        customTitleLabel.isHidden = true
    }
    
    // MARK: - Color Methods
    private func getSelectedBackgroundColor() -> UIColor {
        return ThemeManager.shared.accentColor.withAlphaComponent(0.15)
    }
    
    private func getSelectedIconColor() -> UIColor {
        return ThemeManager.shared.accentColor
    }
    
    private func getSelectedTextColor() -> UIColor {
        return ThemeManager.shared.accentColor
    }
    
    private func getUnselectedIconColor() -> UIColor {
        return UIColor.systemGray
    }
    
    func updateColors() {
        if isSelectedState {
            iconImageView.tintColor = getSelectedIconColor()
            customTitleLabel.textColor = getSelectedTextColor()
            backgroundView.backgroundColor = getSelectedBackgroundColor()
        } else {
            iconImageView.tintColor = getUnselectedIconColor()
        }
    }
    
    // MARK: - Selection State
    func setSelected(_ selected: Bool) {
        isSelectedState = selected
        
        if selected {
            iconImageView.image = UIImage(systemName: selectedIcon)
            iconImageView.tintColor = getSelectedIconColor()
            customTitleLabel.textColor = getSelectedTextColor()
            
            let fixedWidth: CGFloat = 150
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: [.curveEaseInOut]) {
                self.widthConstraint.constant = fixedWidth
                self.backgroundView.backgroundColor = self.getSelectedBackgroundColor()
                self.customTitleLabel.alpha = 1
                self.customTitleLabel.isHidden = false
                self.layoutIfNeeded()
            }
        } else {
            iconImageView.image = UIImage(systemName: normalIcon)
            iconImageView.tintColor = getUnselectedIconColor()
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: [.curveEaseInOut]) {
                self.widthConstraint.constant = 60
                self.backgroundView.backgroundColor = .clear
                self.customTitleLabel.alpha = 0
                self.layoutIfNeeded()
            } completion: { _ in
                self.customTitleLabel.isHidden = true
            }
        }
    }
}
