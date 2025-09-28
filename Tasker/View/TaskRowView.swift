import SwiftUI

struct TaskRowView: View {
    @EnvironmentObject var viewModel: TaskListViewModel
    let task: Task

    // State for inline editing
    @State private var isEditing = false
    @State private var editingTitle: String = ""
    @FocusState private var isTitleFieldFocused: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox
            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.completed ? .green : .secondary)
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
                        .onSubmit {
                            commitEdit()
                        }
                        .onAppear {
                            // Select all text when field appears
                            // This requires a bit more work, often involving AppKit integration.
                            // For now, focusing is sufficient.
                        }
                } else {
                    Text(task.title)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .onTapGesture(count: 2) {
                            startEditing()
                        }
                }

                // Subtitle: Project & Section
                if let project = viewModel.project(for: task), let section = viewModel.section(for: task) {
                    Text(String(format: NSLocalizedString("task_subtitle_format", comment: "Project • Section"), project.name, section.name))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Labels
                let labels = viewModel.labels(for: task)
                if !labels.isEmpty {
                    HStack {
                        ForEach(labels) { label in
                            LabelPill(label: label)
                        }
                    }
                    .padding(.top, 2)
                }

                // Subtasks Disclosure Group
                if !task.subtasks.isEmpty {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(task.subtasks) { subtask in
                                SubtaskRowView(subtask: subtask, task: task)
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        Text("\(task.subtasks.count) subtasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .accentColor(.secondary)
                }
            }

            Spacer()

            // Priority & Due Date
            VStack(alignment: .trailing, spacing: 4) {
                // Priority (e.g., P1, P2)
                Text(String(format: NSLocalizedString("priority_format", comment: "Priority format string"), task.priority))
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(4)

                // Due Date
                Text(task.dueDate, style: .date)
                    .font(.caption)
                    .foregroundColor(isOverdue(task.dueDate) ? .red : .secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func isOverdue(_ date: Date) -> Bool {
        return Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
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