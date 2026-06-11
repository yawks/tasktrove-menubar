import Foundation

class VikunjaNetworkService: NetworkServiceProtocol {

    // MARK: - Internal Vikunja models

    private struct VikunjaTask: Codable {
        let id: Int
        var title: String
        var description: String?
        var done: Bool?
        var doneAt: String?
        var dueDate: String?
        var priority: Int?
        var projectId: Int?
        var labels: [VikunjaLabel]?
        var bucketId: Int?
        var created: String?
        var percentDone: Double?

        enum CodingKeys: String, CodingKey {
            case id, title, description, done, priority, labels, created
            case doneAt = "done_at"
            case dueDate = "due_date"
            case projectId = "project_id"
            case bucketId = "bucket_id"
            case percentDone = "percent_done"
        }
    }

    private struct VikunjaProject: Codable {
        let id: Int
        var title: String
        var hexColor: String?
        var isArchived: Bool?
        var childProjects: [VikunjaProject]?

        enum CodingKeys: String, CodingKey {
            case id, title
            case hexColor = "hex_color"
            case isArchived = "is_archived"
            case childProjects = "child_projects"
        }
    }

    private struct VikunjaLabel: Codable {
        let id: Int
        var title: String
        var hexColor: String?

        enum CodingKeys: String, CodingKey {
            case id, title
            case hexColor = "hex_color"
        }
    }

    // MARK: - Properties

    private let baseURL: URL
    private let session: URLSession
    private let bearerToken: String
    /// Cache of fetched tasks keyed by Vikunja integer ID.
    /// Used to supplement partial update payloads with required fields (title, project_id).
    private var taskCache: [Int: VikunjaTask] = [:]

    // MARK: - Init

    init(configuration: APIConfiguration) throws {
        guard let url = URL(string: configuration.endpoint) else {
            throw NetworkError.invalidURL
        }
        self.baseURL = url
        self.session = URLSession(configuration: .default)
        self.bearerToken = configuration.apiKey
    }

    // MARK: - URL Helpers

    private func apiURL(_ path: String, queryItems: [URLQueryItem]? = nil) -> URL {
        let base = baseURL.absoluteString.hasSuffix("/")
            ? String(baseURL.absoluteString.dropLast())
            : baseURL.absoluteString
        var components = URLComponents(string: "\(base)/\(path)")!
        components.queryItems = queryItems
        return components.url!
    }

    private func makeRequest(_ url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func checkResponse(_ response: URLResponse, data: Data, context: String = "") throws {
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        let tag = context.isEmpty ? "Vikunja" : "Vikunja[\(context)]"
        print("⬅️ \(tag) \(http.statusCode) — \(http.url?.absoluteString ?? "?")")
        if http.statusCode == 403 { throw NetworkService.AuthError.forbidden }
        guard (200...299).contains(http.statusCode) else {
            print("❌ \(tag) error \(http.statusCode): \(String(data: data, encoding: .utf8) ?? "<non-UTF8>")")
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - NetworkServiceProtocol

    func fetchTasks() async throws -> APIResponse {
        print("➡️ Vikunja fetchTasks — base: \(baseURL.absoluteString)")
        // Projects and labels first (needed as fallback for task fetching)
        async let projectsTask = fetchVikunjaProjects()
        async let labelsTask = fetchVikunjaLabels()
        let (vikunjaProjects, vikunjaLabels) = try await (projectsTask, labelsTask)

        // Try tasks/all; fall back to per-project fetch if the endpoint returns an error
        var vikunjaTasks: [VikunjaTask]
        do {
            vikunjaTasks = try await fetchAllVikunjaTasks()
        } catch {
            print("⚠️ Vikunja tasks/all failed (\(error.localizedDescription)) — falling back to per-project fetch")
            vikunjaTasks = try await fetchTasksForProjects(vikunjaProjects)
        }

        print("✅ Vikunja fetchTasks — tasks:\(vikunjaTasks.count) projects:\(vikunjaProjects.count) labels:\(vikunjaLabels.count)")

        let appTasks = vikunjaTasks.map { mapTask($0) }
        let appProjects = flattenProjects(vikunjaProjects).map { mapProject($0) }
        let appLabels = vikunjaLabels.map { mapLabel($0) }

        return APIResponse(
            tasks: appTasks,
            projects: appProjects,
            labels: appLabels,
            projectGroups: nil,
            labelGroups: nil,
            version: nil
        )
    }

    func updateTasks(_ tasks: [[String: Any]]) async throws {
        for taskDict in tasks {
            guard let idString = taskDict["id"] as? String, let taskId = Int(idString) else {
                print("⚠️ Vikunja updateTasks — skipping task with non-integer id: \(taskDict["id"] ?? "nil")")
                continue
            }
            let body = buildUpdateBody(from: taskDict, taskId: taskId)
            let url = apiURL("tasks/\(taskId)")
            print("➡️ Vikunja updateTask \(taskId) — \(url.absoluteString)")
            if let bodyData = try? JSONSerialization.data(withJSONObject: body),
               let bodyStr = String(data: bodyData, encoding: .utf8) {
                print("   body: \(bodyStr)")
            }
            var request = makeRequest(url, method: "POST")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await session.data(for: request)
            try checkResponse(response, data: data, context: "updateTask:\(taskId)")
        }
    }

    func createTask(_ taskData: [String: Any]) async throws {
        let projectId = (taskData["projectId"] as? String).flatMap { Int($0) } ?? 1
        let body = buildCreateBody(from: taskData)
        let url = apiURL("projects/\(projectId)/tasks")
        print("➡️ Vikunja createTask — \(url.absoluteString)")
        if let bodyData = try? JSONSerialization.data(withJSONObject: body),
           let bodyStr = String(data: bodyData, encoding: .utf8) {
            print("   body: \(bodyStr)")
        }
        var request = makeRequest(url, method: "PUT")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        try checkResponse(response, data: data, context: "createTask")
    }

    // MARK: - Private Fetch Methods

    private func fetchAllVikunjaTasks() async throws -> [VikunjaTask] {
        var allTasks: [VikunjaTask] = []
        var page = 1

        while true {
            let url = apiURL("tasks/all", queryItems: [
                URLQueryItem(name: "page", value: String(page))
            ])
            print("➡️ Vikunja GET tasks/all page:\(page) — \(url.absoluteString)")
            let request = makeRequest(url)
            let (data, response) = try await session.data(for: request)
            try checkResponse(response, data: data, context: "tasks/all p\(page)")

            if let batch = try? JSONDecoder().decode([VikunjaTask].self, from: data) {
                if batch.isEmpty { break }
                allTasks.append(contentsOf: batch)
                print("   tasks/all p\(page): decoded \(batch.count) tasks")
                page += 1
            } else {
                let preview = String(data: data.prefix(300), encoding: .utf8) ?? "<non-UTF8>"
                print("⚠️ Vikunja tasks/all: JSON decode failed. Response preview: \(preview)")
                break
            }
        }

        for task in allTasks { taskCache[task.id] = task }
        return allTasks
    }

    private func fetchTasksForProjects(_ projects: [VikunjaProject]) async throws -> [VikunjaTask] {
        var allTasks: [VikunjaTask] = []
        for project in flattenProjects(projects) {
            let tasks = (try? await fetchTasksForProject(project.id)) ?? []
            allTasks.append(contentsOf: tasks)
        }
        for task in allTasks { taskCache[task.id] = task }
        return allTasks
    }

    private func fetchTasksForProject(_ projectId: Int) async throws -> [VikunjaTask] {
        var allTasks: [VikunjaTask] = []
        var page = 1
        while true {
            let url = apiURL("projects/\(projectId)/tasks", queryItems: [
                URLQueryItem(name: "page", value: String(page))
            ])
            print("➡️ Vikunja GET projects/\(projectId)/tasks page:\(page)")
            let request = makeRequest(url)
            let (data, response) = try await session.data(for: request)
            try checkResponse(response, data: data, context: "projects/\(projectId)/tasks p\(page)")
            if let batch = try? JSONDecoder().decode([VikunjaTask].self, from: data) {
                if batch.isEmpty { break }
                allTasks.append(contentsOf: batch)
                print("   projects/\(projectId)/tasks p\(page): decoded \(batch.count) tasks")
                page += 1
            } else {
                let preview = String(data: data.prefix(300), encoding: .utf8) ?? "<non-UTF8>"
                print("⚠️ Vikunja projects/\(projectId)/tasks: JSON decode failed. Response preview: \(preview)")
                break
            }
        }
        return allTasks
    }

    private func fetchVikunjaProjects() async throws -> [VikunjaProject] {
        let url = apiURL("projects")
        print("➡️ Vikunja GET projects — \(url.absoluteString)")
        let request = makeRequest(url)
        let (data, response) = try await session.data(for: request)
        try checkResponse(response, data: data, context: "projects")
        if let decoded = try? JSONDecoder().decode([VikunjaProject].self, from: data) {
            print("   projects: decoded \(decoded.count)")
            return decoded
        } else {
            let preview = String(data: data.prefix(300), encoding: .utf8) ?? "<non-UTF8>"
            print("⚠️ Vikunja projects: JSON decode failed. Response preview: \(preview)")
            return []
        }
    }

    private func fetchVikunjaLabels() async throws -> [VikunjaLabel] {
        let url = apiURL("labels")
        print("➡️ Vikunja GET labels — \(url.absoluteString)")
        let request = makeRequest(url)
        let (data, response) = try await session.data(for: request)
        try checkResponse(response, data: data, context: "labels")
        if let decoded = try? JSONDecoder().decode([VikunjaLabel].self, from: data) {
            print("   labels: decoded \(decoded.count)")
            return decoded
        } else {
            let preview = String(data: data.prefix(300), encoding: .utf8) ?? "<non-UTF8>"
            print("⚠️ Vikunja labels: JSON decode failed. Response preview: \(preview)")
            return []
        }
    }

    // MARK: - Mapping Vikunja → App Models

    private func mapTask(_ t: VikunjaTask) -> TodoTask {
        TodoTask(
            id: String(t.id),
            title: t.title,
            description: t.description,
            completed: t.done ?? false,
            priority: vikunjaPriorityToApp(t.priority),
            dueDate: extractDateString(t.dueDate),
            dueTime: nil,
            projectId: t.projectId.map { String($0) },
            sectionId: t.bucketId.map { String($0) },
            labels: t.labels?.map { String($0.id) },
            subtasks: nil,
            comments: nil,
            attachments: nil,
            createdAt: t.created,
            completedAt: t.doneAt,
            recurring: nil,
            recurringMode: nil,
            estimation: nil
        )
    }

    private func mapProject(_ p: VikunjaProject) -> Project {
        Project(
            id: String(p.id),
            name: p.title,
            slug: "",
            color: normalizeColor(p.hexColor),
            shared: false,
            sections: nil,
            taskOrder: nil
        )
    }

    private func mapLabel(_ l: VikunjaLabel) -> Label {
        Label(id: String(l.id), name: l.title, slug: "", color: normalizeColor(l.hexColor))
    }

    private func flattenProjects(_ projects: [VikunjaProject]) -> [VikunjaProject] {
        projects.flatMap { [$0] + flattenProjects($0.childProjects ?? []) }
    }

    // MARK: - Mapping App → Vikunja (for write operations)

    private func buildUpdateBody(from dict: [String: Any], taskId: Int) -> [String: Any] {
        // Start from the cached task so Vikunja always receives the required fields
        // (at minimum: id, title, project_id). Then overlay the changed fields.
        var body: [String: Any] = ["id": taskId]
        if let cached = taskCache[taskId] {
            body["title"] = cached.title
            body["done"] = cached.done ?? false
            body["priority"] = cached.priority ?? 0
            if let pid = cached.projectId { body["project_id"] = pid }
            if let desc = cached.description { body["description"] = desc }
            if let due = cached.dueDate { body["due_date"] = due }
            if let bid = cached.bucketId { body["bucket_id"] = bid }
            if let labels = cached.labels { body["labels"] = labels.map { ["id": $0.id] } }
        }
        // Overlay with the incoming diff
        if let title = dict["title"] as? String { body["title"] = title }
        if let desc = dict["description"] as? String { body["description"] = desc }
        if let completed = dict["completed"] as? Bool { body["done"] = completed }
        if let priority = dict["priority"] as? Int { body["priority"] = appPriorityToVikunja(priority) }
        if let dueDate = dict["dueDate"] as? String, !dueDate.isEmpty {
            body["due_date"] = "\(dueDate)T00:00:00Z"
        } else if dict["dueDate"] is NSNull {
            body["due_date"] = NSNull()
        }
        if let labelIds = dict["labels"] as? [String] {
            body["labels"] = labelIds.compactMap { Int($0) }.map { ["id": $0] }
        }
        if let projectId = dict["projectId"] as? String, let pid = Int(projectId) {
            body["project_id"] = pid
        }
        return body
    }

    private func buildCreateBody(from dict: [String: Any]) -> [String: Any] {
        var body: [String: Any] = ["title": dict["title"] as? String ?? "New Task"]
        if let desc = dict["description"] as? String { body["description"] = desc }
        if let priority = dict["priority"] as? Int { body["priority"] = appPriorityToVikunja(priority) }
        if let dueDate = dict["dueDate"] as? String, !dueDate.isEmpty {
            body["due_date"] = "\(dueDate)T00:00:00Z"
        }
        if let labelIds = dict["labels"] as? [String] {
            body["labels"] = labelIds.compactMap { Int($0) }.map { ["id": $0] }
        }
        return body
    }

    // MARK: - Conversion Helpers

    /// Vikunja: 0=none, 1=low, 2=medium, 3=high, 4=urgent, 5=do now → App: nil/1/2/3
    private func vikunjaPriorityToApp(_ p: Int?) -> Int? {
        switch p {
        case 0, nil: return nil
        case 1, 2:   return 3  // low
        case 3:      return 2  // medium
        default:     return 1  // high (4, 5)
        }
    }

    /// App: 1=high, 2=medium, 3=low → Vikunja: 4/3/1
    private func appPriorityToVikunja(_ p: Int) -> Int {
        switch p {
        case 1: return 4
        case 2: return 3
        case 3: return 1
        default: return 0
        }
    }

    /// Extract yyyy-MM-dd from ISO8601. Returns nil for Vikunja's zero-date "0001-01-01...".
    private func extractDateString(_ iso: String?) -> String? {
        guard let iso = iso, iso.count >= 10, !iso.hasPrefix("0001-") else { return nil }
        return String(iso.prefix(10))
    }

    /// Ensure color has "#" prefix; default to neutral gray.
    private func normalizeColor(_ hex: String?) -> String {
        guard let hex = hex, !hex.isEmpty else { return "#808080" }
        return hex.hasPrefix("#") ? hex : "#\(hex)"
    }
}
