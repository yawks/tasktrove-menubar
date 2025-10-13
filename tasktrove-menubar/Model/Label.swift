import Foundation

struct Label: Codable, Hashable, Equatable, SelectableItem {
    let id: String
    let name: String
    let slug: String
    let color: String
}

struct ProjectGroup: Codable, Identifiable {
    let type: String
    let id: String
    let name: String
    let slug: String
    let items: [String]
}

struct LabelGroup: Codable, Identifiable {
    let type: String
    let id: String
    let name: String
    let slug: String
    let items: [String]
}