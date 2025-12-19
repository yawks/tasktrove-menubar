import Foundation
import Combine
import SwiftUI

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
    
    // MARK: - Date Parsing Helpers
    // Reuse these formatters to avoid recreating them for each task
    private static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func parseDueDate(_ isoString: String) -> Date? {
        // Try ISO8601 with fractional seconds first, then fall back to a date-only format.
        if let d = Self.iso8601WithFractionalSeconds.date(from: isoString) {
            return d
        }
        return Self.dateOnlyFormatter.date(from: isoString)
    }
    
    /// Formats a Date to yyyy-MM-dd string format for API requests
    private static func formatDateForAPI(_ date: Date) -> String {
        return dateOnlyFormatter.string(from: date)
    }
    
    /// Converts a date string (ISO8601 or yyyy-MM-dd) to yyyy-MM-dd format for API
    private static func normalizeDateString(_ dateString: String?) -> String? {
        guard let dateString = dateString, !dateString.isEmpty else { return nil }
        
        // If already in yyyy-MM-dd format, return as is
        if dateString.count == 10 && dateString.split(separator: "-").count == 3 {
            return dateString
        }
        
        // Try to parse and reformat
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: dateString) {
            return dateOnlyFormatter.string(from: date)
        }
        
        // Try with basic ISO8601
        let basicIsoFormatter = ISO8601DateFormatter()
        if let date = basicIsoFormatter.date(from: dateString) {
            return dateOnlyFormatter.string(from: date)
        }
        
        // If all parsing fails, try to extract yyyy-MM-dd from the string
        let components = dateString.split(separator: "T")
        if let firstComponent = components.first, firstComponent.count == 10 {
            return String(firstComponent)
        }
        
        return nil
    }

    // MARK: - Published Properties

    @Published private(set) var allTasks: [TodoTask] = []
    @Published private(set) var allProjects: [Project] = []
    @Published private(set) var allLabels: [Label] = []
    @Published private(set) var filteredTasksCache: [TodoTask] = []

    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var isCacheStale = false

    // Filtering & Sorting criteria
    @Published var selectedProjectIDs = Set<String>()
    @Published var selectedLabelIDs = Set<String>()
    @Published var sortOption: SortOption = .dueDate
    @Published var filterCategory: FilterCategory = .all

    // Navigation
    @Published var selectedTask: TodoTask?
    @Published var isLoadingDetail = false


    // Pagination
    @Published var currentPage: Int = 0
    // Make itemsPerPage adjustable at runtime (driven by the view measuring available space)
    @Published var itemsPerPage: Int = 5

    // MARK: - Computed Properties

    var totalPages: Int {
        let totalItems = filteredTasksCache.count
        return max(1, (totalItems + itemsPerPage - 1) / itemsPerPage)
    }

    var paginatedTasks: [TodoTask] {
        let allFiltered = filteredTasksCache
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

    func createTask(_ task: TodoTask) async {
        var taskData: [String: Any] = [
                "title": task.title,
            "comments": task.comments ?? []
        ]
        if let description = task.description, !description.isEmpty {
            taskData["description"] = description
        }
        if let priority = task.priority {
            taskData["priority"] = priority
        }
        if let dueDate = task.dueDate {
            // Normalize date to yyyy-MM-dd format for API
            taskData["dueDate"] = Self.normalizeDateString(dueDate) ?? dueDate
        }
        if let projectId = task.projectId {
            taskData["projectId"] = projectId
        }
        if let labels = task.labels, !labels.isEmpty {
            taskData["labels"] = labels
        }

        Task {
            do {
                try await networkService.createTask(taskData)
                print("Successfully created task.")
                // Refresh data to see the new task
                fetchData()
            } catch {
                errorMessage = "Failed to create the new task."
            }
        }
    }

    private func computeFilteredTasks() -> [TodoTask] {
        var tasks: [TodoTask]

        // 1. Primary Filter based on the selected category
        switch filterCategory {
        case .all:
            tasks = allTasks.filter { t in
                // Show if not completed (false or nil)
                t.completed != true
            }
        case .inbox:
            tasks = allTasks.filter { t in
                // Inbox: no projectId (nil or empty) and not completed (false or nil)
                (t.projectId == nil || t.projectId == "") && t.completed != true
            }
        case .today:
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            tasks = allTasks.filter { task in
                guard let dueDateStr = task.dueDate, let dueDate = parseDueDate(dueDateStr) else { return false }
                let taskDueDate = calendar.startOfDay(for: dueDate)
                // Include overdue (taskDueDate < today) and tasks due today (==)
                return taskDueDate <= today && task.completed != true
            }
        case .upcoming:
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            tasks = allTasks.filter { task in
                guard let dueDateStr = task.dueDate, let dueDate = parseDueDate(dueDateStr) else { return false }
                let taskDueDate = calendar.startOfDay(for: dueDate)
                return taskDueDate > today && task.completed != true
            }
        case .completed:
            tasks = allTasks.filter { $0.completed == true }
        }

        // 2. Secondary Filters (Project and Labels)
        let hasProjects = !(allProjects.isEmpty)
        let hasLabels = !(allLabels.isEmpty)
        if filterCategory != .inbox && hasProjects { // "Inbox" is for tasks without a project.
            tasks = filterTasksByProject(tasks)
        }
        if filterCategory != .completed && hasLabels { // The "Completed" view should not be filtered by labels.
            tasks = filterTasksByLabels(tasks)
        }

        // 3. Sorting
        switch sortOption {
        case .defaultOrder:
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

    private func refreshFilteredCacheIfNeeded(animated: Bool = true) {
        let newFiltered = computeFilteredTasks()
        guard newFiltered != filteredTasksCache else { return }
        if animated {
            withAnimation(.default) {
                filteredTasksCache = newFiltered
            }
        } else {
            filteredTasksCache = newFiltered
        }
    }

    // MARK: - Private Properties

    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let updateSubject = PassthroughSubject<TodoTask, Never>()
    private var dirtyTaskIDs = Set<String>()

    // MARK: - Initializer

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService

        // Load cached data first for instant UI, then load user settings
        loadFromCache()
        loadSettings()

        self.refreshFilteredCacheIfNeeded(animated: false)

        setupDebouncer()

        // Fetch fresh data when the view model is created
        fetchData()

        // Reset pagination and save settings whenever they change
        $selectedProjectIDs
            .dropFirst()
            .sink { [weak self] ids in
                SettingsService.shared.selectedProjectIDs = ids
                self?.resetPagination()
                self?.refreshFilteredCacheIfNeeded()
            }
            .store(in: &cancellables)

        $selectedLabelIDs
            .dropFirst()
            .sink { [weak self] ids in
                SettingsService.shared.selectedLabelIDs = ids
                self?.resetPagination()
                self?.refreshFilteredCacheIfNeeded()
            }
            .store(in: &cancellables)

        $sortOption
            .dropFirst()
            .sink { [weak self] option in
                SettingsService.shared.sortOption = option
                self?.resetPagination()
                self?.refreshFilteredCacheIfNeeded()
            }
            .store(in: &cancellables)

        $filterCategory
            .dropFirst()
            .sink { [weak self] category in
                SettingsService.shared.filterCategory = category
                self?.resetPagination()
                self?.refreshFilteredCacheIfNeeded()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    @Published var showSettingsOnAuthError = false
    @Published var lastAuthConfig: (endpoint: String, apiKey: String)? = nil

    func fetchData() {
        // Immediately load cached data for instant UI display
        loadFromCache()
        
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {
            self.isCacheStale = true
            defer {
                self.isCacheStale = false
                self.isLoading = false
            }
            do {
                let response = try await networkService.fetchTasks()
                let serverTasks = response.tasks ?? []
                async let fetchedProjects = (networkService as? NetworkService)?.fetchProjects()
                async let fetchedLabels = (networkService as? NetworkService)?.fetchLabels()
                let projects = await (try? fetchedProjects) ?? []
                let labels = await (try? fetchedLabels) ?? []

                if serverTasks != self.allTasks || projects != self.allProjects || labels != self.allLabels {
                    // When caching the API response, ensure all three are included.
                    SettingsService.shared.cachedAPIResponse = APIResponse(tasks: serverTasks, projects: projects, labels: labels, projectGroups: nil, labelGroups: nil, version: nil)
                    
                    let dirtyTasks = self.allTasks.filter { self.dirtyTaskIDs.contains($0.id ?? "") }
                    let dirtyTasksByID = Dictionary(uniqueKeysWithValues: dirtyTasks.map { ($0.id, $0) })
                    let mergedTasks = serverTasks.map { serverTask in dirtyTasksByID[serverTask.id] ?? serverTask }
                    self.allTasks = mergedTasks

                    // Only update projects if non-empty, else retain cached.
                    if !projects.isEmpty {
                        self.allProjects = projects
                    }
                    // Only update labels if non-empty, else retain cached.
                    if !labels.isEmpty {
                        self.allLabels = labels
                    }
                    
                    self.refreshFilteredCacheIfNeeded()
                } else {
                    // Update projects and labels only if non-empty, do not refresh filteredTasksCache otherwise.
                    if !projects.isEmpty {
                        self.allProjects = projects
                    }
                    if !labels.isEmpty {
                        self.allLabels = labels
                    }
                }
            } catch let error as NetworkService.AuthError {
                if case .forbidden = error {
                    let configService = ConfigurationService.shared
                    let endpoint = configService.configuration?.endpoint ?? ""
                    let apiKey = configService.configuration?.apiKey ?? ""
                    self.lastAuthConfig = (endpoint: endpoint, apiKey: apiKey)
                    self.showSettingsOnAuthError = true
                }
            } catch {
                // For non-auth errors, log details and keep existing UI state instead of opening settings immediately
                print("❌ fetchData failed with error: \(error)")
                self.errorMessage = NSLocalizedString("error_fetch_failed", comment: "Error message for network fetch failure")
                // If it's a decoding error, the NetworkService already printed the raw JSON and error; we just surface a message
                // Do not forcibly present settings for generic network/decode errors to avoid wiping the UI.
            }
        }
    }

    func updateTask(_ task: TodoTask) {
        if let id = task.id, let index = allTasks.firstIndex(where: { $0.id == id }) {
            allTasks[index] = task
            dirtyTaskIDs.insert(id)
        }
        updateSubject.send(task)
    }

    func updateTaskImmediately(_ modifiedTask: TodoTask) {
        guard let id = modifiedTask.id, let originalTask = allTasks.first(where: { $0.id == id }) else {
            print("Error: Could not find original task to create a diff.")
            return
        }

        let diff = createDiff(original: originalTask, modified: modifiedTask)

        // Update the local task list immediately
        if let index = allTasks.firstIndex(where: { $0.id == id }) {
            allTasks[index] = modifiedTask
        }

        // Only send the update if there are actual changes
        guard diff.count > 1 else { // > 1 because 'id' is always present
            print("No changes detected for task \(String(describing: modifiedTask.id)). Skipping update.")
            return
        }

        // Send the update to the server immediately
        Task {
            do {
                try await networkService.updateTasks([diff])
                if let id = modifiedTask.id { self.dirtyTaskIDs.remove(id) }
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
        mutatedTask.completed = !(task.completed ?? false)
        updateTaskImmediately(mutatedTask)
    }

    func toggleSubtaskCompletion(for subtask: TodoSubtask, in parentTask: TodoTask) {
      guard let parentTaskId = parentTask.id, let parentTaskIndex = allTasks.firstIndex(where: { $0.id == parentTaskId }) else { return }
      guard let subtaskId = subtask.id,
          let subtasks = allTasks[parentTaskIndex].subtasks,
          let subtaskIndex = subtasks.firstIndex(where: { $0.id == subtaskId }) else { return }

      var updatedSubtasks = subtasks
      updatedSubtasks[subtaskIndex].completed = !(updatedSubtasks[subtaskIndex].completed ?? false)
      allTasks[parentTaskIndex].subtasks = updatedSubtasks

      let updatedParentTask = allTasks[parentTaskIndex]
      updateTask(updatedParentTask)
    }

    // MARK: - Private Methods

    func loadFromCache() {
        if let cachedResponse = SettingsService.shared.cachedAPIResponse {
            self.allTasks = cachedResponse.tasks ?? []
            self.allProjects = cachedResponse.projects ?? []
            self.allLabels = cachedResponse.labels ?? []
        }
    }

    func createDiff(original: TodoTask, modified: TodoTask) -> [String: Any] {
        var diff = [String: Any]()
        if let id = modified.id { diff["id"] = id }

        if original.title != modified.title {
            diff["title"] = modified.title
        }
        if original.description != modified.description {
            diff["description"] = modified.description ?? NSNull()
        }
        if (original.completed ?? false) != (modified.completed ?? false) {
            diff["completed"] = modified.completed ?? false
        }
        if original.priority != modified.priority {
            diff["priority"] = modified.priority ?? NSNull()
        }
        if original.dueDate != modified.dueDate {
            // Normalize date to yyyy-MM-dd format for API
            if let normalizedDate = Self.normalizeDateString(modified.dueDate) {
                diff["dueDate"] = normalizedDate
            } else {
                diff["dueDate"] = NSNull()
            }
        }
        if original.projectId != modified.projectId {
            diff["projectId"] = modified.projectId ?? NSNull()
        }
        let origLabels = Set(original.labels ?? [])
        let modLabels = Set(modified.labels ?? [])
        if origLabels != modLabels {
            diff["labels"] = modified.labels ?? []
        }
        if original.subtasks != modified.subtasks {
            let subtaskDicts = (modified.subtasks ?? []).map { subtask in
                return [
                    "id": subtask.id ?? "",
                    "title": subtask.title,
                    "completed": subtask.completed ?? false,
                    "order": subtask.order ?? 0
                ]
            }
            diff["subtasks"] = subtaskDicts
        }

        return diff
    }

    func loadSettings() {
        sortOption = SettingsService.shared.sortOption
        filterCategory = SettingsService.shared.filterCategory
        selectedProjectIDs = SettingsService.shared.selectedProjectIDs
        selectedLabelIDs = SettingsService.shared.selectedLabelIDs
    }

    func setupDebouncer() {
        updateSubject
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .collect()
            .sink { [weak self] tasks in
                let uniqueTasks = Dictionary(tasks.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last }).values
                self?.sendUpdate(tasks: Array(uniqueTasks))
            }
            .store(in: &cancellables)
    }

    func sendUpdate(tasks: [TodoTask]) {
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

        let taskIDsToUpdate = tasks.compactMap { $0.id }

        Task {
            do {
                try await networkService.updateTasks(diffs)
                for id in taskIDsToUpdate {
                    self.dirtyTaskIDs.remove(id)
                }
            } catch {
                errorMessage = NSLocalizedString("error_update_failed", comment: "Error message for network update failure")
            }
        }
    }

    func filterTasksByProject(_ tasks: [TodoTask]) -> [TodoTask] {
        guard !selectedProjectIDs.isEmpty else {
            return tasks
        }
        return tasks.filter {
            guard let projID = $0.projectId else { return false }
            return selectedProjectIDs.contains(projID)
        }
    }

    func filterTasksByLabels(_ tasks: [TodoTask]) -> [TodoTask] {
        guard !selectedLabelIDs.isEmpty else {
            return tasks
        }
        return tasks.filter { task in
            let taskLabelSet = Set(task.labels ?? [])
            return !selectedLabelIDs.isDisjoint(with: taskLabelSet)
        }
    }

    // MARK: - Computed Properties for UI

    var selectedProjects: [Project] {
        let projectsByID = Dictionary(uniqueKeysWithValues: allProjects.map { ($0.id, $0) })
        return selectedProjectIDs.compactMap { projectsByID[$0] }
    }

    var selectedLabels: [Label] {
        let labelsByID = Dictionary(uniqueKeysWithValues: allLabels.map { ($0.id, $0) })
        return selectedLabelIDs.compactMap { labelsByID[$0] }
    }


    // MARK: - Data Resolution Methods

    func project(for task: TodoTask) -> Project? {
        guard let pid = task.projectId else { return nil }
        return allProjects.first { $0.id == pid }
    }

    func section(for task: TodoTask) -> Section? {
        guard let project = project(for: task), let sid = task.sectionId else { return nil }
        // `sections` may be nil if the API omitted them; handle gracefully
        return project.sections?.first { $0.id == sid }
    }

    func labels(for task: TodoTask) -> [Label] {
        let taskLabelSet = Set(task.labels ?? [])
        return allLabels.filter { taskLabelSet.contains($0.id) }
    }
}

