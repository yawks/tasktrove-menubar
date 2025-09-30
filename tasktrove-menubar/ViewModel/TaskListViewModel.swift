import Foundation
import Combine

enum SortOption: String, CaseIterable, Identifiable {
    case defaultOrder = "Default"
    case dueDate = "Due Date"
    case priority = "Priority"

    var id: String { self.rawValue }
}

enum FilterCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case inbox = "Inbox"
    case today = "Today"
    case upcoming = "Upcoming"
    case completed = "Completed"

    var id: String { self.rawValue }
}

@MainActor
class TaskListViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var allTasks: [TodoTask] = []
    @Published private(set) var allProjects: [Project] = []
    @Published private(set) var allLabels: [Label] = []

    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    // Filtering & Sorting criteria
    @Published var selectedProjectIDs = Set<UUID>()
    @Published var selectedLabelIDs = Set<UUID>()
    @Published var sortOption: SortOption = .dueDate
    @Published var filterCategory: FilterCategory = .all

    // Navigation
    @Published var selectedTask: TodoTask?
    @Published var isLoadingDetail = false


    // Pagination
    @Published var currentPage: Int = 0
    private let itemsPerPage: Int = 5

    // MARK: - Computed Properties

    var totalPages: Int {
        let totalItems = filteredTasks.count
        return max(1, (totalItems + itemsPerPage - 1) / itemsPerPage)
    }

    var paginatedTasks: [TodoTask] {
        let allFiltered = filteredTasks
        let startIndex = currentPage * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, allFiltered.count)

        guard startIndex < endIndex else { return [] }

        return Array(allFiltered[startIndex..<endIndex])
    }

    func comparison<T: Comparable>(obj1: TodoTask, obj2: TodoTask, keyPath: KeyPath<TodoTask, T?>) -> Bool {
        switch (obj1[keyPath: keyPath], obj2[keyPath: keyPath]) {
        case let (lhs?, rhs?):
            return lhs < rhs
        case (nil, nil):
            return false
        case (nil, _?):
            return false // nil value goes after non-nil
        case (_?, nil):
            return true  // non-nil value goes before nil
        }
    }

    var filteredTasks: [TodoTask] {
        var tasks: [TodoTask]

        // 1. Primary Filter based on the selected category
        switch filterCategory {
        case .all:
            tasks = allTasks.filter { !$0.completed }
        case .inbox:
            tasks = allTasks.filter { $0.projectId == nil && !$0.completed }
        case .today:
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            tasks = allTasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                let taskDueDate = calendar.startOfDay(for: dueDate)
                return taskDueDate <= today && !task.completed
            }
        case .upcoming:
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            tasks = allTasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                let taskDueDate = calendar.startOfDay(for: dueDate)
                return taskDueDate > today && !task.completed
            }
        case .completed:
            tasks = allTasks.filter { $0.completed }
        }

        // 2. Secondary Filters (Project and Labels)
        if filterCategory != .inbox { // "Inbox" is for tasks without a project.
            tasks = filterTasksByProject(tasks)
        }
        if filterCategory != .completed { // The "Completed" view should not be filtered by labels.
            tasks = filterTasksByLabels(tasks)
        }


        // 3. Sorting
        switch sortOption {
        case .defaultOrder:
            // A more robust implementation would use the `taskOrder` array from the `Project` model.
            break
        case .dueDate:
            tasks.sort {
                comparison(obj1: $0, obj2: $1, keyPath: \.dueDate)
            }
        case .priority:
            tasks.sort {
                comparison(obj1: $0, obj2: $1, keyPath: \.priority)
            }
        }

        return tasks
    }

    // MARK: - Private Properties

    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let updateSubject = PassthroughSubject<TodoTask, Never>()
    private var dirtyTaskIDs = Set<UUID>()

    // MARK: - Initializer

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService

        // Load saved settings before setting up subscribers
        loadSettings()

        setupDebouncer()

        // Reset pagination and save settings whenever they change
        $selectedProjectIDs
            .dropFirst() // Ignore the initial value set by loadSettings
            .sink { [weak self] ids in
                SettingsService.shared.selectedProjectIDs = ids
                self?.resetPagination()
            }
            .store(in: &cancellables)

        $selectedLabelIDs
            .dropFirst()
            .sink { [weak self] ids in
                SettingsService.shared.selectedLabelIDs = ids
                self?.resetPagination()
            }
            .store(in: &cancellables)

        $sortOption
            .dropFirst()
            .sink { [weak self] option in
                SettingsService.shared.sortOption = option
                self?.resetPagination()
            }
            .store(in: &cancellables)

        $filterCategory
            .dropFirst()
            .sink { [weak self] category in
                SettingsService.shared.filterCategory = category
                self?.resetPagination()
            }
            .store(in: &cancellables)
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

    func updateTask(_ task: TodoTask) {
        if let index = allTasks.firstIndex(where: { $0.id == task.id }) {
            allTasks[index] = task
            dirtyTaskIDs.insert(task.id)
        }
        updateSubject.send(task)
    }

    func updateTaskImmediately(_ modifiedTask: TodoTask) {
        guard let originalTask = allTasks.first(where: { $0.id == modifiedTask.id }) else {
            print("Error: Could not find original task to create a diff.")
            return
        }

        let diff = createDiff(original: originalTask, modified: modifiedTask)

        // Update the local task list immediately
        if let index = allTasks.firstIndex(where: { $0.id == modifiedTask.id }) {
            allTasks[index] = modifiedTask
        }

        // Only send the update if there are actual changes
        guard diff.count > 1 else { // > 1 because 'id' is always present
            print("No changes detected for task \(modifiedTask.id). Skipping update.")
            return
        }

        // Send the update to the server immediately
        Task {
            do {
                try await networkService.updateTasks([diff])
                print("Successfully updated task \(modifiedTask.id).")
                self.dirtyTaskIDs.remove(modifiedTask.id)
            } catch {
                errorMessage = NSLocalizedString("error_update_failed", comment: "Error message for network update failure")
            }
        }
    }

    func nextPage() {
        if currentPage < totalPages - 1 {
            currentPage += 1
        }
    }

    func previousPage() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }

    func resetPagination() {
        currentPage = 0
    }

    func toggleTaskCompletion(for task: TodoTask) {
        var mutatedTask = task
        mutatedTask.completed.toggle()
        updateTask(mutatedTask)
    }

    func toggleSubtaskCompletion(for subtask: TodoSubtask, in parentTask: TodoTask) {
        guard let parentTaskIndex = allTasks.firstIndex(where: { $0.id == parentTask.id }) else { return }
        guard let subtaskIndex = allTasks[parentTaskIndex].subtasks.firstIndex(where: { $0.id == subtask.id }) else { return }

        allTasks[parentTaskIndex].subtasks[subtaskIndex].completed.toggle()

        let updatedParentTask = allTasks[parentTaskIndex]
        updateTask(updatedParentTask)
    }

    // MARK: - Private Methods

    private func createDiff(original: TodoTask, modified: TodoTask) -> [String: Any] {
        var diff = [String: Any]()
        diff["id"] = modified.id

        if original.title != modified.title {
            diff["title"] = modified.title
        }
        if original.description != modified.description {
            diff["description"] = modified.description ?? NSNull()
        }
        if original.completed != modified.completed {
            diff["completed"] = modified.completed
        }
        if original.priority != modified.priority {
            diff["priority"] = modified.priority ?? NSNull()
        }
        if original.dueDate != modified.dueDate {
            if let date = modified.dueDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                diff["dueDate"] = formatter.string(from: date)
            } else {
                diff["dueDate"] = NSNull()
            }
        }
        if original.projectId != modified.projectId {
            diff["projectId"] = modified.projectId ?? NSNull()
        }
        if Set(original.labels) != Set(modified.labels) {
            diff["labels"] = modified.labels
        }
        if original.subtasks != modified.subtasks {
            // The API expects an array of dictionaries for subtasks
            let subtaskDicts = modified.subtasks.map { subtask in
                return ["id": subtask.id, "title": subtask.title, "completed": subtask.completed, "order": subtask.order]
            }
            diff["subtasks"] = subtaskDicts
        }

        return diff
    }

    private func loadSettings() {
        sortOption = SettingsService.shared.sortOption
        filterCategory = SettingsService.shared.filterCategory
        selectedProjectIDs = SettingsService.shared.selectedProjectIDs
        selectedLabelIDs = SettingsService.shared.selectedLabelIDs
    }

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

    private func sendUpdate(tasks: [TodoTask]) {
        guard !tasks.isEmpty else { return }

        let diffs = tasks.compactMap { modifiedTask -> [String: Any]? in
            guard let originalTask = self.allTasks.first(where: { $0.id == modifiedTask.id }) else { return nil }
            let diff = self.createDiff(original: originalTask, modified: modifiedTask)
            return diff.count > 1 ? diff : nil
        }

        guard !diffs.isEmpty else {
            print("No effective changes to update.")
            return
        }

        let taskIDsToUpdate = tasks.map { $0.id }

        Task {
            do {
                try await networkService.updateTasks(diffs)
                print("Successfully updated \(diffs.count) tasks.")
                for id in taskIDsToUpdate {
                    self.dirtyTaskIDs.remove(id)
                }
            } catch {
                errorMessage = NSLocalizedString("error_update_failed", comment: "Error message for network update failure")
            }
        }
    }

    private func filterTasksByProject(_ tasks: [TodoTask]) -> [TodoTask] {
        guard !selectedProjectIDs.isEmpty else {
            return tasks
        }
        return tasks.filter {
            guard let projID = $0.projectId else { return false }
            return selectedProjectIDs.contains(projID)
        }
    }

    private func filterTasksByLabels(_ tasks: [TodoTask]) -> [TodoTask] {
        guard !selectedLabelIDs.isEmpty else {
            return tasks
        }
        return tasks.filter { task in
            let taskLabelSet = Set(task.labels)
            return !selectedLabelIDs.isDisjoint(with: taskLabelSet)
        }
    }

    // MARK: - Computed Properties for UI

    var selectedProjects: [Project] {
        // Create a dictionary for quick lookups
        let projectsByID = Dictionary(uniqueKeysWithValues: allProjects.map { ($0.id, $0) })
        // Map selected IDs to project objects, maintaining order if necessary
        return selectedProjectIDs.compactMap { projectsByID[$0] }
    }

    var selectedLabels: [Label] {
        let labelsByID = Dictionary(uniqueKeysWithValues: allLabels.map { ($0.id, $0) })
        return selectedLabelIDs.compactMap { labelsByID[$0] }
    }


    // MARK: - Data Resolution Methods

    func project(for task: TodoTask) -> Project? {
        return allProjects.first { $0.id == task.projectId }
    }

    func section(for task: TodoTask) -> Section? {
        guard let project = project(for: task) else { return nil }
        return project.sections.first { $0.id == task.sectionId }
    }

    func labels(for task: TodoTask) -> [Label] {
        let taskLabelSet = Set(task.labels)
        return allLabels.filter { taskLabelSet.contains($0.id) }
    }
}
