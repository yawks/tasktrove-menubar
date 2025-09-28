import Foundation

struct APIResponse: Codable {
    let tasks: [Task]
    let projects: [Project]
    let labels: [Label]
    let projectGroups: ProjectGroup
    let labelGroups: LabelGroup
    let version: String
}