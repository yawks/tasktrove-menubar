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

struct TodoTask: Codable, Identifiable {
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
