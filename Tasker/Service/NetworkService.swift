import Foundation

/// The concrete implementation of `NetworkServiceProtocol` that performs live network requests.
class NetworkService: NetworkServiceProtocol {

    private let baseURL = URL(string: "https://api.example.com/api")! // Placeholder URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init() {
        self.session = URLSession(configuration: .default)

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
        self.encoder.dateEncodingStrategy = .iso8601 // Standard for sending data
    }

    /// Creates an authenticated request using Basic Authentication.
    private func createAuthenticatedRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method

        // Basic Auth - credentials should be stored securely (e.g., Keychain)
        let username = "user" // Placeholder
        let password = "password" // Placeholder
        let loginData = "\(username):\(password)".data(using: .utf8)!
        let base64LoginString = loginData.base64EncodedString()

        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return request
    }

    func fetchTasks() async throws -> APIResponse {
        let url = baseURL.appendingPathComponent("tasks")
        let request = createAuthenticatedRequest(url: url, method: "GET")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try decoder.decode(APIResponse.self, from: data)
    }

    func updateTasks(_ tasks: [TodoTask]) async throws {
        let url = baseURL.appendingPathComponent("tasks")
        var request = createAuthenticatedRequest(url: url, method: "PATCH")

        request.httpBody = try encoder.encode(tasks)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}