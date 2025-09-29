import Foundation

struct Label: Codable, Identifiable {
    let id: UUID
    let name: String
    let slug: String
    let color: String
}

struct ProjectGroup: Codable, Identifiable {
    let type: String
    let id: UUID
    let name: String
    let slug: String
    let items: [UUID]
}

struct LabelGroup: Codable, Identifiable {
    let type: String
    let id: UUID
    let name: String
    let slug: String
    let items: [UUID]
}