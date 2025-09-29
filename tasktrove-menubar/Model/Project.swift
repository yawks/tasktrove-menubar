import Foundation

struct Project: Codable, Identifiable, Hashable, Equatable, SelectableItem {
    let id: UUID
    let name: String
    let slug: String
    let color: String
    let shared: Bool
    let sections: [Section]
    let taskOrder: [UUID]?
}

struct Section: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    let name: String
    let color: String
}
