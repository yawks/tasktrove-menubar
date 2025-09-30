import Foundation

/// Defines the interface for a service that interacts with the tasks API.
/// Using a protocol allows for dependency injection, making it easy to swap
/// the live network service with a mock for testing purposes.
protocol NetworkServiceProtocol {

    /// Fetches the main data structure containing tasks, projects, labels, etc.
    /// - Returns: An `APIResponse` object.
    /// - Throws: An error if the network request fails or decoding fails.
    func fetchTasks() async throws -> APIResponse

    /// Updates one or more tasks on the server.
    /// - Parameter tasks: An array of dictionaries, where each dictionary represents a partial task update.
    /// - Throws: An error if the network request or encoding fails.
    func updateTasks(_ tasks: [[String: Any]]) async throws

    /// Creates a new task on the server.
    /// - Parameter taskData: A dictionary representing the new task.
    /// - Throws: An error if the network request or encoding fails.
    func createTask(_ taskData: [String: Any]) async throws
}