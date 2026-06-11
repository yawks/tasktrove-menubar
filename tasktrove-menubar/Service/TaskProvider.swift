import Foundation

enum TaskProvider: String, CaseIterable, Identifiable, Codable {
    case taskTrove = "tasktrove"
    case vikunja = "vikunja"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .taskTrove: return "TaskTrove"
        case .vikunja: return "Vikunja"
        }
    }

    var endpointPlaceholder: String {
        switch self {
        case .taskTrove: return "https://api.example.com/api"
        case .vikunja: return "https://vikunja.example.com/api/v1"
        }
    }

    var tokenLabel: String {
        switch self {
        case .taskTrove: return "API Key (Bearer Token)"
        case .vikunja: return "API Token"
        }
    }
}
