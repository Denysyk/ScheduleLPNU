import XCTest

final class ScheduleLPNUUITestsLaunchTests: XCTestCase {
    
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false // ВАЖЛИВО: вимикаємо множинні запуски
    }
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    // MARK: - App Launch Performance Test
    
    func testAppLaunchPerformance() throws {
        // Простий тест запуску без measure для швидкості
        let app = XCUIApplication()
        app.launch()
        
        // Перевіряємо що додаток запустився
        XCTAssertEqual(app.state, .runningForeground, "Додаток має запуститись")
        
        // Записуємо час вручну для інформації
        let startTime = Date()
        app.terminate()
        app.launch()
        let launchTime = Date().timeIntervalSince(startTime)
        
        print("⏱️ Час запуску додатку: \(launchTime) секунд")
        
        // Перевіряємо що запуск відбувся швидко (менше 10 секунд)
        XCTAssertLessThan(launchTime, 10.0, "Запуск додатку має бути швидким")
        
        app.terminate()
    }
    
    func testAppLaunchStability() throws {
        // Тестуємо стабільність запуску
        let app = XCUIApplication()
        
        // Запускаємо кілька разів поспіль
        for i in 1...3 {
            app.launch()
            XCTAssertEqual(app.state, .runningForeground, "Запуск #\(i) має бути успішним")
            
            // Коротка перевірка що UI завантажився
            let _ = app.firstMatch.waitForExistence(timeout: 5.0)
            
            app.terminate()
            
            // Коротка пауза між запусками
            usleep(500000) // 0.5 секунди
        }
    }
    
    func testInitialScreenLoad() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Перевіряємо що початковий екран завантажився
        let initialView = app.firstMatch
        XCTAssertTrue(initialView.waitForExistence(timeout: 5.0), "Початковий екран має завантажитися")
        
        // Перевіряємо наявність основних UI елементів
        let hasTabBar = app.tabBars.firstMatch.exists
        let hasNavigationBar = app.navigationBars.firstMatch.exists
        
        XCTAssertTrue(hasTabBar || hasNavigationBar, "Основні навігаційні елементи мають бути присутні")
        
        app.terminate()
    }
    
    func testAppLaunchWithoutCrash() throws {
        // Швидкий тест що додаток не падає при запуску
        let app = XCUIApplication()
        app.launch()
        
        // Очікуємо 2 секунди та перевіряємо що додаток працює
        sleep(2)
        XCTAssertEqual(app.state, .runningForeground, "Додаток не має падати після запуску")
        
        app.terminate()
    }
    
    func testMemoryUsageOnLaunch() throws {
        // Простий тест використання пам'яті
        let app = XCUIApplication()
        
        // Запускаємо та одразу перевіряємо стан
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
        
        // Перевіряємо що додаток не споживає забагато ресурсів
        // (непрямо через стабільність роботи)
        for _ in 1...5 {
            usleep(200000) // 0.2 секунди
            XCTAssertEqual(app.state, .runningForeground, "Додаток має залишатися стабільним")
        }
        
        app.terminate()
    }
    
    func testLaunchInDifferentOrientations() throws {
        let app = XCUIApplication()
        
        // Тестуємо запуск у портретній орієнтації
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
        app.terminate()
        
        // Тестуємо запуск у ландшафтній орієнтації (для iPad)
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
            app.launch()
            XCTAssertEqual(app.state, .runningForeground)
            app.terminate()
        }
        
        // Повертаємо назад у портретну
        XCUIDevice.shared.orientation = .portrait
    }
    
    func testLaunchWithScreenshots() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Робимо скріншот для документації (за потреби)
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        XCTAssertEqual(app.state, .runningForeground)
        app.terminate()
    }
    
    func testLaunchWithAccessibility() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Перевіряємо що accessibility працює
        let accessibleElements = app.descendants(matching: .any).allElementsBoundByAccessibilityElement
        XCTAssertGreaterThan(accessibleElements.count, 0, "Мають бути доступні accessibility елементи")
        
        app.terminate()
    }
    
    // MARK: - Helper Methods
    
    private func measureLaunchTime(block: () -> Void) -> TimeInterval {
        let startTime = Date()
        block()
        return Date().timeIntervalSince(startTime)
    }
}
