import XCTest
@testable import Tasker

class NetworkServiceTests: XCTestCase {

    func testMockNetworkServiceFetchTasks() async throws {
        // 1. Initialize the mock service
        let mockService: NetworkServiceProtocol = MockNetworkService()

        // 2. Call the fetch method
        do {
            let response = try await mockService.fetchTasks()

            // 3. Assert that the data is what we expect from tasks.json
            XCTAssertEqual(response.version, "v0.6.0")
            XCTAssertFalse(response.tasks.isEmpty)
            XCTAssertFalse(response.projects.isEmpty)
            XCTAssertEqual(response.tasks.first?.title, "Multi collections et DMRag et fichiers uploadés")

        } catch {
            XCTFail("Mock service failed to fetch or decode tasks: \(error)")
        }
    }

    func testMockNetworkServiceUpdateTasks() async throws {
        // 1. Initialize the mock service
        let mockService: NetworkServiceProtocol = MockNetworkService()

        // 2. Create a dummy task to "update"
        // We can create a lightweight task since the mock doesn't inspect the data.
        let dummyTask = Task(
            id: UUID(), title: "Test", description: "", completed: false, priority: 1,
            dueDate: Date(), projectId: UUID(), sectionId: UUID(), labels: [],
            subtasks: [], comments: [], attachments: [], createdAt: Date(),
            status: "active", recurringMode: "none"
        )

        // 3. Call the update method and ensure it doesn't throw an error
        do {
            try await mockService.updateTasks([dummyTask])
            // The test passes if the call completes without throwing.
        } catch {
            XCTFail("Mock service update should not throw an error, but it did: \(error)")
        }
    }
}