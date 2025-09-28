import Foundation

struct Task: Codable, Identifiable {
    let id: UUID
    var title: String
    var description: String
    var completed: Bool
    var priority: Int
    var dueDate: Date
    var projectId: UUID
    var sectionId: UUID
    var labels: [UUID]
    var subtasks: [Subtask]
    let comments: [String]
    let attachments: [String]
    let createdAt: Date
    var status: String
    let recurringMode: String

    // Custom coding keys might be needed if the API payload for PATCH is different,
    // but for now, we assume it accepts the full object.
}

struct Subtask: Codable, Identifiable {
    let id: UUID
    var title: String
    var completed: Bool
    let order: Int
}