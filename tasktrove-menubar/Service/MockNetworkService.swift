import Foundation

/// A mock implementation of `NetworkServiceProtocol` for testing and previewing purposes.
class MockNetworkService: NetworkServiceProtocol {

    private let decoder: JSONDecoder

    init() {
        // Configure JSON Decoder with the same strategy as the real service
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
    }

    func fetchTasks() async throws -> APIResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Use the static JSON string from MockData
        let data = Data(MockData.tasksJSON.utf8)

        do {
            return try decoder.decode(APIResponse.self, from: data)
        } catch {
            // This is useful for debugging decoding errors in the mock data
            print("Mock decoding error: \(error)")
            throw error
        }
    }

    func updateTasks(_ tasks: [TodoTask]) async throws {
        // Simulate a successful network call with a short delay.
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        print("Mock: Pretended to update \(tasks.count) tasks.")
    }
}