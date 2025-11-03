import SwiftUI

struct TaskRowView: View {
    @EnvironmentObject var viewModel: TaskListViewModel
    let task: TodoTask

    // State for inline editing
    @State private var isEditing = false
    @State private var editingTitle: String = ""
    @FocusState private var isTitleFieldFocused: Bool

    // State for inline popovers
    @State private var showingProjectPicker = false
    @State private var showingLabelPicker = false
    @State private var showingDatePicker = false
    @State private var showingPriorityPicker = false

    // Temporary selections for popovers
    @State private var selectedLabelIDs: Set<String> = []
    @State private var selectedProjectId: String? = nil
    @State private var selectedPriority: Int? = nil
    @State private var selectedDueDate: Date = Date()

    // State for hover effect
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Checkbox
                let isCompleted = task.completed ?? false
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .green : .secondary)
                    .font(.title2)
                    .onTapGesture {
                        viewModel.toggleTaskCompletion(for: task)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    // Editable Title
                    if isEditing {
                        TextField("Edit title", text: $editingTitle)
                            .textFieldStyle(.plain)
                            .focused($isTitleFieldFocused)
                            .onSubmit(commitEdit)
                    } else {
                        Text(task.title)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .onTapGesture(count: 2, perform: startEditing)
                            .onTapGesture(count: 1) {
                                openTaskDetail()
                            }
                    }

                    // Subtitle: Project & Section
                    if let project = viewModel.project(for: task), let section = viewModel.section(for: task) {
                        Text(String(format: NSLocalizedString("task_subtitle_format", comment: "Project • Section"), project.name, section.name))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Single line for all metadata
                    HStack(spacing: 8) {
                        // Project pill (small, colored) with popover
                        Button(action: {
                            // Prepare selection and show popover
                            selectedProjectId = task.projectId
                            showingProjectPicker = true
                        }) {
                            if let project = viewModel.project(for: task) {
                                ProjectPill(project: project)
                            } else {
                                Text("No Project")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.secondary.opacity(0.08))
                                    .cornerRadius(6)
                            }
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showingProjectPicker) {
                            VStack(alignment: .leading) {
                                Button(action: {
                                    var mutated = task
                                    mutated.projectId = nil
                                    viewModel.updateTaskImmediately(mutated)
                                    showingProjectPicker = false
                                }) {
                                    HStack {
                                        Image(systemName: "folder")
                                        Text("No Project")
                                        Spacer()
                                        if task.projectId == nil { Image(systemName: "checkmark") }
                                    }
                                }
                                .buttonStyle(.plain)

                                Divider()

                                ForEach(viewModel.allProjects) { project in
                                    Button(action: {
                                        var mutated = task
                                        mutated.projectId = project.id
                                        viewModel.updateTaskImmediately(mutated)
                                        showingProjectPicker = false
                                    }) {
                                        HStack {
                                            Image(systemName: "folder.fill").foregroundColor(Color(hex: project.color) ?? .secondary)
                                            Text(project.name)
                                            Spacer()
                                            if task.projectId == project.id { Image(systemName: "checkmark") }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                            .frame(width: 260)
                        }

                        // Labels with multi-select popover
                        let labels = viewModel.labels(for: task)
                        Button(action: {
                            selectedLabelIDs = Set(task.labels ?? [])
                            showingLabelPicker = true
                        }) {
                            if labels.isEmpty {
                                Text("No Labels")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.secondary.opacity(0.08))
                                    .cornerRadius(8)
                            } else {
                                HStack {
                                    ForEach(labels.prefix(2)) { label in
                                        LabelPill(label: label)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showingLabelPicker) {
                            MultiSelectPickerView(
                                title: "Select Labels",
                                items: viewModel.allLabels,
                                iconName: "tag.fill",
                                selections: $selectedLabelIDs
                            )
                            .onDisappear {
                                // Update task labels when popover closes
                                var mutated = task
                                mutated.labels = Array(selectedLabelIDs)
                                viewModel.updateTaskImmediately(mutated)
                            }
                        }

                        Spacer()

                        // Subtask Indicator
                        let subtasks = task.subtasks ?? []
                        if !subtasks.isEmpty {
                            HStack(spacing: 2) {
                                Image(systemName: "checklist")
                                Text("\(subtasks.filter { $0.completed ?? false }.count)/\(subtasks.count)")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }

                        // Priority with popover
                        Button(action: {
                            selectedPriority = task.priority ?? 4
                            showingPriorityPicker = true
                        }) {
                            if task.priority != nil && task.priority != 4 {
                                priorityView(for: task.priority ?? 4)
                                    .font(.caption)
                            } else {
                                priorityView(for: 4).font(.caption)
                            }
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showingPriorityPicker) {
                            VStack(alignment: .leading) {
                                ForEach(1...4, id: \.self) { priority in
                                    Button(action: {
                                        var mutated = task
                                        mutated.priority = priority == 4 ? nil : priority
                                        viewModel.updateTaskImmediately(mutated)
                                        showingPriorityPicker = false
                                    }) {
                                        HStack {
                                            priorityView(for: priority)
                                            Spacer()
                                            if (task.priority ?? 4) == priority { Image(systemName: "checkmark") }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                            .frame(width: 200)
                        }

                        // Due Date with popover
                        Button(action: {
                            selectedDueDate = parseDate(from: task.dueDate) ?? Date()
                            showingDatePicker = true
                        }) {
                            if let dueDateString = task.dueDate, let dueDate = parseDate(from: dueDateString) {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                    Text(formatRelativeDate(dueDate))
                                }
                                .font(.caption)
                                .foregroundColor(isOverdue(dueDate) ? .red : .secondary)
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                    Text("No due date")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showingDatePicker) {
                            VStack {
                                HStack(spacing: 12) {
                                    Button(action: {
                                        var mutated = task
                                        mutated.dueDate = isoString(from: Date())
                                        viewModel.updateTaskImmediately(mutated)
                                        showingDatePicker = false
                                    }) {
                                        HStack { Image(systemName: "sun.max.fill").foregroundColor(.yellow); Text("Today") }
                                    }

                                    Button(action: {
                                        if let d = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                                            var mutated = task
                                            mutated.dueDate = isoString(from: d)
                                            viewModel.updateTaskImmediately(mutated)
                                        }
                                        showingDatePicker = false
                                    }) {
                                        HStack { Image(systemName: "sunrise.fill").foregroundColor(.orange); Text("Tomorrow") }
                                    }

                                    Button(action: {
                                        if let d = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) {
                                            var mutated = task
                                            mutated.dueDate = isoString(from: d)
                                            viewModel.updateTaskImmediately(mutated)
                                        }
                                        showingDatePicker = false
                                    }) {
                                        HStack { Image(systemName: "arrow.right.square.fill").foregroundColor(.green); Text("Next Week") }
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.top)

                                DatePicker(
                                    "Due Date",
                                    selection: Binding(
                                        get: { selectedDueDate },
                                        set: { newDate in
                                            selectedDueDate = newDate
                                            var mutated = task
                                            mutated.dueDate = isoString(from: newDate)
                                            viewModel.updateTaskImmediately(mutated)
                                        }
                                    ),
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                            }
                            .padding()
                            .frame(width: 260)
                        }
                    }
                    .padding(.top, 2)
                }

                Button(action: {
                    viewModel.isLoadingDetail = true
                    // A short delay to allow the UI to update and show the loader
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        viewModel.selectedTask = task
                        viewModel.isLoadingDetail = false
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)

        }
        .background(isHovering ? Color.secondary.opacity(0.1) : Color.clear)
        .onHover { hovering in
            isHovering = hovering
        }
        // Report the row's height to a preference so the list can compute how many fit
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: RowHeightPreferenceKey.self, value: geo.size.height)
            }
        )
    }

    private func isOverdue(_ date: Date) -> Bool {
        return Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
    }

    @ViewBuilder
    private func priorityView(for priority: Int) -> some View {
        switch priority {
        case 1:
            HStack(spacing: 2) {
                Image(systemName: "flag.fill").foregroundColor(.red)
                Text("P1")
            }
        case 2:
            HStack(spacing: 2) {
                Image(systemName: "flag.fill").foregroundColor(.orange)
                Text("P2")
            }
        case 3:
            HStack(spacing: 2) {
                Image(systemName: "flag.fill").foregroundColor(.blue)
                Text("P3")
            }
        default:
            EmptyView()
        }
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInYesterday(date) {
            return "hier"
        }
        if calendar.isDateInToday(date) {
            return "aujourd'hui"
        }
        if calendar.isDateInTomorrow(date) {
            return "demain"
        }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    // Helper to parse ISO8601 date string (optional) to Date
    private func parseDate(from string: String?) -> Date? {
        guard let string = string, !string.isEmpty else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        // Try full ISO8601 with time first
        if let date = isoFormatter.date(from: string) {
            return date
        }
        // Try just date (yyyy-MM-dd)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.date(from: string)
    }

    // Helper to convert Date to ISO8601 string
    private func isoString(from date: Date) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.string(from: date)
    }

    // MARK: - Inline Editing Methods

    private func startEditing() {
        editingTitle = task.title
        isEditing = true
        // Delay focus to ensure the text field is visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isTitleFieldFocused = true
        }
    }

    private func commitEdit() {
        if !editingTitle.isEmpty && editingTitle != task.title {
            var mutatedTask = task
            mutatedTask.title = editingTitle
            viewModel.updateTask(mutatedTask)
        }
        isEditing = false
    }

    private func openTaskDetail() {
        viewModel.isLoadingDetail = true
        // A short delay to allow the UI to update and show the loader
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            viewModel.selectedTask = task
            viewModel.isLoadingDetail = false
        }
    }
}

// A small view for displaying a label as a colored "pill".
struct LabelPill: View {
    let label: Label

    var body: some View {
        Text(label.name)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(hex: label.color)?.opacity(0.3) ?? .gray.opacity(0.3))
            .cornerRadius(8)
    }
}

// Extension to allow initializing Color from a hex string.
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

struct TaskRowView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TaskListViewModel(networkService: MockNetworkService())
        viewModel.fetchData()

        // Need to wait for the async fetch to complete for the preview
        // A better way is to have synchronous mock data for previews.
        return Group {
            if let task = viewModel.allTasks.first {
                TaskRowView(task: task)
                    .environmentObject(viewModel)
                    .padding()
            } else {
                Text("Loading preview...")
            }
        }
        .frame(width: 400)
    }
}

// A small view for displaying a project as a colored pill (smaller font)
struct ProjectPill: View {
    let project: Project

    var body: some View {
        Text(project.name)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(hex: project.color)?.opacity(0.15) ?? .gray.opacity(0.15))
            .cornerRadius(6)
    }
}
