import Foundation

// Загальні структури для всіх типів розкладів
struct ScheduleDay: Codable {
    let dayName: String
    var lessons: [Lesson]
}

struct Lesson: Codable {
    let number: String
    let name: String
    let teacher: String 
    let room: String
    let type: String
    let timeStart: String
    let timeEnd: String
    let url: String?
    let weekType: WeekType
}

// Enum для типу тижня
enum WeekType: String, Codable {
    case full = "full"    // Кожен тиждень
    case odd = "odd"      // Непарний тиждень
    case even = "even"    // Парний тиждень
}
