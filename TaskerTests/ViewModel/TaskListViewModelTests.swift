import XCTest
import Combine
@testable import Tasker

@MainActor
class TaskListViewModelTests: XCTestCase {

    var viewModel: TaskListViewModel!
    var mockNetworkService: MockNetworkService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        viewModel = TaskListViewModel(networkService: mockNetworkService)
        cancellables = []
    }

    override func tearDown() {
        viewModel = nil
        mockNetworkService = nil
        cancellables = nil
        super.tearDown()
    }

    func testFetchDataSuccess() async {
        // Given
        let expectation = XCTestExpectation(description: "Fetch data and update properties")

        viewModel.$allTasks
            .dropFirst() // Ignore initial empty value
            .sink { tasks in
                if !tasks.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        viewModel.fetchData()

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.allTasks.count, 1)
        XCTAssertEqual(viewModel.allProjects.count, 1)
    }

    func testFilterTasksByDueDate() {
        // 1. GIVEN: A set of tasks with different due dates
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        // Create a base task to avoid boilerplate
        let baseTask = TodoTask(
            id: UUID(), title: "Test", description: "", completed: false, priority: 1,
            dueDate: Date(), projectId: UUID(), sectionId: UUID(), labels: [],
            subtasks: [], comments: [], attachments: [], createdAt: Date(),
            status: "active", recurringMode: "none"
        )

        var overdueTask = baseTask; overdueTask.id = UUID(); overdueTask.dueDate = yesterday
        var dueTodayTask = baseTask; dueTodayTask.id = UUID(); dueTodayTask.dueDate = today
        var futureTask = baseTask; futureTask.id = UUID(); futureTask.dueDate = tomorrow

        viewModel.allTasks = [overdueTask, dueTodayTask, futureTask]

        // 2. WHEN: The filteredTasks property is accessed
        let filtered = viewModel.filteredTasks

        // 3. THEN: Only overdue and today's tasks are included
        XCTAssertEqual(filtered.count, 2, "Should include tasks due today and overdue tasks.")
        XCTAssertTrue(filtered.contains(where: { $0.id == overdueTask.id }), "Overdue task should be included.")
        XCTAssertTrue(filtered.contains(where: { $0.id == dueTodayTask.id }), "Task due today should be included.")
        XCTAssertFalse(filtered.contains(where: { $0.id == futureTask.id }), "Future task should not be included.")
    }

    func testFilterByProject() async {
        // Given
        viewModel.fetchData()
        // Wait for the async fetch to complete
        await fulfillment(of: [XCTestExpectation(description: "wait")], timeout: 1)

        // When
        let projectID = UUID(uuidString: "42812db3-12a7-44e0-93da-7dafbf91019e")!
        viewModel.selectedProjectID = projectID

        // Then
        XCTAssertEqual(viewModel.filteredTasks.count, 1, "Should filter to the single task in the selected project.")

        // When
        viewModel.selectedProjectID = UUID() // A random, non-existent project

        // Then
        XCTAssertEqual(viewModel.filteredTasks.count, 0, "Should filter to zero tasks for a non-existent project.")
    }

    func testUpdateTaskDebouncing() async {
        // This test checks the immediate local update and that the task is marked as dirty.
        // Testing the Combine debouncer itself would require more complex expectation handling.

        // Given
        viewModel.fetchData()
        await fulfillment(of: [XCTestExpectation(description: "wait")], timeout: 1)

        guard var taskToUpdate = viewModel.allTasks.first else {
            XCTFail("No task to update")
            return
        }

        let newTitle = "Updated Title"
        taskToUpdate.title = newTitle

        // When
        viewModel.updateTask(taskToUpdate)

        // Then
        // Check for immediate local update
        XCTAssertEqual(viewModel.allTasks.first?.title, newTitle)
        XCTAssertTrue(viewModel.dirtyTaskIDs.contains(taskToUpdate.id))
    }
}