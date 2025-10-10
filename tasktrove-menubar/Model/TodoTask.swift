import Foundation

struct TodoTask: Codable, Identifiable {
    let id: UUID
    var title: String
    var description: String?
    var completed: Bool
    var priority: Int?
    var dueDate: Date?
    var projectId: UUID?
    var sectionId: UUID?
    var labels: [UUID]
    var subtasks: [TodoSubtask]
    var comments: [String]
    let attachments: [String]
    let createdAt: Date
    var status: String
    let recurringMode: String?
}

struct TodoSubtask: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var completed: Bool
    let order: Int
}
