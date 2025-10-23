//
//  BaseFullScreenViewController.swift
//  ScheduleLPNU
//
//  Базовий клас для екранів, де потрібен full-screen контент (без safe area зверху і знизу)
//

import UIKit

class BaseFullScreenViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFullScreenLayout()
    }
    
    private func setupFullScreenLayout() {
        // Знаходимо перший subview (зазвичай це основний контент: TableView, MapView, ScrollView тощо)
        guard let mainContentView = view.subviews.first(where: {
            $0 is UITableView || $0 is UIScrollView || $0.isKind(of: NSClassFromString("MKMapView") ?? UIView.self)
        }) else {
            return
        }
        
        // Зберігаємо reference на кнопки та інші елементи
        let otherSubviews = view.subviews.filter { $0 !== mainContentView }
        
        // Видаляємо основний контент view
        mainContentView.removeFromSuperview()
        
        // Додаємо його назад як перший (нижній) шар
        view.insertSubview(mainContentView, at: 0)
        
        // Встановлюємо нові constraints БЕЗ safe area
        mainContentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainContentView.topAnchor.constraint(equalTo: view.topAnchor),
            mainContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Повертаємо інші елементи на передній план
        otherSubviews.forEach { view.bringSubviewToFront($0) }
    }
}

// MARK: - Як використовувати:
//
// Замість:
//   class MapViewController: UIViewController { ... }
//
// Пишіть:
//   class MapViewController: BaseFullScreenViewController { ... }
//
// Це автоматично зробить основний контент full-screen!
