import Foundation

struct Project: Codable, Identifiable {
    let id: UUID
    let name: String
    let slug: String
    let color: String
    let shared: Bool
    let sections: [Section]
    let taskOrder: [UUID]
}

struct Section: Codable, Identifiable {
    let id: UUID
    let name: String
    let color: String
}