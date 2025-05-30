//
//  SavedSchedule.swift
//  ScheduleLPNU
//
//  Created by Denys Brativnyk on 25.05.2025.
//

import Foundation

struct SavedSchedule: Codable {
    let id: String
    let title: String
    let type: ScheduleType
    let groupName: String?
    let teacherName: String?
    let semester: String?
    let semesterDuration: String?
    let savedDate: Date
    let scheduleDays: [ScheduleDay]
    
    enum ScheduleType: String, Codable {
        case student = "student"
        case teacher = "teacher"
        case external = "external"
        case externalTeacher = "externalTeacher"
        case externalPhd = "externalPhd"
        case elective = "elective"
        case exam = "exam"
        case teacherExam = "teacherExam"
        case phd = "phd"
    }
}
