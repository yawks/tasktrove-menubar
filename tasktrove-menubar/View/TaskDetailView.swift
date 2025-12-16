import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject var viewModel: TaskListViewModel
    @State private var task: TodoTask // Work on a local copy

    var isCreating: Bool
    var onDismiss: () -> Void // Callback to dismiss the view

    // State for popovers
    @State private var showingProjectPicker = false
    @State private var showingLabelPicker = false
    @State private var showingDatePicker = false
    @State private var showingPriorityPicker = false

    // State for new items
    @State private var newSubtaskTitle = ""
    @State private var newCommentText = ""

    init(task: TodoTask, isCreating: Bool, onDismiss: @escaping () -> Void) {
        _task = State(initialValue: task)
        self.isCreating = isCreating
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with Back button and Title
            HStack {
                Button(action: {
                    if !isCreating {
                        viewModel.updateTaskImmediately(self.task) // Save if editing
                    }
                    self.onDismiss() // Always dismiss
                }) {
                    Image(systemName: "chevron.left")
                    Text("Tasks")
                }
                .buttonStyle(.plain)

                Spacer()

                Text(isCreating ? "New Task" : "Edit Task")
                    .font(.headline)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text("Title").font(.caption).foregroundColor(.secondary)
                    TextField("Task title", text: $task.title)
                        .textFieldStyle(.roundedBorder)

                    // Description
                    Text("Description").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: Binding(
                        get: { task.description ?? "" },
                        set: { task.description = $0 }
                    ))
                    .frame(minHeight: 100)
                    .padding(4) // Internal padding
                    .background(Color.clear)
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )


                    // Project Picker
                    Text("Project").font(.caption).foregroundColor(.secondary)
                    Button(action: { showingProjectPicker = true }) {
                        HStack {
                            if let project = viewModel.project(for: self.task) {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(Color(hex: project.color) ?? .secondary)
                                Text(project.name)
                            } else {
                                Text("No Project")
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding(8).background(Color.secondary.opacity(0.1)).cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingProjectPicker) {
                        VStack(alignment: .leading) {
                            // "No Project" option
                            Button(action: {
                                task.projectId = nil
                                showingProjectPicker = false
                            }) {
                                HStack {
                                    Image(systemName: "folder")
                                    Text("No Project")
                                    Spacer()
                                    if task.projectId == nil {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            Divider()

                            // List of projects
                            ForEach(viewModel.allProjects) { project in
                                Button(action: {
                                    task.projectId = project.id
                                    showingProjectPicker = false
                                }) {
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(Color(hex: project.color) ?? .secondary)
                                        Text(project.name)
                                        Spacer()
                                        if task.projectId == project.id {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        .frame(width: 250)
                    }

                    // Label Picker
                    Text("Labels").font(.caption).foregroundColor(.secondary)
                    Button(action: { showingLabelPicker = true }) {
                         HStack {
                            if (self.task.labels ?? []).isEmpty {
                                Text("No Labels")
                                Spacer()
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(viewModel.labels(for: self.task)) { label in
                                            ItemPillView(item: label, iconName: "tag.fill")
                                        }
                                    }
                                }
                            }
                            Image(systemName: "chevron.right")
                        }
                        .padding(8).background(Color.secondary.opacity(0.1)).cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingLabelPicker) {
                        MultiSelectPickerView(
                            title: "Select Labels",
                            items: viewModel.allLabels,
                            iconName: "tag.fill",
                            selections: Binding(
                                get: { Set(self.task.labels ?? []) },
                                set: { self.task.labels = Array($0) }
                            )
                        )
                    }

                    // Due Date Picker
                    Text("Due Date").font(.caption).foregroundColor(.secondary)
                    Button(action: { showingDatePicker = true }) {
                        HStack {
                            Text(formattedDueDateText())
                            Spacer()
                            if self.task.dueDate != nil {
                                Button(action: { self.task.dueDate = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.secondary)
                            }
                        }
                        .padding(8).background(Color.secondary.opacity(0.1)).cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingDatePicker) {
                        VStack {
                            HStack(spacing: 12) {
                                Button(action: {
                                    self.task.dueDate = isoString(from: Date())
                                    showingDatePicker = false
                                }) {
                                    HStack {
                                        Image(systemName: "sun.max.fill").foregroundColor(.yellow)
                                        Text("Today")
                                    }
                                }

                                Button(action: {
                                    if let d = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                                        self.task.dueDate = isoString(from: d)
                                    }
                                    showingDatePicker = false
                                }) {
                                    HStack {
                                        Image(systemName: "sunrise.fill").foregroundColor(.orange)
                                        Text("Tomorrow")
                                    }
                                }

                                Button(action: {
                                    if let d = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) {
                                        self.task.dueDate = isoString(from: d)
                                    }
                                    showingDatePicker = false
                                }) {
                                     HStack {
                                        Image(systemName: "arrow.right.square.fill").foregroundColor(.green)
                                        Text("Next Week")
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.top)

                            DatePicker(
                                "Due Date",
                                selection: Binding(
                                    get: { parseDate(from: self.task.dueDate) ?? Date() },
                                    set: { self.task.dueDate = isoString(from: $0) }
                                ),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                        }
                        .padding()
                        .frame(width: 250)
                    }


                    // Priority Picker
                    Text("Priority").font(.caption).foregroundColor(.secondary)
                    Button(action: { showingPriorityPicker = true }) {
                        HStack {
                            priorityView(for: self.task.priority ?? 4)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding(8).background(Color.secondary.opacity(0.1)).cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingPriorityPicker) {
                        VStack(alignment: .leading) {
                            ForEach(1...4, id: \.self) { priority in
                                Button(action: {
                                    self.task.priority = priority
                                    showingPriorityPicker = false
                                }) {
                                    HStack {
                                        priorityView(for: priority)
                                        Spacer()
                                        if self.task.priority == priority || (self.task.priority == nil && priority == 4) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        .frame(width: 200)
                    }

                    // Subtasks
                    Text("Subtasks").font(.caption).foregroundColor(.secondary)
                    if let _ = task.subtasks {
                        ForEach(task.subtasks!.indices, id: \.self) { idx in
                            Button(action: {
                                task.subtasks![idx].completed = !(task.subtasks![idx].completed ?? false)
                            }) {
                                HStack {
                                    Image(systemName: (task.subtasks![idx].completed ?? false) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor((task.subtasks![idx].completed ?? false) ? .green : .secondary)
                                    Text(task.subtasks![idx].title)
                                        .strikethrough(task.subtasks![idx].completed ?? false, color: .secondary)
                                        .foregroundColor((task.subtasks![idx].completed ?? false) ? .secondary : .primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Add new subtask UI
                    HStack {
                        TextField("New subtask...", text: $newSubtaskTitle)
                        Button("Add") {
                            if !newSubtaskTitle.isEmpty {
                                let newId = UUID().uuidString
                                let order = task.subtasks?.count ?? 0
                                let newSubtask = TodoSubtask(id: newId, title: newSubtaskTitle, completed: false, order: order)
                                if task.subtasks == nil {
                                    task.subtasks = [newSubtask]
                                } else {
                                    task.subtasks!.append(newSubtask)
                                }
                                newSubtaskTitle = ""
                            }
                        }
                    }

                    // Comments
                    Text("Comments").font(.caption).foregroundColor(.secondary)
                    if (task.comments ?? []).isEmpty {
                        Text("No comments yet.").italic().foregroundColor(.secondary)
                    } else {
                        ForEach(task.comments ?? []) { comment in
                            Text(comment.content ?? "")
                                .padding(8)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    // Add new comment UI
                    HStack {
                        TextField("Add a comment...", text: $newCommentText)
                        Button("Add") {
                            if !newCommentText.isEmpty {
                                let newComment = Comment(id: UUID().uuidString, content: newCommentText, createdAt: isoStringForComment(from: Date()))
                                if task.comments == nil {
                                    task.comments = [newComment]
                                } else {
                                    task.comments!.append(newComment)
                                }
                                newCommentText = ""
                            }
                        }
                    }
                }
                .padding()
            }

            if isCreating {
                Divider()
                HStack {
                    Spacer()
                    Button("Cancel") {
                        self.onDismiss()
                    }
                    Button("Create Task") {
                        Task {
                            await viewModel.createTask(self.task)
                            self.onDismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private func priorityView(for priority: Int) -> some View {
        switch priority {
        case 1:
            HStack {
                Image(systemName: "flag.fill").foregroundColor(.red)
                Text("Priority 1")
            }
        case 2:
            HStack {
                Image(systemName: "flag.fill").foregroundColor(.orange)
                Text("Priority 2")
            }
        case 3:
            HStack {
                Image(systemName: "flag.fill").foregroundColor(.blue)
                Text("Priority 3")
            }
        default:
            HStack {
                Image(systemName: "flag").foregroundColor(.secondary)
                Text("No Priority")
            }
        }
    }

    // Date helpers to convert between ISO8601 strings and Date
    private func parseDate(from string: String?) -> Date? {
        guard let string = string else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: string) {
            return date
        }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df.date(from: string)
    }

    // Helper to convert Date to yyyy-MM-dd string format for API (dueDate)
    private func isoString(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    
    // Helper to convert Date to ISO8601 string for comments (createdAt)
    private func isoStringForComment(from date: Date) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.string(from: date)
    }

    private func formattedDueDateText() -> String {
        if let dueDateString = task.dueDate, let date = parseDate(from: dueDateString) {
            let df = DateFormatter()
            df.dateStyle = .long
            df.timeStyle = .none
            return df.string(from: date)
        }
        return "No due date"
    }
}