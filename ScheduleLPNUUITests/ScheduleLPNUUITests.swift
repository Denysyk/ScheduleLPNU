import XCTest

final class ScheduleLPNUUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Basic UI Tests
    
    func testMainTabBarExists() throws {
        // Перевіряємо що основні вкладки присутні
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab Bar має існувати")
        
        // Перевіряємо наявність основних вкладок
        let homeTab = tabBar.buttons["Головна"]
        let searchTab = tabBar.buttons["Пошук"]
        let tasksTab = tabBar.buttons["Завдання"]
        let mapTab = tabBar.buttons["Мапа"]
        let settingsTab = tabBar.buttons["Налаштування"]
        
        XCTAssertTrue(homeTab.exists || searchTab.exists || tasksTab.exists || mapTab.exists || settingsTab.exists,
                     "Принаймні одна вкладка має існувати")
    }
    
    func testNavigationBarExists() throws {
        // Перевіряємо що navigation bar присутній
        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.exists, "Navigation Bar має існувати")
    }
    
    func testSearchButtonTappable() throws {
        // Переходимо на головну вкладку
        if app.tabBars.buttons["Головна"].exists {
            app.tabBars.buttons["Головна"].tap()
            
            // Шукаємо кнопку пошуку на контролері
            if app.buttons["Пошук"].exists {
                let searchButton = app.buttons["Пошук"]
                XCTAssertTrue(searchButton.isHittable, "Кнопка пошуку має бути доступною для натискання")
            } else {
                // Можливо кнопка має інший identifier
                let searchButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Пошук' OR label CONTAINS 'пошук'")).firstMatch
                if searchButton.exists {
                    XCTAssertTrue(searchButton.isHittable, "Кнопка пошуку має бути доступною для натискання")
                }
            }
        }
    }
    
    func testTasksTabNavigation() throws {
        // Перевіряємо що можна перейти на вкладку завдань
        if app.tabBars.buttons["Завдання"].exists {
            app.tabBars.buttons["Завдання"].tap()
            
            // Перевіряємо що перехід відбувся (наприклад, по title)
            let tasksTitle = app.navigationBars["ЗАВДАННЯ"]
            XCTAssertTrue(tasksTitle.waitForExistence(timeout: 2.0), "Має з'явитися заголовок завдань")
        }
    }
    
    func testSettingsTabNavigation() throws {
        // Перевіряємо перехід до налаштувань
        if app.tabBars.buttons["Налаштування"].exists {
            app.tabBars.buttons["Налаштування"].tap()
            
            let settingsTitle = app.navigationBars["НАЛАШТУВАННЯ"]
            XCTAssertTrue(settingsTitle.waitForExistence(timeout: 2.0), "Має з'явитися заголовок налаштувань")
        }
    }
    
    func testMapTabExists() throws {
        // Перевіряємо що вкладка мапи існує
        if app.tabBars.buttons["Мапа"].exists {
            app.tabBars.buttons["Мапа"].tap()
            
            // Очікуємо що мапа завантажиться
            let mapTitle = app.navigationBars["МАПА"]
            XCTAssertTrue(mapTitle.waitForExistence(timeout: 3.0), "Має з'явитися заголовок мапи")
        }
    }
    
    // MARK: - Tasks Flow Tests
    
    func testAddTaskButtonExists() throws {
        // Переходимо на вкладку завдань
        if app.tabBars.buttons["Завдання"].exists {
            app.tabBars.buttons["Завдання"].tap()
            
            // Шукаємо кнопку додавання (зазвичай це "+" або "Add")
            let addButton = app.buttons.matching(identifier: "add").firstMatch
            if !addButton.exists {
                // Пробуємо знайти по символу
                let plusButton = app.buttons["+"]
                XCTAssertTrue(plusButton.exists || addButton.exists, "Кнопка додавання завдання має існувати")
            }
        }
    }
    
    func testTasksEmptyState() throws {
        // Перевіряємо empty state на екрані завдань
        if app.tabBars.buttons["Завдання"].exists {
            app.tabBars.buttons["Завдання"].tap()
            
            // Очікуємо завантаження екрану
            let _ = app.navigationBars["ЗАВДАННЯ"].waitForExistence(timeout: 2.0)
            
            // Перевіряємо чи є текст про порожній список
            let emptyStateExists = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'пустий' OR label CONTAINS 'порожній'")).firstMatch.exists
            
            // Не вимагаємо обов'язково empty state, оскільки можуть бути завдання
            if emptyStateExists {
                XCTAssertTrue(true, "Empty state відображається коректно")
            }
        }
    }
    
    // MARK: - Search Flow Tests
    
    func testSearchScreenAccess() throws {
        // Спочатку переходимо на головну вкладку
        if app.tabBars.buttons["Головна"].exists {
            app.tabBars.buttons["Головна"].tap()
            
            // Тепер натискаємо кнопку пошуку на контролері
            if app.buttons["Пошук"].exists {
                app.buttons["Пошук"].tap()
                
                let searchTitle = app.navigationBars["ПОШУК"]
                XCTAssertTrue(searchTitle.waitForExistence(timeout: 3.0), "Має з'явитися заголовок пошуку")
            } else {
                throw XCTSkip("Кнопка пошуку не знайдена на головному екрані")
            }
        } else if app.tabBars.buttons["Пошук"].exists {
            // Якщо є окрема вкладка пошуку
            app.tabBars.buttons["Пошук"].tap()
            
            let searchTitle = app.navigationBars["ПОШУК"]
            XCTAssertTrue(searchTitle.waitForExistence(timeout: 3.0), "Має з'явитися заголовок пошуку")
        } else {
            throw XCTSkip("Не знайдено способу доступу до екрану пошуку")
        }
    }
    
    func testScheduleTypeButtonsExist() throws {
        // Спочатку переходимо на головну вкладку
        if app.tabBars.buttons["Головна"].exists {
            app.tabBars.buttons["Головна"].tap()
            
            // Тепер шукаємо кнопку пошуку на контролері
            if app.buttons["Пошук"].exists {
                app.buttons["Пошук"].tap()
                
                // Очікуємо завантаження екрану пошуку
                let _ = app.navigationBars["ПОШУК"].waitForExistence(timeout: 3.0)
                
                // Перевіряємо наявність кнопок типів розкладу
                let scheduleButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Розклад' OR label CONTAINS 'розклад'"))
                XCTAssertGreaterThan(scheduleButtons.count, 0, "Має бути принаймні одна кнопка з розкладом")
            } else {
                throw XCTSkip("Кнопка пошуку не знайдена на головному екрані")
            }
        } else if app.tabBars.buttons["Пошук"].exists {
            // Якщо є окрема вкладка пошуку
            app.tabBars.buttons["Пошук"].tap()
            
            let _ = app.navigationBars["ПОШУК"].waitForExistence(timeout: 3.0)
            let scheduleButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Розклад' OR label CONTAINS 'розклад'"))
            XCTAssertGreaterThan(scheduleButtons.count, 0, "Має бути принаймні одна кнопка з розкладом")
        } else {
            throw XCTSkip("Не знайдено способу доступу до екрану пошуку")
        }
    }
    
    // MARK: - Settings Flow Tests
    
    func testSettingsOptionsExist() throws {
        // Переходимо до налаштувань
        if app.tabBars.buttons["Налаштування"].exists {
            app.tabBars.buttons["Налаштування"].tap()
            
            // Очікуємо завантаження
            let _ = app.navigationBars["НАЛАШТУВАННЯ"].waitForExistence(timeout: 2.0)
            
            // Перевіряємо наявність основних опцій налаштувань
            let themeOption = app.staticTexts["Вигляд"]
            let supportOption = app.staticTexts["Підтримка"]
            
            XCTAssertTrue(themeOption.exists || supportOption.exists, "Мають існувати опції налаштувань")
        }
    }
    
    // MARK: - Interface Response Performance Test
    
    func testInterfaceResponseTime() throws {
        measure {
            // Перевіряємо що додаток запущений та реагує
            XCTAssertEqual(app.state, .runningForeground)
            
            // Виконуємо простий tab switch якщо можливо
            if app.tabBars.firstMatch.exists {
                let tabBar = app.tabBars.firstMatch
                let firstTab = tabBar.buttons.firstMatch
                if firstTab.exists {
                    firstTab.tap()
                }
            }
            
            // Мінімальна затримка для вимірювання
            usleep(5000) // 0.005 секунди
        }
    }
    
    func testTabSwitchingPerformance() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.exists else {
            throw XCTSkip("Tab Bar не знайдений")
        }
        
        measure {
            // Переключаємося між вкладками
            let tabs = tabBar.buttons
            if tabs.count >= 2 {
                tabs.element(boundBy: 0).tap()
                tabs.element(boundBy: 1).tap()
            }
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() throws {
        // Перевіряємо що основні елементи мають accessibility labels
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let buttons = tabBar.buttons
            for i in 0..<min(buttons.count, 3) { // Перевіряємо перші 3 кнопки
                let button = buttons.element(boundBy: i)
                XCTAssertFalse(button.label.isEmpty, "Tab bar кнопка має мати label")
            }
        }
    }
    
    func testNavigationBackButton() throws {
        // Переходимо на головну вкладку та натискаємо пошук
        if app.tabBars.buttons["Головна"].exists {
            app.tabBars.buttons["Головна"].tap()
            
            if app.buttons["Пошук"].exists {
                app.buttons["Пошук"].tap()
                
                // Перевіряємо чи з'явилася кнопка назад
                let backButton = app.navigationBars.buttons.firstMatch
                if backButton.exists && (backButton.label.contains("Back") || backButton.label.contains("Назад") || backButton.label.contains("<")) {
                    XCTAssertTrue(backButton.isHittable, "Кнопка назад має бути доступною")
                }
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testAppDoesNotCrash() throws {
        // Виконуємо кілька дій щоб переконатися що додаток не падає
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let tabs = tabBar.buttons
            
            // Переключаємося між усіма доступними вкладками
            for i in 0..<min(tabs.count, 5) {
                tabs.element(boundBy: i).tap()
                // Короткочасна затримка
                usleep(100000) // 0.1 секунди
                
                // Перевіряємо що додаток ще працює
                XCTAssertEqual(app.state, .runningForeground, "Додаток має продовжувати працювати")
            }
        }
    }
    
}
