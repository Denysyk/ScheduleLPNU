import Foundation
import UIKit

struct SubjectGrade: Codable {
    let id: String
    let name: String
    let credits: Int
    let grade: Double // Тепер 0-100 балів
    let isCompleted: Bool
    let dateAdded: Date
    
    init(name: String, credits: Int, grade: Double, isCompleted: Bool = true) {
        self.id = UUID().uuidString
        self.name = name
        self.credits = credits
        self.grade = grade
        self.isCompleted = isCompleted
        self.dateAdded = Date()
    }
}

extension SubjectGrade {
    var formattedGrade: String {
        return String(format: "%.0f", grade) // Цілі числа для 100-бальної шкали
    }
    
    var gradePoints: Double {
        return grade * Double(credits)
    }
    
    // Конвертація в 5-бальну систему для відображення
    var gradeTo5Scale: Double {
        switch grade {
        case 88...100: return 5.0  // Відмінно
        case 80...87: return 4.5   // Дуже добре
        case 71...79: return 4.0   // Добре
        case 61...70: return 3.5   // Посередньо
        case 50...60: return 3.0   // Задовільно
        case 26...49: return 2.0   // Незадовільно (з можливістю перескладання)
        default: return 1.0        // Незадовільно (з обов'язковим повторним вивченням)
    }
}
    
    var gradeDescription: String {
        switch grade {
        case 88...100: return "Відмінно"
        case 80...87: return "Дуже добре"
        case 71...79: return "Добре"
        case 61...70: return "Посередньо"
        case 50...60: return "Задовільно"
        case 26...49: return "Незадовільно"
        default: return "Незадовільно (повторне вивчення)"
        }
    }
    
    var gradeColor: UIColor {
        switch grade {
        case 88...100: return .systemGreen      // Відмінно
        case 80...87: return .systemBlue        // Дуже добре
        case 71...79: return .systemTeal        // Добре
        case 61...70: return .systemOrange      // Посередньо
        case 50...60: return .systemYellow      // Задовільно
        case 26...49: return .systemRed         // Незадовільно
        default: return .systemPink             // Критично незадовільно
        }
    }
}

// Енум для швидкого вибору кредитів
enum CreditOption: Int, CaseIterable {
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    
    var displayName: String {
        return "\(rawValue) кредит\(rawValue == 1 ? "" : rawValue < 5 ? "и" : "ів")"
    }
}

// Енум для 100-бальних оцінок LPNU
enum GradeOption100: Double, CaseIterable {
    case excellent = 94.0      // Відмінно (88-100)
    case veryGood = 84.0       // Дуже добре (80-87)
    case good = 75.0           // Добре (71-79)
    case moderate = 65.0       // Посередньо (61-70)
    case satisfactory = 55.0   // Задовільно (50-60)
    case fail = 35.0           // Незадовільно (26-49)
    case criticalFail = 15.0   // Незадовільно з повторним вивченням (0-25)
    
    var displayName: String {
        switch self {
        case .excellent: return "94 (Відмінно)"
        case .veryGood: return "84 (Дуже добре)"
        case .good: return "75 (Добре)"
        case .moderate: return "65 (Посередньо)"
        case .satisfactory: return "55 (Задовільно)"
        case .fail: return "35 (Незадовільно)"
        case .criticalFail: return "15 (Незадовільно - повторне вивчення)"
        }
    }
    
    var description: String {
        switch self {
        case .excellent: return "Відмінно"
        case .veryGood: return "Дуже добре"
        case .good: return "Добре"
        case .moderate: return "Посередньо"
        case .satisfactory: return "Задовільно"
        case .fail: return "Незадовільно"
        case .criticalFail: return "Незадовільно (повторне вивчення)"
        }
    }
    
    var range: String {
        switch self {
        case .excellent: return "88-100"
        case .veryGood: return "80-87"
        case .good: return "71-79"
        case .moderate: return "61-70"
        case .satisfactory: return "50-60"
        case .fail: return "26-49"
        case .criticalFail: return "0-25"
        }
    }
}
