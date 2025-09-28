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

    @Published private(set) var allTasks: [Task] = []
    @Published private(set) var allProjects: [Project] = []
    @Published private(set) var allLabels: [Label] = []

    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    // Filtering & Sorting criteria
    @Published var selectedProjectID: UUID?
    @Published var selectedLabelIDs = Set<UUID>()
    @Published var sortOption: SortOption = .defaultOrder

    // MARK: - Computed Properties

    var filteredTasks: [Task] {
        var tasks = filterTasksByDueDate(allTasks)
        tasks = filterTasksByProject(tasks)
        tasks = filterTasksByLabels(tasks)

        switch sortOption {
        case .defaultOrder:
            break
        case .dueDate:
            tasks.sort { $0.dueDate < $1.dueDate }
        case .priority:
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

    init(networkService: NetworkServiceProtocol = MockNetworkService()) {
        self.networkService = networkService
        setupDebouncer()
    }

    // MARK: - Public Methods

    func fetchData() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let response = try await networkService.fetchTasks()

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

    func updateTask(_ task: Task) {
        if let index = allTasks.firstIndex(where: { $0.id == task.id }) {
            allTasks[index] = task
            dirtyTaskIDs.insert(task.id)
        }
        updateSubject.send(task)
    }

    func toggleTaskCompletion(for task: Task) {
        var mutatedTask = task
        mutatedTask.completed.toggle()
        updateTask(mutatedTask)
    }

    func toggleSubtaskCompletion(for subtask: Subtask, in parentTask: Task) {
        guard let parentTaskIndex = allTasks.firstIndex(where: { $0.id == parentTask.id }) else { return }
        guard let subtaskIndex = allTasks[parentTaskIndex].subtasks.firstIndex(where: { $0.id == subtask.id }) else { return }

        allTasks[parentTaskIndex].subtasks[subtaskIndex].completed.toggle()

        let updatedParentTask = allTasks[parentTaskIndex]
        updateTask(updatedParentTask)
    }

    // MARK: - Private Methods

    private func setupDebouncer() {
        updateSubject
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .collect()
            .sink { [weak self] tasks in
                let uniqueTasks = Dictionary(tasks.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last }).values
                self?.sendUpdate(tasks: Array(uniqueTasks))
            }
            .store(in: &cancellables)
    }

    private func sendUpdate(tasks: [Task]) {
        guard !tasks.isEmpty else { return }

        let taskIDsToUpdate = tasks.map { $0.id }

        Task {
            do {
                try await networkService.updateTasks(tasks)
                print("Successfully updated \(tasks.count) tasks.")
                for id in taskIDsToUpdate {
                    self.dirtyTaskIDs.remove(id)
                }
            } catch {
                errorMessage = NSLocalizedString("error_update_failed", comment: "Error message for network update failure")
            }
        }
    }

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
            return tasks
        }
        return tasks.filter { $0.projectId == projectID }
    }

    private func filterTasksByLabels(_ tasks: [Task]) -> [Task] {
        guard !selectedLabelIDs.isEmpty else {
            return tasks
        }
        return tasks.filter { task in
            let taskLabelSet = Set(task.labels)
            return !selectedLabelIDs.isDisjoint(with: taskLabelSet)
        }
    }

    // MARK: - Data Resolution Methods

    func project(for task: Task) -> Project? {
        return allProjects.first { $0.id == task.projectId }
    }

    func section(for task: Task) -> Section? {
        guard let project = project(for: task) else { return nil }
        return project.sections.first { $0.id == task.sectionId }
    }

    func labels(for task: Task) -> [Label] {
        let taskLabelSet = Set(task.labels)
        return allLabels.filter { taskLabelSet.contains($0.id) }
    }
}