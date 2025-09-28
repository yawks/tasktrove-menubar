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
    /// - Parameter tasks: An array of `Task` objects to be updated.
    /// - Throws: An error if the network request or encoding fails.
    func updateTasks(_ tasks: [Task]) async throws
}