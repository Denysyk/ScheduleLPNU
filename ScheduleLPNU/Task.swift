import Foundation
import UIKit

struct Task: Codable {
    let id: String
    var title: String
    var description: String?
    var isCompleted: Bool
    var priority: TaskPriority
    var dueDate: Date?
    var createdDate: Date
    var associatedSchedule: String?
    var category: TaskCategory
    var tags: [String]
    
    enum TaskPriority: String, Codable, CaseIterable {
        case low = "Низький"
        case medium = "Середній"
        case high = "Високий"
        
        var color: UIColor {
            switch self {
            case .low: return UIColor.systemGreen
            case .medium: return UIColor.systemOrange
            case .high: return UIColor.systemRed
            }
        }
    }
    
    enum TaskCategory: String, Codable, CaseIterable {
        case personal = "Особисте"
        case work = "Робота"
        case study = "Навчання"
        case health = "Здоров'я"
        case shopping = "Покупки"
        case other = "Інше"
        
        var color: UIColor {
            switch self {
            case .personal: return UIColor.systemBlue
            case .work: return UIColor.systemPurple
            case .study: return UIColor.systemGreen
            case .health: return UIColor.systemRed
            case .shopping: return UIColor.systemOrange
            case .other: return UIColor.systemGray
            }
        }
        
        var icon: String {
            switch self {
            case .personal: return "person.fill"
            case .work: return "briefcase.fill"
            case .study: return "book.fill"
            case .health: return "heart.fill"
            case .shopping: return "cart.fill"
            case .other: return "folder.fill"
            }
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        priority = try container.decode(TaskPriority.self, forKey: .priority)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        associatedSchedule = try container.decodeIfPresent(String.self, forKey: .associatedSchedule)
        
        category = try container.decodeIfPresent(TaskCategory.self, forKey: .category) ?? .other
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(priority, forKey: .priority)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encodeIfPresent(associatedSchedule, forKey: .associatedSchedule)
        try container.encode(category, forKey: .category)
        try container.encode(tags, forKey: .tags)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, isCompleted, priority, dueDate, createdDate, associatedSchedule, category, tags
    }
    
    init(title: String, description: String? = nil, priority: TaskPriority = .medium, dueDate: Date? = nil, category: TaskCategory = .other, tags: [String] = []) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.isCompleted = false
        self.priority = priority
        self.dueDate = dueDate
        self.createdDate = Date()
        self.associatedSchedule = nil
        self.category = category
        self.tags = tags
    }
}
