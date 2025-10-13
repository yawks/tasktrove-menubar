import Foundation

struct Project: Codable, Hashable, Equatable, SelectableItem {
    let id: String
    let name: String
    let slug: String
    let color: String
    // `shared` and `sections` can be omitted by the API -> make optional to be tolerant
    let shared: Bool?
    let sections: [Section]?
    let taskOrder: [String]?
}

struct Section: Codable, Identifiable, Hashable, Equatable {
    let id: String
    let name: String
    let color: String
}
