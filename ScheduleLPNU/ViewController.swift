//
//  ViewController.swift
//  ScheduleLPNU
//
//  Created by Denys Brativnyk on 27.03.2025.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var SearchButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var emptyStateLabel: UILabel!
    
    private var savedSchedules: [SavedSchedule] = []
    private var isNavigating = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupThemeObserver()
        applyTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSavedSchedules()
        applyTheme()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isNavigating = false
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
        
        // Фон
        view.backgroundColor = theme.backgroundColor
        
        // Кнопка пошуку
        SearchButton.backgroundColor = theme.accentColor
        SearchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        SearchButton.tintColor = .white
        
        // Навігаційний бар
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: theme.accentColor,
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)
        ]
        
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = theme.cardBackgroundColor
            appearance.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: theme.accentColor,
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)
            ]
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationController?.navigationBar.barTintColor = theme.cardBackgroundColor
            navigationController?.navigationBar.isTranslucent = false
        }
        
        // Таблиця
        tableView.backgroundColor = theme.backgroundColor
        
        // Empty state
        emptyStateView.backgroundColor = theme.backgroundColor
        emptyStateLabel.textColor = theme.secondaryTextColor
        
        // Оновлюємо комірки таблиці
        tableView.reloadData()
    }
    
    private func setupUI() {
        SearchButton.layer.cornerRadius = 30
        SearchButton.layer.shadowColor = UIColor.black.cgColor
        SearchButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        SearchButton.layer.shadowRadius = 8
        SearchButton.layer.shadowOpacity = 0.3
        
        emptyStateLabel.text = "Список пустий\nКлікніть на кнопку Пошук, завантажте та збережіть необхідний розклад"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        
        // Реєструємо кастомну клітинку
        tableView.register(SavedScheduleTableViewCell.self, forCellReuseIdentifier: "SavedScheduleCell")
    }
    
    @IBAction func searchButtonTapped(_ sender: UIButton) {
        guard !isNavigating else { return }
        
        isNavigating = true
        
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                sender.transform = CGAffineTransform.identity
            }) { _ in
                self.navigateToSearch()
            }
        }
    }
    
    private func navigateToSearch() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let searchVC = storyboard.instantiateViewController(withIdentifier: "SearchViewController") as? SearchViewController else {
            print("❌ Помилка: SearchViewController не знайдено")
            isNavigating = false
            return
        }
        
        navigationController?.pushViewController(searchVC, animated: true)
    }
    
    private func loadSavedSchedules() {
        savedSchedules = ScheduleManager.shared.getSavedSchedules()
        updateUI()
    }
    
    private func updateUI() {
        if savedSchedules.isEmpty {
            tableView.isHidden = true
            emptyStateView.isHidden = false
        } else {
            tableView.isHidden = false
            emptyStateView.isHidden = true
            tableView.reloadData()
        }
    }
    
    private func openSchedule(_ schedule: SavedSchedule) {
        guard !isNavigating else { return }
        
        isNavigating = true
        
        var destinationVC: UIViewController?
        
        switch schedule.type {
        case .student:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "ResultStudentScheduleViewController") as? ResultStudentScheduleViewController {
                vc.groupName = schedule.groupName ?? ""
                vc.semester = schedule.semester ?? ""
                vc.semesterDuration = schedule.semesterDuration ?? ""
                vc.scheduleDays = schedule.scheduleDays
                vc.isOfflineMode = false
                destinationVC = vc
            }
        case .teacher:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "ResultTeacherScheduleViewController") as? ResultTeacherScheduleViewController {
                vc.teacherName = schedule.teacherName ?? ""
                vc.semester = schedule.semester ?? ""
                vc.semesterDuration = schedule.semesterDuration ?? ""
                vc.scheduleDays = schedule.scheduleDays
                vc.isOfflineMode = false
                destinationVC = vc
            }
        case .external:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "ResultExternalStudentScheduleViewController") as? ResultExternalStudentScheduleViewController {
                vc.groupName = schedule.groupName ?? ""
                vc.semester = schedule.semester ?? ""
                vc.scheduleDays = schedule.scheduleDays
                vc.isOfflineMode = false
                destinationVC = vc
            }
        case .externalTeacher:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "ResultExternalTeacherScheduleViewController") as? ResultExternalTeacherScheduleViewController {
                vc.teacherName = schedule.teacherName ?? ""
                vc.semester = schedule.semester ?? ""
                vc.scheduleDays = schedule.scheduleDays
                vc.isOfflineMode = false
                destinationVC = vc
            }
        case .externalPhd:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "ResultExternalPhdStudentScheduleViewController") as? ResultExternalPhdStudentScheduleViewController {
                vc.groupName = schedule.groupName ?? ""
                vc.semester = schedule.semester ?? ""
                vc.scheduleDays = schedule.scheduleDays
                vc.isOfflineMode = false
                destinationVC = vc
            }
        case .elective:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "ResultElectiveScheduleViewController") as? ResultElectiveScheduleViewController {
                vc.groupName = schedule.groupName ?? ""
                vc.scheduleDays = schedule.scheduleDays
                vc.isOfflineMode = false
                destinationVC = vc
            }
        case .exam:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "ResultStudentExamScheduleViewController") as? ResultStudentExamScheduleViewController {
                vc.groupName = schedule.groupName ?? ""
                vc.scheduleDays = schedule.scheduleDays
                vc.isOfflineMode = false
                destinationVC = vc
            }
        case .teacherExam:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "ResultTeacherExamScheduleViewController") as? ResultTeacherExamScheduleViewController {
                vc.teacherName = schedule.teacherName ?? ""
                vc.scheduleDays = schedule.scheduleDays
                vc.isOfflineMode = false
                destinationVC = vc
            }
        case .phd:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "ResultPhdScheduleViewController") as? ResultPhdScheduleViewController {
                vc.groupName = schedule.groupName ?? ""
                vc.scheduleDays = schedule.scheduleDays
                vc.isOfflineMode = false
                destinationVC = vc
            }
        }
        
        if let vc = destinationVC {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedSchedules.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavedScheduleCell", for: indexPath) as! SavedScheduleTableViewCell
        let schedule = savedSchedules[indexPath.row]
        
        cell.configure(with: schedule)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let schedule = savedSchedules[indexPath.row]
        openSchedule(schedule)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let schedule = savedSchedules[indexPath.row]
            ScheduleManager.shared.deleteSchedule(withId: schedule.id)
            savedSchedules.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            if savedSchedules.isEmpty {
                updateUI()
            }
        }
    }
}
