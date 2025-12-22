import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provided endpoint URL is not valid. Please ensure it includes 'http://' or 'https://'."
        }
    }
}

/// The concrete implementation of `NetworkServiceProtocol` that performs live network requests.
class NetworkService: NetworkServiceProtocol {

    /// Deletes a label via DELETE /labels
    func deleteLabel(id: String) async throws {
        let url = baseURL.appendingPathComponent("labels")
        var request = createAuthenticatedRequest(url: url, method: "DELETE")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["id": id]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        if let jsonString = String(data: request.httpBody ?? Data(), encoding: .utf8) {
            print("➡️ Deleting Label with body:")
            print(jsonString)
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print("❌ Network Error (deleteLabel):\nStatus code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            print("Body: \(String(data: data, encoding: .utf8) ?? "<non-UTF8>")")
            throw URLError(.badServerResponse)
        }
        print("⬅️ Label deleted successfully.")
    }

    /// Updates an existing label via PATCH /labels
    func updateLabel(_ label: Label) async throws {
        let url = baseURL.appendingPathComponent("labels")
        var request = createAuthenticatedRequest(url: url, method: "PATCH")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(label)
        request.httpBody = data

        if let jsonString = String(data: data, encoding: .utf8) {
            print("➡️ Updating Label with body:")
            print(jsonString)
        }

        let (responseData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print("❌ Network Error (updateLabel):\nStatus code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            print("Body: \(String(data: responseData, encoding: .utf8) ?? "<non-UTF8>")")
            throw URLError(.badServerResponse)
        }
        print("⬅️ Label updated successfully.")
    }

    /// Creates a new label via POST /labels
    func createLabel(_ label: Label) async throws {
        let url = baseURL.appendingPathComponent("labels")
        var request = createAuthenticatedRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(label)
        request.httpBody = data

        if let jsonString = String(data: data, encoding: .utf8) {
            print("➡️ Creating Label with body:")
            print(jsonString)
        }

        let (responseData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print("❌ Network Error (createLabel):\nStatus code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            print("Body: \(String(data: responseData, encoding: .utf8) ?? "<non-UTF8>")")
            throw URLError(.badServerResponse)
        }
        print("⬅️ Label created successfully.")
    }

    /// Deletes one or more projects via DELETE /projects
    func deleteProjects(ids: [String]) async throws {
        let url = baseURL.appendingPathComponent("projects")
        var request = createAuthenticatedRequest(url: url, method: "DELETE")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["ids": ids]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        if let jsonString = String(data: request.httpBody ?? Data(), encoding: .utf8) {
            print("➡️ Deleting Projects with body:")
            print(jsonString)
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print("❌ Network Error (deleteProjects):\nStatus code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            print("Body: \(String(data: data, encoding: .utf8) ?? "<non-UTF8>")")
            throw URLError(.badServerResponse)
        }
        print("⬅️ Project(s) deleted successfully.")
    }

    /// Updates an existing project via PATCH /projects
    func updateProject(_ project: Project) async throws {
        let url = baseURL.appendingPathComponent("projects")
        var request = createAuthenticatedRequest(url: url, method: "PATCH")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build the JSON body from the Project model
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(project)
        request.httpBody = data

        if let jsonString = String(data: data, encoding: .utf8) {
            print("➡️ Updating Project with body:")
            print(jsonString)
        }

        let (responseData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print("❌ Network Error (updateProject):\nStatus code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            print("Body: \(String(data: responseData, encoding: .utf8) ?? "<non-UTF8>")")
            throw URLError(.badServerResponse)
        }
        print("⬅️ Project updated successfully.")
    }

    /// Creates a new project via POST /projects
    func createProject(_ project: Project) async throws {
        let url = baseURL.appendingPathComponent("projects")
        var request = createAuthenticatedRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build the JSON body from the Project model
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(project)
        request.httpBody = data

        if let jsonString = String(data: data, encoding: .utf8) {
            print("➡️ Creating Project with body:")
            print(jsonString)
        }

        let (responseData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print("❌ Network Error (createProject):\nStatus code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            print("Body: \(String(data: responseData, encoding: .utf8) ?? "<non-UTF8>")")
            throw URLError(.badServerResponse)
        }
        print("⬅️ Project created successfully.")
    }

    /// Fetches all projects from the /projects endpoint
    func fetchProjects() async throws -> [Project] {
        let url = baseURL.appendingPathComponent("projects")
        let request = createAuthenticatedRequest(url: url, method: "GET")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print("❌ Network Error (fetchProjects):\nStatus code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw URLError(.badServerResponse)
        }
        if let jsonString = String(data: data, encoding: .utf8) {
            print("⬅️ Received Projects JSON:")
            print(jsonString)
        }
        // Try decoding directly as an array first
        do {
            let decoded = try decoder.decode([Project].self, from: data)
            print("📦 Decoded Projects (array):")
            dump(decoded.prefix(3))
            return decoded
        } catch {
            print("⚠️ Direct decode to [Project] failed: \(error). Falling back to tolerant parsing...")
        }

        // Fallback: parse JSON and build Project objects tolerate missing fields
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])

            // Helper to convert an array-of-dicts into [Project]
            func projectsFromArray(_ arr: [[String: Any]]) -> [Project] {
                var results: [Project] = []
                for dict in arr {
                    // Required-ish fields with fallbacks
                    guard let id = dict["id"] as? String ?? dict["_id"] as? String else { continue }
                    let name = dict["name"] as? String ?? dict["title"] as? String ?? "Unnamed Project"
                    let slug = dict["slug"] as? String ?? ""
                    let color = dict["color"] as? String ?? "#000000"
                    let shared = dict["shared"] as? Bool ?? false

                    var sections: [Section] = []
                    if let rawSections = dict["sections"] as? [[String: Any]] {
                        for s in rawSections {
                            if let sid = s["id"] as? String ?? s["_id"] as? String,
                               let sname = s["name"] as? String {
                                let scolor = s["color"] as? String ?? "#000000"
                                sections.append(Section(id: sid, name: sname, color: scolor))
                            }
                        }
                    }

                    let taskOrder = dict["taskOrder"] as? [String] ?? dict["task_order"] as? [String]

                    let project = Project(id: id, name: name, slug: slug, color: color, shared: shared, sections: sections, taskOrder: taskOrder)
                    results.append(project)
                }
                return results
            }

            if let arr = jsonObject as? [[String: Any]] {
                let projects = projectsFromArray(arr)
                print("📦 Decoded Projects (from top-level array) - count: \(projects.count)")
                dump(projects.prefix(3))
                return projects
            }

            if let dict = jsonObject as? [String: Any] {
                // Try common wrapper keys
                let candidates = ["projects", "data", "items", "results"]
                for key in candidates {
                    if let arr = dict[key] as? [[String: Any]] {
                        let projects = projectsFromArray(arr)
                        print("📦 Decoded Projects (from key '\(key)') - count: \(projects.count)")
                        dump(projects.prefix(3))
                        return projects
                    }
                }

                // Fallback: first array value
                for (_, value) in dict {
                    if let arr = value as? [[String: Any]] {
                        let projects = projectsFromArray(arr)
                        print("📦 Decoded Projects (from first array value) - count: \(projects.count)")
                        dump(projects.prefix(3))
                        return projects
                    }
                }
            }

            print("❌ No projects array found in JSON payload.")
            return []
        } catch {
            print("❌ Failed to parse Projects JSON: \(error)")
            throw error
        }
    }

    /// Fetches all labels from the /labels endpoint
    func fetchLabels() async throws -> [Label] {
        let url = baseURL.appendingPathComponent("labels")
        let request = createAuthenticatedRequest(url: url, method: "GET")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print("❌ Network Error (fetchLabels):\nStatus code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw URLError(.badServerResponse)
        }
        if let jsonString = String(data: data, encoding: .utf8) {
            print("⬅️ Received Labels JSON:")
            print(jsonString)
        }
        // Try decoding directly as an array first
        do {
            let decoded = try decoder.decode([Label].self, from: data)
            print("📦 Decoded Labels (array):")
            dump(decoded.prefix(3))
            return decoded
        } catch {
            print("⚠️ Direct decode to [Label] failed: \(error). Falling back to tolerant parsing...")
        }

        // Fallback: parse JSON and build Label objects tolerate missing fields
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])

            func labelsFromArray(_ arr: [[String: Any]]) -> [Label] {
                var results: [Label] = []
                for dict in arr {
                    guard let id = dict["id"] as? String ?? dict["_id"] as? String else { continue }
                    let name = dict["name"] as? String ?? dict["title"] as? String ?? "Unnamed Label"
                    let slug = dict["slug"] as? String ?? ""
                    let color = dict["color"] as? String ?? "#000000"
                    results.append(Label(id: id, name: name, slug: slug, color: color))
                }
                return results
            }

            if let arr = jsonObject as? [[String: Any]] {
                let labels = labelsFromArray(arr)
                print("📦 Decoded Labels (from top-level array) - count: \(labels.count)")
                dump(labels.prefix(3))
                return labels
            }

            if let dict = jsonObject as? [String: Any] {
                let candidates = ["labels", "data", "items", "results"]
                for key in candidates {
                    if let arr = dict[key] as? [[String: Any]] {
                        let labels = labelsFromArray(arr)
                        print("📦 Decoded Labels (from key '\(key)') - count: \(labels.count)")
                        dump(labels.prefix(3))
                        return labels
                    }
                }

                for (_, value) in dict {
                    if let arr = value as? [[String: Any]] {
                        let labels = labelsFromArray(arr)
                        print("📦 Decoded Labels (from first array value) - count: \(labels.count)")
                        dump(labels.prefix(3))
                        return labels
                    }
                }
            }

            print("❌ No labels array found in JSON payload.")
            return []
        } catch {
            print("❌ Failed to parse Labels JSON: \(error)")
            throw error
        }
    }
    /// Supprime une ou plusieurs tâches via DELETE /tasks
    func deleteTasks(ids: [String]) async throws {
        let url = baseURL.appendingPathComponent("tasks")
        var request = createAuthenticatedRequest(url: url, method: "DELETE")
        let body: [String: Any] = ["ids": ids]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if httpResponse.statusCode == 403 {
            throw AuthError.forbidden
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ Network Error (deleteTasks):")
            print("Status code: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
            print("Body: \(String(data: data, encoding: .utf8) ?? "<non-UTF8>")")
            throw URLError(.badServerResponse)
        }
    }
    /// Met à jour une tâche unique via PATCH /tasks
    func updateTask(_ task: TodoTask) async throws {
        guard let dict = task.asDictionary() else {
            throw URLError(.badURL) // Erreur générique si l'encodage échoue
        }
        let url = baseURL.appendingPathComponent("tasks")
        var request = createAuthenticatedRequest(url: url, method: "PATCH")
        request.httpBody = try JSONSerialization.data(withJSONObject: dict, options: [])

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if httpResponse.statusCode == 403 {
            throw AuthError.forbidden
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ Network Error (updateTask):")
            print("Status code: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
            print("Body: \(String(data: data, encoding: .utf8) ?? "<non-UTF8>")")
            throw URLError(.badServerResponse)
        }
    }
    /// Crée une tâche à partir d'un objet TodoTask Swift
    func createTask(_ task: TodoTask) async throws {
        guard let dict = task.asDictionary() else {
            throw URLError(.badURL) // Erreur générique si l'encodage échoue
        }
        try await createTask(dict)
    }
    enum AuthError: Error {
        case forbidden
    }

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let bearerToken: String

    /// Initializes the service with a specific API configuration. Can throw an error if the URL is invalid.
    init(configuration: APIConfiguration) throws {
        guard let url = URL(string: configuration.endpoint) else {
            throw NetworkError.invalidURL
        }
        self.baseURL = url
        self.session = URLSession(configuration: .default)

        // Utilise la clé API comme bearer token
        self.bearerToken = configuration.apiKey

        // Configure JSON Decoder
        self.decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateString)")
        }

        // Configure JSON Encoder
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    /// Creates an authenticated request using Bearer token.
    private func createAuthenticatedRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    func fetchTasks() async throws -> APIResponse {
        let url = baseURL.appendingPathComponent("tasks")
        let request = createAuthenticatedRequest(url: url, method: "GET")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if httpResponse.statusCode == 403 {
            throw AuthError.forbidden
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ Network Error (fetchTasks):")
            print("Status code: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
            print("Body: \(String(data: data, encoding: .utf8) ?? "<non-UTF8>")")
            throw URLError(.badServerResponse)
        }

        // Log the received tasks for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("⬅️ Received Tasks JSON:")
            print(jsonString)
        } else {
            print("⚠️ Unable to decode received tasks data as UTF-8 string.")
        }

        // Attempt to decode and provide rich debug output on failure
        do {
            let decoded = try decoder.decode(APIResponse.self, from: data)
            print("📦 Decoded APIResponse:")
            dump(decoded)
            return decoded
        } catch {
            print("❌ Failed to decode APIResponse: \(error)")

            // Try to parse the raw JSON with JSONSerialization to get a readable structure
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
                print("🔍 Raw JSON object:")
                dump(jsonObject)
            } catch let parseError {
                print("⚠️ JSONSerialization failed: \(parseError)")
                print("⚠️ Raw body (fallback): \(String(data: data, encoding: .utf8) ?? "<non-UTF8>")")
            }

            // Rethrow the original decoding error so callers can handle it
            throw error
        }
    }

    /// Recursively traverses a dictionary or array and converts all UUID objects to lowercase strings.
    private func recursivelySanitize(value: Any) -> Any {
        if let uuid = value as? UUID {
            return uuid.uuidString.lowercased()
        } else if var array = value as? [Any] {
            for i in 0..<array.count {
                array[i] = recursivelySanitize(value: array[i])
            }
            return array
        } else if var dictionary = value as? [String: Any] {
            for (key, val) in dictionary {
                dictionary[key] = recursivelySanitize(value: val)
            }
            return dictionary
        }
        return value
    }

    func updateTasks(_ tasks: [[String: Any]]) async throws {
        let url = baseURL.appendingPathComponent("tasks")
        var request = createAuthenticatedRequest(url: url, method: "PATCH")

        // Sanitize the payload to ensure all UUIDs are lowercase strings, even nested ones.
        let sanitizedTasks = tasks.map { taskDict in
            return taskDict.mapValues { value in
                recursivelySanitize(value: value)
            }
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: sanitizedTasks, options: [])

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if httpResponse.statusCode == 403 {
            throw AuthError.forbidden
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    func createTask(_ taskData: [String: Any]) async throws {
        let url = baseURL.appendingPathComponent("tasks")
        var request = createAuthenticatedRequest(url: url, method: "POST")

        // Sanitize the payload to ensure all UUIDs are lowercase strings, even nested ones.
        let sanitizedTask = taskData.mapValues { value in
            recursivelySanitize(value: value)
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: sanitizedTask, options: [])

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if httpResponse.statusCode == 403 {
            throw AuthError.forbidden
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ Network Error (createTask):")
            print("Status code: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
            print("Body: \(String(data: data, encoding: .utf8) ?? "<non-UTF8>")")
            // You might want to decode an error message from the body here
            throw URLError(.badServerResponse)
        }
    }
}
