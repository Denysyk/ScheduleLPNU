//
//  ThemeManager.swift
//  ScheduleLPNU
//
//  Created by Denys Brativnyk on 28.05.2025.
//

import UIKit

class ThemeManager {
    static let shared = ThemeManager()
    
    // Повідомлення про зміну теми
    static let themeChangedNotification = NSNotification.Name("ThemeChanged")
    
    // Поточна тема
    var currentTheme: Theme {
        get {
            let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? "system"
            return Theme(rawValue: savedTheme) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "selectedTheme")
            applyTheme()
            NotificationCenter.default.post(name: ThemeManager.themeChangedNotification, object: nil)
        }
    }
    
    // Поточний акцентний колір
    var currentAccentColor: AccentColor {
        get {
            let savedColor = UserDefaults.standard.string(forKey: "selectedAccentColor") ?? "default"
            return AccentColor(rawValue: savedColor) ?? .default
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "selectedAccentColor")
            // Очищаємо власний колір при виборі стандартного
            clearCustomAccentColor()
            
            // ВИПРАВЛЕНО: Повне оновлення інтерфейсу
            DispatchQueue.main.async {
                self.configureGlobalAppearance()
                self.updateAllNavigationBars()
                self.updateAllTabBars()
                self.forceUpdateAllWindows()
                NotificationCenter.default.post(name: ThemeManager.themeChangedNotification, object: nil)
            }
        }
    }
    
    // Визначаємо чи зараз темна тема
    var isDarkMode: Bool {
        switch currentTheme {
        case .light:
            return false
        case .dark:
            return true
        case .system:
            if #available(iOS 13.0, *) {
                return UITraitCollection.current.userInterfaceStyle == .dark
            } else {
                return false
            }
        }
    }
    
    private init() {}
    
    // Застосовуємо тему при запуску
    func applyTheme() {
        if #available(iOS 13.0, *) {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            
            switch currentTheme {
            case .light:
                window?.overrideUserInterfaceStyle = .light
            case .dark:
                window?.overrideUserInterfaceStyle = .dark
            case .system:
                window?.overrideUserInterfaceStyle = .unspecified
            }
        }
        
        // Застосовуємо стилі до всіх UITabBar та UINavigationBar
        configureGlobalAppearance()
        
        // Оновлюємо Tab Bar
        updateTabBarAppearance()
        
        // Примусово оновлюємо appearance
        forceUpdateAppearance()
    }
    
    private func configureGlobalAppearance() {
        // Tab Bar
        if #available(iOS 13.0, *) {
            let tabBarAppearance = UITabBarAppearance()
            
            // Завжди використовуємо непрозорий фон
            tabBarAppearance.configureWithOpaqueBackground()
            
            // Встановлюємо фон в залежності від теми
            if isDarkMode {
                tabBarAppearance.backgroundColor = UIColor.systemBackground
            } else {
                tabBarAppearance.backgroundColor = UIColor.systemBackground
            }
            
            // Налаштування кольорів елементів
            tabBarAppearance.selectionIndicatorTintColor = accentColor
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = accentColor
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: accentColor
            ]
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.systemGray
            ]
            
            // Застосовуємо appearance до всіх станів
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            
            // Додатково для iOS 15+
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
        } else {
            UITabBar.appearance().barTintColor = cardBackgroundColor
            UITabBar.appearance().tintColor = accentColor
            UITabBar.appearance().unselectedItemTintColor = UIColor.systemGray
            UITabBar.appearance().isTranslucent = false // Важливо для непрозорості
        }
        
        // Navigation Bar
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            
            // Завжди використовуємо непрозорий фон
            navBarAppearance.configureWithOpaqueBackground()
            
            // Встановлюємо фон
            navBarAppearance.backgroundColor = cardBackgroundColor
            
            // Налаштування тексту
            navBarAppearance.titleTextAttributes = [
                .foregroundColor: accentColor,
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
            ]
            navBarAppearance.largeTitleTextAttributes = [
                .foregroundColor: accentColor,
                .font: UIFont.systemFont(ofSize: 34, weight: .bold)
            ]
            
            // Застосовуємо до всіх станів
            UINavigationBar.appearance().standardAppearance = navBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
            UINavigationBar.appearance().compactAppearance = navBarAppearance
            
            // Додатково для iOS 15+
            if #available(iOS 15.0, *) {
                UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
            }
        } else {
            UINavigationBar.appearance().barTintColor = cardBackgroundColor
            UINavigationBar.appearance().titleTextAttributes = [
                .foregroundColor: accentColor,
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
            ]
            UINavigationBar.appearance().isTranslucent = false // Важливо для непрозорості
        }
        
        UINavigationBar.appearance().tintColor = accentColor
    }
    
    // Метод для примусового оновлення всіх вікон
    func forceUpdateAppearance() {
        // Оновлюємо всі вікна
        DispatchQueue.main.async {
            if #available(iOS 13.0, *) {
                for scene in UIApplication.shared.connectedScenes {
                    if let windowScene = scene as? UIWindowScene {
                        for window in windowScene.windows {
                            for view in window.subviews {
                                view.removeFromSuperview()
                                window.addSubview(view)
                            }
                        }
                    }
                }
            } else {
                for window in UIApplication.shared.windows {
                    for view in window.subviews {
                        view.removeFromSuperview()
                        window.addSubview(view)
                    }
                }
            }
        }
    }
    
    // MARK: - Custom Color Methods
    
    // ВИПРАВЛЕНО: Метод для збереження власного кольору
    func setCustomAccentColor(_ color: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        UserDefaults.standard.set([r, g, b, a], forKey: "customAccentColor")
        UserDefaults.standard.synchronize() // Примусово зберігаємо
        
        print("Saving custom color: R:\(r), G:\(g), B:\(b), A:\(a)") // Debug
        
        // ВИПРАВЛЕНО: Повне оновлення інтерфейсу
        DispatchQueue.main.async {
            self.configureGlobalAppearance()
            self.updateAllNavigationBars()
            self.updateAllTabBars()
            self.forceUpdateAllWindows()
            NotificationCenter.default.post(name: ThemeManager.themeChangedNotification, object: nil)
        }
    }
    
    // Додайте метод для скидання до стандартного кольору
    func clearCustomAccentColor() {
        UserDefaults.standard.removeObject(forKey: "customAccentColor")
    }
    
    // НОВИЙ: Метод для оновлення всіх Navigation Bar
    private func updateAllNavigationBars() {
        if #available(iOS 13.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    for window in windowScene.windows {
                        self.updateNavigationBarsInWindow(window)
                    }
                }
            }
        } else {
            for window in UIApplication.shared.windows {
                self.updateNavigationBarsInWindow(window)
            }
        }
    }
    
    // НОВИЙ: Рекурсивне оновлення Navigation Bar у вікні
    private func updateNavigationBarsInWindow(_ window: UIWindow) {
        func updateInViewController(_ viewController: UIViewController) {
            // Оновлюємо Navigation Bar поточного контролера
            if let navController = viewController as? UINavigationController {
                navController.navigationBar.tintColor = self.accentColor
                navController.navigationBar.titleTextAttributes = [
                    NSAttributedString.Key.foregroundColor: self.accentColor,
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .semibold)
                ]
                
                // Оновлюємо всі контролери в стеку
                for childVC in navController.viewControllers {
                    updateInViewController(childVC)
                }
            } else if let navController = viewController.navigationController {
                navController.navigationBar.tintColor = self.accentColor
                navController.navigationBar.titleTextAttributes = [
                    NSAttributedString.Key.foregroundColor: self.accentColor,
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .semibold)
                ]
            }
            
            // Рекурсивно оновлюємо дочірні контролери
            for child in viewController.children {
                updateInViewController(child)
            }
            
            // Оновлюємо presented контролери
            if let presented = viewController.presentedViewController {
                updateInViewController(presented)
            }
        }
        
        if let rootViewController = window.rootViewController {
            updateInViewController(rootViewController)
        }
    }
    
    // НОВИЙ: Метод для оновлення всіх Tab Bar
    private func updateAllTabBars() {
        if #available(iOS 13.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    for window in windowScene.windows {
                        self.updateTabBarsInWindow(window)
                    }
                }
            }
        } else {
            for window in UIApplication.shared.windows {
                self.updateTabBarsInWindow(window)
            }
        }
    }
    
    // НОВИЙ: Оновлення Tab Bar у вікні
    private func updateTabBarsInWindow(_ window: UIWindow) {
        func updateInViewController(_ viewController: UIViewController) {
            if let tabBarController = viewController as? UITabBarController {
                tabBarController.tabBar.tintColor = self.accentColor
                
                // Для iOS 13+ оновлюємо appearance
                if #available(iOS 13.0, *) {
                    let appearance = UITabBarAppearance()
                    appearance.configureWithOpaqueBackground()
                    appearance.backgroundColor = self.backgroundColor
                    
                    appearance.stackedLayoutAppearance.selected.iconColor = self.accentColor
                    appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                        .foregroundColor: self.accentColor
                    ]
                    
                    tabBarController.tabBar.standardAppearance = appearance
                    tabBarController.tabBar.scrollEdgeAppearance = appearance
                }
                
                // Оновлюємо всі контролери табів
                for tabVC in tabBarController.viewControllers ?? [] {
                    updateInViewController(tabVC)
                }
            }
            
            // Рекурсивно оновлюємо дочірні контролери
            for child in viewController.children {
                updateInViewController(child)
            }
            
            // Оновлюємо presented контролери
            if let presented = viewController.presentedViewController {
                updateInViewController(presented)
            }
        }
        
        if let rootViewController = window.rootViewController {
            updateInViewController(rootViewController)
        }
    }
    
    // ВИПРАВЛЕНО: Примусове оновлення всіх вікон
    private func forceUpdateAllWindows() {
        DispatchQueue.main.async {
            if #available(iOS 13.0, *) {
                for scene in UIApplication.shared.connectedScenes {
                    if let windowScene = scene as? UIWindowScene {
                        for window in windowScene.windows {
                            // Примусово оновлюємо всі subviews
                            window.setNeedsLayout()
                            window.layoutIfNeeded()
                            
                            // Оновлюємо всі view controllers
                            self.forceUpdateViewControllerHierarchy(window.rootViewController)
                        }
                    }
                }
            } else {
                for window in UIApplication.shared.windows {
                    window.setNeedsLayout()
                    window.layoutIfNeeded()
                    self.forceUpdateViewControllerHierarchy(window.rootViewController)
                }
            }
        }
    }
    
    // НОВИЙ: Рекурсивне оновлення view controllers
    private func forceUpdateViewControllerHierarchy(_ viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        
        // Викликаємо viewWillAppear для примусового оновлення
        viewController.viewWillAppear(false)
        viewController.view.setNeedsLayout()
        viewController.view.layoutIfNeeded()
        
        // Рекурсивно оновлюємо дочірні контролери
        for child in viewController.children {
            forceUpdateViewControllerHierarchy(child)
        }
        
        // Оновлюємо presented контролери
        if let presented = viewController.presentedViewController {
            forceUpdateViewControllerHierarchy(presented)
        }
    }
    
    // Новий метод для примусового оновлення Tab Bar
    func updateTabBarAppearance() {
        DispatchQueue.main.async {
            // Оновлюємо всі Tab Bar Controllers
            if #available(iOS 13.0, *) {
                for scene in UIApplication.shared.connectedScenes {
                    if let windowScene = scene as? UIWindowScene {
                        for window in windowScene.windows {
                            if let tabBarController = window.rootViewController as? UITabBarController {
                                tabBarController.tabBar.tintColor = self.accentColor
                                tabBarController.tabBar.setNeedsLayout()
                            }
                        }
                    }
                }
            } else {
                for window in UIApplication.shared.windows {
                    if let tabBarController = window.rootViewController as? UITabBarController {
                        tabBarController.tabBar.tintColor = self.accentColor
                        tabBarController.tabBar.setNeedsLayout()
                    }
                }
            }
        }
    }
}

// MARK: - Theme Enum
enum Theme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light:
            return "Світла"
        case .dark:
            return "Темна"
        case .system:
            return "Системна"
        }
    }
    
    var icon: String {
        switch self {
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        case .system:
            return "gear"
        }
    }
}

// MARK: - Accent Color Enum
enum AccentColor: String, CaseIterable {
    case `default` = "default"
    case blue = "blue"
    case purple = "purple"
    case pink = "pink"
    
    var displayName: String {
        switch self {
        case .default:
            return "За замовчуванням"
        case .blue:
            return "Синій"
        case .purple:
            return "Фіолетовий"
        case .pink:
            return "Рожевий"
        }
    }
    
    var color: UIColor {
        switch self {
        case .default:
            return UIColor(red: 70/255, green: 102/255, blue: 102/255, alpha: 1) // #466666
        case .blue:
            return UIColor(red: 140/255, green: 180/255, blue: 210/255, alpha: 1) // приглушено-блакитний (#8CB4D2)
        case .purple:
            return UIColor(red: 170/255, green: 130/255, blue: 190/255, alpha: 1) // пастельна сіро-фіолетова (#AA82BE)
        case .pink:
            return UIColor(red: 240/255, green: 140/255, blue: 160/255, alpha: 1) // м'яка пудрова рожева (#F08CA0)
        }
    }
}

// MARK: - Theme Colors Extension
extension ThemeManager {
    
    // Основні кольори інтерфейсу
    var backgroundColor: UIColor {
        if isDarkMode {
            return UIColor.systemBackground
        } else {
            return UIColor(white: 0.97, alpha: 1.0)
        }
    }
    
    var cardBackgroundColor: UIColor {
        if isDarkMode {
            return UIColor.secondarySystemBackground
        } else {
            return UIColor.white
        }
    }
    
    var secondaryCardBackgroundColor: UIColor {
        if isDarkMode {
            return UIColor.tertiarySystemBackground
        } else {
            return UIColor(white: 0.98, alpha: 1.0)
        }
    }
    
    var textColor: UIColor {
        return UIColor.label
    }
    
    var secondaryTextColor: UIColor {
        return UIColor.secondaryLabel
    }
    
    var tertiaryTextColor: UIColor {
        return UIColor.tertiaryLabel
    }
    
    var separatorColor: UIColor {
        return UIColor.separator
    }
    
    var accentColor: UIColor {
        // Спочатку перевіряємо чи є збережений власний колір
        if let customColorData = UserDefaults.standard.array(forKey: "customAccentColor") as? [CGFloat],
           customColorData.count == 4 {
            let customColor = UIColor(red: customColorData[0], green: customColorData[1],
                                    blue: customColorData[2], alpha: customColorData[3])
            print("Using custom color: R:\(customColorData[0]), G:\(customColorData[1]), B:\(customColorData[2])") // Debug
            return customColor
        }
        
        // Якщо немає власного кольору, повертаємо стандартний
        print("Using standard color: \(currentAccentColor.displayName)") // Debug
        return currentAccentColor.color
    }
    
    // Градієнти для кнопок
    var primaryGradientStart: UIColor {
        return accentColor
    }
    
    var primaryGradientEnd: UIColor {
        let color = accentColor
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return UIColor(red: red * 0.85, green: green * 0.85, blue: blue * 0.85, alpha: alpha)
    }
    
    // Кольори для збережених розкладів
    var savedScheduleBackgroundColor: UIColor {
        return cardBackgroundColor
    }
    
    var savedScheduleBorderColor: UIColor {
        if isDarkMode {
            return UIColor.systemGray4
        } else {
            return UIColor(white: 0.9, alpha: 1.0)
        }
    }
}
