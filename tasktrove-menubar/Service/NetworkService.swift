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

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let basicAuthHeader: String

    /// Initializes the service with a specific API configuration. Can throw an error if the URL is invalid.
    init(configuration: APIConfiguration, password: String?) throws {
        guard let url = URL(string: configuration.endpoint) else {
            throw NetworkError.invalidURL
        }
        self.baseURL = url
        self.session = URLSession(configuration: .default)

        // Setup Basic Auth header
        let loginString = "\(configuration.login):\(password ?? "")"
        let loginData = loginString.data(using: .utf8)!
        self.basicAuthHeader = "Basic \(loginData.base64EncodedString())"

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

    /// Creates an authenticated request using the stored Basic Authentication header.
    private func createAuthenticatedRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(basicAuthHeader, forHTTPHeaderField: "Authorization")
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