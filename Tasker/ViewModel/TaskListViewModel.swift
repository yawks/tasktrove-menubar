import Foundation
import Combine

enum SortOption: String, CaseIterable, Identifiable {
    case defaultOrder = "Default"
    case dueDate = "Due Date"
    case priority = "Priority"

    var id: String { self.rawValue }
}

@MainActor
class TaskListViewModel: ObservableObject {

    // MARK: - Published Properties

    // Raw data from the API
    @Published private(set) var allTasks: [Task] = []
    @Published private(set) var allProjects: [Project] = []
    @Published private(set) var allLabels: [Label] = []

    // State management
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    // Filtering & Sorting criteria
    @Published var selectedProjectID: UUID?
    @Published var selectedLabelIDs = Set<UUID>()
    @Published var sortOption: SortOption = .defaultOrder

    // MARK: - Computed Properties

    /// Returns tasks filtered and sorted by the current criteria.
    var filteredTasks: [Task] {
        var tasks = filterTasksByDueDate(allTasks)
        tasks = filterTasksByProject(tasks)
        tasks = filterTasksByLabels(tasks)

        // Apply sorting
        switch sortOption {
        case .defaultOrder:
            // This requires mapping tasks to their order in the project's taskOrder array.
            // For simplicity, we'll keep the original order for now. A more robust
            // implementation would use the `taskOrder` array from the `Project` model.
            break
        case .dueDate:
            tasks.sort { $0.dueDate < $1.dueDate }
        case .priority:
            // Assuming higher priority number means more important (e.g., P1 > P2)
            tasks.sort { $0.priority > $1.priority }
        }

        return tasks
    }

    // MARK: - Private Properties

    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let updateSubject = PassthroughSubject<Task, Never>()
    private var dirtyTaskIDs = Set<UUID>()

    // MARK: - Initializer

    init(networkService: NetworkServiceProtocol = MockNetworkService()) { // Default to Mock for easier previewing
        self.networkService = networkService
        setupDebouncer()
    }

    // MARK: - Public Methods

    /// Fetches all necessary data from the API, merging it with any local changes.
    func fetchData() {
        // Don't fetch if a fetch is already in progress.
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let response = try await networkService.fetchTasks()

                // Merge server data with local changes to avoid overwriting edits
                let serverTasks = response.tasks
                let dirtyTasks = self.allTasks.filter { self.dirtyTaskIDs.contains($0.id) }
                let dirtyTasksByID = Dictionary(uniqueKeysWithValues: dirtyTasks.map { ($0.id, $0) })

                let mergedTasks = serverTasks.map { serverTask in
                    return dirtyTasksByID[serverTask.id] ?? serverTask
                }

                self.allTasks = mergedTasks
                self.allProjects = response.projects
                self.allLabels = response.labels

            } catch {
                self.errorMessage = NSLocalizedString("error_fetch_failed", comment: "Error message for network fetch failure")
            }

            self.isLoading = false
        }
    }

    /// Triggers an update for a given task.
    /// The update is debounced to avoid excessive network calls.
    /// - Parameter task: The task that has been modified.
    func updateTask(_ task: Task) {
        // Update the local task array immediately for snappy UI
        if let index = allTasks.firstIndex(where: { $0.id == task.id }) {
            allTasks[index] = task
            dirtyTaskIDs.insert(task.id) // Mark task as dirty
        }
        // Push the task to the debouncer
        updateSubject.send(task)
    }

    /// Toggles the completion status of a task.
    func toggleTaskCompletion(for task: Task) {
        var mutatedTask = task
        mutatedTask.completed.toggle()
        updateTask(mutatedTask)
    }

    /// Toggles the completion status of a subtask within a parent task.
    func toggleSubtaskCompletion(for subtask: Subtask, in parentTask: Task) {
        // Find the index of the parent task in the main array
        guard let parentTaskIndex = allTasks.firstIndex(where: { $0.id == parentTask.id }) else { return }

        // Find the index of the subtask within that parent task
        guard let subtaskIndex = allTasks[parentTaskIndex].subtasks.firstIndex(where: { $0.id == subtask.id }) else { return }

        // Since Task and Subtask are structs, this modification creates a new copy of the Task.
        // We can now directly modify the subtask in our array.
        allTasks[parentTaskIndex].subtasks[subtaskIndex].completed.toggle()

        // Get the now-modified parent task
        let updatedParentTask = allTasks[parentTaskIndex]

        // Trigger the update process
        updateTask(updatedParentTask)
    }

    // MARK: - Private Methods

    /// Sets up a Combine pipeline to debounce update requests.
    private func setupDebouncer() {
        updateSubject
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .collect() // Collect all updates that occurred during the window
            .sink { [weak self] tasks in
                // Remove duplicates, keeping the latest update for each task
                let uniqueTasks = Dictionary(tasks.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last }).values
                self?.sendUpdate(tasks: Array(uniqueTasks))
            }
            .store(in: &cancellables)
    }

    /// Sends the updated tasks to the network service.
    private func sendUpdate(tasks: [Task]) {
        guard !tasks.isEmpty else { return }

        let taskIDsToUpdate = tasks.map { $0.id }

        Task {
            do {
                try await networkService.updateTasks(tasks)
                print("Successfully updated \(tasks.count) tasks.")
                // On success, remove these task IDs from the dirty set
                for id in taskIDsToUpdate {
                    self.dirtyTaskIDs.remove(id)
                }
            } catch {
                // Handle error: show a banner, offer retry, or rollback changes
                errorMessage = NSLocalizedString("error_update_failed", comment: "Error message for network update failure")
                // To implement rollback, we would need to keep a copy of the original state.
            }
        }
    }

    // MARK: - Private Filtering Methods

    private func filterTasksByDueDate(_ tasks: [Task]) -> [Task] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return tasks.filter { task in
            let taskDueDate = calendar.startOfDay(for: task.dueDate)
            return taskDueDate <= today
        }
    }

    private func filterTasksByProject(_ tasks: [Task]) -> [Task] {
        guard let projectID = selectedProjectID else {
            return tasks // No project filter applied
        }
        return tasks.filter { $0.projectId == projectID }
    }

    private func filterTasksByLabels(_ tasks: [Task]) -> [Task] {
        guard !selectedLabelIDs.isEmpty else {
            return tasks // No label filter applied
        }
        return tasks.filter { task in
            let taskLabelSet = Set(task.labels)
            return !selectedLabelIDs.isDisjoint(with: taskLabelSet) // OR logic
        }
    }

    // MARK: - Data Resolution Methods

    /// Finds a project by its ID.
    func project(for task: Task) -> Project? {
        return allProjects.first { $0.id == task.projectId }
    }

    /// Finds a section within a project for a given task.
    func section(for task: Task) -> Section? {
        guard let project = project(for: task) else { return nil }
        return project.sections.first { $0.id == task.sectionId }
    }

    /// Finds all labels associated with a task.
    func labels(for task: Task) -> [Label] {
        let taskLabelSet = Set(task.labels)
        return allLabels.filter { taskLabelSet.contains($0.id) }
    }
}