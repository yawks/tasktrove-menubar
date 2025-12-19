extension TodoTask {
    func asDictionary() -> [String: Any]? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(self)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return json as? [String: Any]
        } catch {
            print("❌ Erreur de conversion TodoTask en dictionnaire: \(error)")
            return nil
        }
    }
}
import Foundation

struct TodoTask: Codable, Identifiable, Equatable {
    let id: String?
    var title: String
    var description: String?
    var completed: Bool?
    var priority: Int?
    var dueDate: String?
    var dueTime: String?
    var projectId: String?
    var sectionId: String?
    var labels: [String]?
    var subtasks: [TodoSubtask]?
    var comments: [Comment]?
    var attachments: [String]?
    var createdAt: String?
    var completedAt: String?
    var recurring: String?
    var recurringMode: String?
    var estimation: Int?
}

extension TodoTask {
    static func == (lhs: TodoTask, rhs: TodoTask) -> Bool {
        return lhs.id == rhs.id &&
            lhs.title == rhs.title &&
            lhs.description == rhs.description &&
            lhs.completed == rhs.completed &&
            lhs.priority == rhs.priority &&
            lhs.dueDate == rhs.dueDate &&
            lhs.dueTime == rhs.dueTime &&
            lhs.projectId == rhs.projectId &&
            lhs.sectionId == rhs.sectionId &&
            lhs.labels == rhs.labels &&
            lhs.subtasks == rhs.subtasks &&
            lhs.comments == rhs.comments &&
            lhs.attachments == rhs.attachments &&
            lhs.createdAt == rhs.createdAt &&
            lhs.completedAt == rhs.completedAt &&
            lhs.recurring == rhs.recurring &&
            lhs.recurringMode == rhs.recurringMode &&
            lhs.estimation == rhs.estimation
    }
}

struct TodoSubtask: Codable, Identifiable, Equatable {
    let id: String?
    var title: String
    var completed: Bool?
    var order: Int?
    var estimation: Int?
}

struct Comment: Codable, Identifiable, Equatable {
    let id: String?
    var content: String?
    var createdAt: String?
}
