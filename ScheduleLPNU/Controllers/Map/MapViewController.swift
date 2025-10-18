//
//  MapViewController.swift
//  ScheduleLPNU
//
//  Created by Denys Brativnyk on 10.05.2025.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var MapButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    private var buildingsListView: UIView?
    private var tableView: UITableView?
    
    // Дані про корпуси Львівської Політехніки
    private let buildings = [
        Building(id: "1", name: "Головний корпус", address: "вул. С. Бандери, 12",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83577120153969, longitude: 24.014502501543017)),
        Building(id: "2", name: "1 навчальний корпус", address: "вул. Старосольських, 2/4",
                 coordinate: CLLocationCoordinate2D(latitude: 49.835415830615105, longitude: 24.010675628588483)),
        Building(id: "3", name: "2 навчальний корпус", address: "вул. Старосольських, 6",
                 coordinate: CLLocationCoordinate2D(latitude:  49.836058257906664, longitude: 24.01241056732647)),
        Building(id: "4", name: "3 навчальний корпус", address: "пл. Св. Юра, 1",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83647156317333, longitude: 24.01364844748602)),
        Building(id: "5", name: "4 навчальний корпус", address: "вул. Митрополита Андрея, 5",
                 coordinate: CLLocationCoordinate2D(latitude: 49.836400006698035, longitude: 24.01139529104343)),
        Building(id: "6", name: "5 навчальний корпус", address: "вул. С. Бандери, 28а",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83511797139092, longitude: 24.00806366906235)),
        Building(id: "7", name: "6 навчальний корпус", address: "вул. С. Бандери, 32",
                 coordinate: CLLocationCoordinate2D(latitude: 49.835256870993476, longitude: 24.006603597898682)),
        Building(id: "8", name: "6а навчальний корпус", address: "вул. С. Бандери, 32а",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83501269896666, longitude: 24.007149042653744)),
        Building(id: "9", name: "7 навчальний корпус", address: "вул. С. Бандери, 55",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83462321258292, longitude: 24.010379155054963)),
        Building(id: "10", name: "8 навчальний корпус", address: "пл. Св. Юра, 2",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83765640520439, longitude: 24.01252068440741)),
        Building(id: "11", name: "9 навчальний корпус", address: "пл. Св. Юра, 9",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83638678885793, longitude: 24.014452914061085)),
        Building(id: "12", name: "10 навчальний корпус", address: "вул. К. Устияновича, 5",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83645950059037, longitude: 24.01521612297941)),
        Building(id: "13", name: "11 навчальний корпус", address: "вул. Професорська, 2",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83593427363987, longitude: 24.016071440441273)),
        Building(id: "14", name: "12 навчальний корпус", address: "вул. С. Бандери, 12",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83611133954199, longitude: 24.014129583842053)),
        Building(id: "15", name: "13 навчальний корпус", address: "вул. С. Бандери, 12",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83617920879788, longitude: 24.014468682553815)),
        Building(id: "16", name: "14 навчальний корпус", address: "вул. Професорська, 1",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83543685325491, longitude: 24.017392918967417)),
        Building(id: "17", name: "15 навчальний корпус", address: "вул. К. Устияновича, 1",
                 coordinate: CLLocationCoordinate2D(latitude: 49.835700593067806, longitude: 24.01704083548972)),
        Building(id: "18", name: "16 навчальний корпус", address: "вул. С. Бандери, 10",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83520332349561, longitude: 24.016918727949)),
        Building(id: "19", name: "17 навчальний корпус", address: "вул. С. Бандери, 10",
                 coordinate: CLLocationCoordinate2D(latitude: 49.835267611781255, longitude: 24.0170076652966)),
        Building(id: "20", name: "18 навчальний корпус", address: "вул. Котляревського, 1",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83347517111764, longitude: 24.01713428676779)),
        Building(id: "21", name: "19 навчальний корпус", address: "вул. Князя Романа, 1, 3, 5",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83828565398603, longitude: 24.032961585327556)),
        Building(id: "22", name: "20 навчальний корпус", address: "вул. Князя Романа, 3а",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83746808599685, longitude: 24.033600853717562)),
        Building(id: "23", name: "21 корпус (1-й спортивний корпус)", address: "вул. У. Самчука, 14",
                 coordinate: CLLocationCoordinate2D(latitude: 49.82389566463816, longitude: 24.029131811863653)),
        Building(id: "24", name: "22 корпус (2-й спортивний корпус)", address: "вул. У. Самчука, 14",
                 coordinate: CLLocationCoordinate2D(latitude: 49.8234790090672, longitude: 24.030564031760093)),
        Building(id: "25", name: "23 навчальний корпус", address: "вул. Ф. Колесси, 2",
                 coordinate: CLLocationCoordinate2D(latitude: 49.835278350777095, longitude: 24.02168213811448)),
        Building(id: "26", name: "23 корпус (Видавництво)", address: "вул. Ф. Колесси, 4",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83447875361564, longitude: 24.021714570915993)),
        Building(id: "27", name: "24 корпус (Автогосподарство)", address: "вул. Конюшинна, 8",
                 coordinate: CLLocationCoordinate2D(latitude: 49.82935854689865, longitude: 23.9356566349707)),
        Building(id: "28", name: "25 корпус (Технопарк)", address: "вул. Городоцька, 286",
                 coordinate: CLLocationCoordinate2D(latitude: 49.820741102230166, longitude: 23.914271813242905)),
        Building(id: "29", name: "26 корпус (СКХ)", address: "вул. Старосольських, 8",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83646022608787, longitude: 24.01291231324349)),
        Building(id: "30", name: "27 корпус (Науково-технічна бібліотека)", address: "вул. Професорська, 1",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83550609788022, longitude: 24.016616275339622)),
        Building(id: "31", name: "28 корпус (Студентська бібліотека)", address: "вул. Митрополита Андрея, 3",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83686034469038, longitude: 24.012489251378934)),
        Building(id: "32", name: "29 навчальний корпус", address: "вул. Коновальця, 4",
                 coordinate: CLLocationCoordinate2D(latitude: 49.83437553000643, longitude: 24.00887304047783)),
        Building(id: "33", name: "30 навчальний корпус", address: "вул. Лазаренка, 42",
                 coordinate: CLLocationCoordinate2D(latitude: 49.81768515649694, longitude: 24.013076502389723)),
        Building(id: "34", name: "31 корпус (Склад університету)", address: "вул. Конюшинна, 8",
                 coordinate: CLLocationCoordinate2D(latitude: 49.82935854689865, longitude: 23.9356566349707)),
        Building(id: "35", name: "32 навчальний корпус", address: "вул. Горбачевського, 18",
                 coordinate: CLLocationCoordinate2D(latitude: 49.828532387724806, longitude: 24.009216707022652)),
        Building(id: "36", name: "33 навчальний корпус", address: "вул. Театральна, 11",
                 coordinate: CLLocationCoordinate2D(latitude: 49.841071435199794, longitude: 24.029436955571267)),
        Building(id: "37", name: "34 корпус (НСК «Політехнік»)", address: "вул. Стуса, 2",
                 coordinate: CLLocationCoordinate2D(latitude: 49.8241746733322, longitude: 24.03738535189979)),
        Building(id: "38", name: "35 корпус (Стадіон НСК «Політехнік»)", address: "вул. О. Олеся, 25",
                 coordinate: CLLocationCoordinate2D(latitude: 49.827772130069725, longitude: 24.05635337891208)),
        Building(id: "39", name: "36 навчальний корпус", address: "Проспект В'ячеслава Чорновола, 57",
                 coordinate: CLLocationCoordinate2D(latitude: 49.855895772200284, longitude: 24.02153246364146)),
        Building(id: "40", name: "37 навчальний корпус", address: "смт. Брюховичі, вул. Сухомлинського, 16",
                 coordinate: CLLocationCoordinate2D(latitude: 49.9011652835263, longitude: 23.945303012420027)),
        Building(id: "41", name: "38 навчальний корпус", address: "вул. Іванни Блажкевич, 12а",
                 coordinate: CLLocationCoordinate2D(latitude: 49.82408755826293, longitude: 24.00040041289424)),
        Building(id: "42", name: "40 навчальний корпус", address: "вул. Січових Стрільців, 7",
                 coordinate: CLLocationCoordinate2D(latitude: 49.84066523630413, longitude: 24.025273484407503))
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMapView()
        setupMapButton()
        setupTabBar()
        setupThemeObserver()
        addBuildingAnnotations()
        applyTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
        
        // Додаткова перевірка для оновлення UI при поверненні на екран
        DispatchQueue.main.async {
            self.applyTheme()
        }
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
        DispatchQueue.main.async {
            self.applyTheme()
        }
    }
    
    private func setupTabBar() {
        // Забезпечуємо, що Tab Bar не буде прозорим
        if let tabBar = tabBarController?.tabBar {
            let theme = ThemeManager.shared
            
            // Встановлюємо фон Tab Bar
            tabBar.backgroundColor = theme.backgroundColor
            tabBar.barTintColor = theme.backgroundColor
            
            // Для iOS 15+ потрібно використовувати appearance
            if #available(iOS 15.0, *) {
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = theme.backgroundColor
                
                tabBar.standardAppearance = appearance
                tabBar.scrollEdgeAppearance = appearance
            }
            
            // Встановлюємо колір тексту та іконок
            tabBar.tintColor = theme.accentColor
            tabBar.unselectedItemTintColor = theme.secondaryTextColor
        }
    }

    private func applyTheme() {
        let theme = ThemeManager.shared
        
        // Background
        view.backgroundColor = theme.backgroundColor
        
        // Map button
        MapButton.backgroundColor = theme.accentColor
        
        // Navigation
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: theme.accentColor,
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)
        ]
        
        // Tab Bar - ДОДАЙТЕ ЦЕ
        setupTabBar()
        
        // Update map markers if needed
        updateMapMarkers()
    }
    
    private func updateMapMarkers() {
        // Refresh all annotations to apply new theme colors
        let annotations = mapView.annotations
        mapView.removeAnnotations(annotations.filter { !($0 is MKUserLocation) })
        addBuildingAnnotations()
    }
    
    private func setupUI() {
        title = "МАПА"
    }
    
    private func setupMapView() {
        mapView.delegate = self
        
        let initialLocation = CLLocationCoordinate2D(
            latitude: 49.83577120153969,
            longitude: 24.014502501543017
        )
        
        let region = MKCoordinateRegion(
            center: initialLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
        
        mapView.setRegion(region, animated: false)
        mapView.showsUserLocation = true
    }
    
    private func setupMapButton() {
        MapButton.layer.cornerRadius = 30
        MapButton.layer.shadowColor = UIColor.black.cgColor
        MapButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        MapButton.layer.shadowRadius = 3
        MapButton.layer.shadowOpacity = 0.3
        
        if MapButton.actions(forTarget: self, forControlEvent: .touchUpInside)?.isEmpty ?? true {
            MapButton.addTarget(self, action: #selector(showBuildingsList), for: .touchUpInside)
        }
    }
    
    private func addBuildingAnnotations() {
        for building in buildings {
            let annotation = BuildingAnnotation(
                id: building.id,
                title: building.name,
                subtitle: building.address,
                coordinate: building.coordinate
            )
            mapView.addAnnotation(annotation)
        }
    }
    
    @objc func showBuildingsList() {
        buildingsListView?.removeFromSuperview()
        
        let theme = ThemeManager.shared
        
        let listView = UIView()
        listView.backgroundColor = theme.cardBackgroundColor
        listView.layer.cornerRadius = 12
        listView.clipsToBounds = true
        listView.translatesAutoresizingMaskIntoConstraints = false
        
        // Створення header та table view як раніше...
        let headerView = UIView()
        headerView.backgroundColor = theme.cardBackgroundColor
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "МАПА"
        titleLabel.textAlignment = .center
        titleLabel.textColor = theme.accentColor
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = theme.secondaryTextColor
        closeButton.addTarget(self, action: #selector(dismissBuildingsList), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(BuildingCell.self, forCellReuseIdentifier: "BuildingCell")
        tableView.backgroundColor = theme.cardBackgroundColor
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)
        listView.addSubview(headerView)
        listView.addSubview(tableView)
        view.addSubview(listView)
        
        // Auto Layout constraints
        NSLayoutConstraint.activate([
            // Header constraints
            headerView.topAnchor.constraint(equalTo: listView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: listView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: listView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 50),
            
            // Title constraints
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Close button constraints
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Table view constraints
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: listView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: listView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: listView.bottomAnchor),
            
            // List view constraints - КЛЮЧОВЕ ВИПРАВЛЕННЯ
            listView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            listView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            listView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            listView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 120, right: 0)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 120, right: 0)
        
        self.buildingsListView = listView
        self.tableView = tableView
    }
    
    @objc func dismissBuildingsList() {
        UIView.animate(withDuration: 0.3, animations: {
            self.buildingsListView?.alpha = 0
        }) { _ in
            self.buildingsListView?.removeFromSuperview()
            self.buildingsListView = nil
        }
    }
    
    // MARK: - UITableViewDelegate, UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return buildings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BuildingCell", for: indexPath) as! BuildingCell
        let building = buildings[indexPath.row]
        cell.configure(with: building)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedBuilding = buildings[indexPath.row]
        
        dismissBuildingsList()
        
        let region = MKCoordinateRegion(
            center: selectedBuilding.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
        )
        mapView.setRegion(region, animated: true)
        
        for annotation in mapView.annotations {
            if let buildingAnnotation = annotation as? BuildingAnnotation,
               buildingAnnotation.id == selectedBuilding.id {
                mapView.selectAnnotation(annotation, animated: true)
                break
            }
        }
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        if let buildingAnnotation = annotation as? BuildingAnnotation {
            let identifier = "BuildingAnnotation"
            
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: buildingAnnotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                
                annotationView?.markerTintColor = ThemeManager.shared.accentColor
                
                if buildingAnnotation.title?.contains("Головний") == true {
                    annotationView?.glyphText = "Гол"
                } else if buildingAnnotation.title?.contains("навчальний") == true {
                    if let number = extractNumberFromBuildingName(buildingAnnotation.title) {
                        annotationView?.glyphText = number
                    } else {
                        annotationView?.glyphText = buildingAnnotation.id
                    }
                } else {
                    annotationView?.glyphText = createAbbreviation(from: buildingAnnotation.title)
                }
                
                let infoButton = UIButton(type: .detailDisclosure)
                annotationView?.rightCalloutAccessoryView = infoButton
            } else {
                annotationView?.annotation = buildingAnnotation
                annotationView?.markerTintColor = ThemeManager.shared.accentColor
            }
            
            return annotationView
        }
        
        return nil
    }
    
    func extractNumberFromBuildingName(_ buildingName: String?) -> String? {
        guard let name = buildingName else { return nil }
        
        let pattern = "^(\\d+[а-яА-Я]?)\\s+навчальний"
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count)) {
            if let range = Range(match.range(at: 1), in: name) {
                return String(name[range])
            }
        }
        
        return nil
    }
    
    func createAbbreviation(from buildingName: String?) -> String {
        guard let name = buildingName else { return "" }
        
        if name.contains("Технопарк") {
            return "ТП"
        } else if name.contains("СКХ") {
            return "СКХ"
        } else if name.contains("бібліотека") {
            return "Б"
        } else if name.contains("Автогосподарство") {
            return "АГ"
        } else if name.contains("Видавництво") {
            return "В"
        } else if name.contains("спортивний") {
            if let regex = try? NSRegularExpression(pattern: "(\\d+)", options: []),
               let match = regex.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count)),
               let range = Range(match.range(at: 1), in: name) {
                return "С" + String(name[range])
            }
            return "СП"
        }
        
        let words = name.components(separatedBy: " ")
        var abbreviation = ""
        for word in words {
            if let firstChar = word.first, firstChar.isLetter {
                abbreviation.append(firstChar)
            }
        }
        
        return abbreviation.isEmpty ? "?" : abbreviation
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let buildingAnnotation = view.annotation as? BuildingAnnotation else { return }
        
        guard let building = buildings.first(where: { $0.id == buildingAnnotation.id }) else { return }
        
        if let existingDetailView = buildingsListView {
            existingDetailView.removeFromSuperview()
            buildingsListView = nil
        }
        
        showBuildingDetailView(for: building)
    }
    
    private func showBuildingDetailView(for building: Building) {
        let theme = ThemeManager.shared
        
        // Отримуємо висоту Tab Bar
        let tabBarHeight = tabBarController?.tabBar.frame.height ?? 49
        let safeAreaBottom = view.safeAreaInsets.bottom
        
        let detailViewHeight: CGFloat = 140
        
        // Позиціонуємо вигляд так, щоб він був ПОЗАДУ Tab Bar
        // Віднімаємо тільки tabBarHeight, без safeAreaBottom
        let detailView = UIView(frame: CGRect(
            x: 0,
            y: view.bounds.height - detailViewHeight - tabBarHeight,
            width: view.bounds.width,
            height: detailViewHeight
        ))
        
        detailView.backgroundColor = theme.cardBackgroundColor
        detailView.layer.cornerRadius = 16
        detailView.clipsToBounds = true
        
        // Додаємо тінь для кращого візуального ефекту
        detailView.layer.shadowColor = UIColor.black.cgColor
        detailView.layer.shadowOffset = CGSize(width: 0, height: -2)
        detailView.layer.shadowRadius = 8
        detailView.layer.shadowOpacity = 0.1
        detailView.layer.masksToBounds = false
        
        let nameLabel = UILabel(frame: CGRect(x: 16, y: 14, width: detailView.bounds.width - 60, height: 24))
        nameLabel.text = building.name
        nameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        nameLabel.textColor = theme.accentColor
        
        let addressLabel = UILabel(frame: CGRect(x: 16, y: nameLabel.frame.maxY,
                                                 width: detailView.bounds.width - 40, height: 20))
        addressLabel.text = building.address
        addressLabel.font = UIFont.systemFont(ofSize: 14)
        addressLabel.textColor = theme.secondaryTextColor
        
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = theme.secondaryTextColor
        closeButton.frame = CGRect(x: detailView.bounds.width - 40, y: 10, width: 24, height: 24)
        closeButton.addTarget(self, action: #selector(dismissDetailView), for: .touchUpInside)
        
        let buttonHeight: CGFloat = 44
        let buttonMargin: CGFloat = 16
        let directionsButton = UIButton(type: .system)
        directionsButton.setTitle("Прокласти маршрут", for: .normal)
        directionsButton.backgroundColor = theme.accentColor
        directionsButton.setTitleColor(.white, for: .normal)
        directionsButton.layer.cornerRadius = 8
        
        directionsButton.frame = CGRect(
            x: buttonMargin,
            y: detailView.bounds.height - buttonHeight - buttonMargin,
            width: detailView.bounds.width - (buttonMargin * 2),
            height: buttonHeight
        )
        
        directionsButton.tag = Int(building.id) ?? 0
        directionsButton.addTarget(self, action: #selector(getDirections), for: .touchUpInside)
        
        detailView.addSubview(nameLabel)
        detailView.addSubview(addressLabel)
        detailView.addSubview(closeButton)
        detailView.addSubview(directionsButton)
        
        view.addSubview(detailView)
        
        self.buildingsListView = detailView
        
        // Анімація появи знизу
        detailView.transform = CGAffineTransform(translationX: 0, y: detailView.bounds.height)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            detailView.transform = .identity
        }, completion: nil)
    }
    
    @objc func dismissDetailView() {
        UIView.animate(withDuration: 0.3, animations: {
            self.buildingsListView?.transform = CGAffineTransform(translationX: 0, y: self.buildingsListView!.bounds.height)
        }) { _ in
            self.buildingsListView?.removeFromSuperview()
            self.buildingsListView = nil
        }
    }
    
    @objc func getDirections(_ sender: UIButton) {
        let buildingId = String(sender.tag)
        guard let building = buildings.first(where: { $0.id == buildingId }) else { return }
        
        let placemark = MKPlacemark(coordinate: building.coordinate, addressDictionary: nil)
        let destination = MKMapItem(placemark: placemark)
        destination.name = building.name
        
        let userLocation = MKMapItem.forCurrentLocation()
        
        MKMapItem.openMaps(with: [userLocation, destination],
                           launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
}

// MARK: - Models

struct Building {
    let id: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
}

class BuildingAnnotation: NSObject, MKAnnotation {
    let id: String
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    
    init(id: String, title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        super.init()
    }
}

// MARK: - Custom UITableViewCell for Buildings List

class BuildingCell: UITableViewCell {
    private let locationImageView = UIImageView()
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupThemeObserver()
               applyTheme()
           }
           
           required init?(coder: NSCoder) {
               fatalError("init(coder:) has not been implemented")
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
               DispatchQueue.main.async {
                   self.applyTheme()
               }
           }
           
           private func applyTheme() {
               let theme = ThemeManager.shared
               
               backgroundColor = theme.cardBackgroundColor
               contentView.backgroundColor = theme.cardBackgroundColor
               
               locationImageView.tintColor = theme.accentColor
               nameLabel.textColor = theme.textColor
               addressLabel.textColor = theme.secondaryTextColor
           }
           
           private func setupUI() {
               locationImageView.image = UIImage(systemName: "mappin.circle.fill")
               locationImageView.contentMode = .scaleAspectFit
               
               nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
               addressLabel.font = UIFont.systemFont(ofSize: 14)
               
               contentView.addSubview(locationImageView)
               contentView.addSubview(nameLabel)
               contentView.addSubview(addressLabel)
               
               locationImageView.translatesAutoresizingMaskIntoConstraints = false
               nameLabel.translatesAutoresizingMaskIntoConstraints = false
               addressLabel.translatesAutoresizingMaskIntoConstraints = false
               
               NSLayoutConstraint.activate([
                   locationImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                   locationImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                   locationImageView.widthAnchor.constraint(equalToConstant: 24),
                   locationImageView.heightAnchor.constraint(equalToConstant: 24),
                   
                   nameLabel.leadingAnchor.constraint(equalTo: locationImageView.trailingAnchor, constant: 16),
                   nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
                   nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                   
                   addressLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
                   addressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
                   addressLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
               ])
           }
           
           func configure(with building: Building) {
               nameLabel.text = building.name
               addressLabel.text = building.address
           }
        }
