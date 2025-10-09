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
    }
    
    private func setupCustomTabBar() {
        customTabBarView.delegate = self
        view.addSubview(customTabBarView)
    }
}

// MARK: - CustomTabBarDelegate
extension CustomTabBarController: CustomTabBarDelegate {
    func didSelectTab(at index: Int) {
        selectedIndex = index
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
        super.init(coder: coder)
        setupUI()
        setupThemeObserver()
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
        // Оновлюємо кольори всіх кнопок
        for button in buttons {
            button.updateColors()
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        DispatchQueue.main.async {
            self.selectButtonInternal(at: 0)
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        layer.cornerRadius = 30
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12
        layer.shadowOpacity = 0.15
        
        // Blur effect
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.layer.cornerRadius = 30
        blurView.clipsToBounds = true
        
        insertSubview(blurView, at: 0)
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
    
    // MARK: - Properties
    private var isSelectedState = false
    private let buttonTitle: String
    private let normalIcon: String
    private let selectedIcon: String
    
    private var widthConstraint: NSLayoutConstraint!
    private let contentContainer = UIView()
    private let stackView = UIStackView()
    
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
                self.backgroundView.layer.cornerRadius = 20
                self.backgroundView.backgroundColor = self.getSelectedBackgroundColor()
                self.superview?.layoutIfNeeded()
            }
            
            UIView.animate(withDuration: 0.15, delay: 0.15) {
                self.customTitleLabel.isHidden = false
                self.customTitleLabel.alpha = 1
            }
            
        } else {
            UIView.animate(withDuration: 0.2) {
                self.customTitleLabel.alpha = 0
            } completion: { _ in
                self.customTitleLabel.isHidden = true
            }
            
            UIView.animate(withDuration: 0.3, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2) {
                self.widthConstraint.constant = 60
                self.backgroundView.backgroundColor = .clear
                self.superview?.layoutIfNeeded()
            } completion: { _ in
                self.iconImageView.image = UIImage(systemName: self.normalIcon)
                self.iconImageView.tintColor = self.getUnselectedIconColor()
            }
        }
    }
    
    // MARK: - Update Colors
    func updateColors() {
        if isSelectedState {
            iconImageView.tintColor = getSelectedIconColor()
            customTitleLabel.textColor = getSelectedTextColor()
            backgroundView.backgroundColor = getSelectedBackgroundColor()
        }
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
            self.transform = .identity
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.transform = .identity
        }
    }
    
    // MARK: - Theme Support
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }
}
