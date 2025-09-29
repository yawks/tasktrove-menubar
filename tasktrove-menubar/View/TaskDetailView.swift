import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject var viewModel: TaskListViewModel
    @Binding var task: TodoTask

    // State for popovers
    @State private var showingProjectPicker = false
    @State private var showingLabelPicker = false
    @State private var showingDatePicker = false
    @State private var showingPriorityPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with Back button and Title
            HStack {
                Button(action: {
                    viewModel.selectedTask = nil // Go back to the list
                }) {
                    Image(systemName: "chevron.left")
                    Text("Tasks")
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Edit Task")
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

                    // Project Picker
                    Text("Project").font(.caption).foregroundColor(.secondary)
                    Button(action: { showingProjectPicker = true }) {
                        HStack {
                            if let project = viewModel.project(for: task) {
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
                        // A simple picker for single project selection
                        VStack {
                            Picker("Project", selection: $task.projectId) {
                                Text("No Project").tag(nil as UUID?)
                                ForEach(viewModel.allProjects) { project in
                                    Text(project.name).tag(project.id as UUID?)
                                }
                            }
                            .pickerStyle(.inline)
                            Button("Done") { showingProjectPicker = false }.padding()
                        }.frame(width: 200)
                    }

                    // Label Picker
                    Text("Labels").font(.caption).foregroundColor(.secondary)
                    Button(action: { showingLabelPicker = true }) {
                         HStack {
                            if task.labels.isEmpty {
                                Text("No Labels")
                                Spacer()
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(viewModel.labels(for: task)) { label in
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
                                get: { Set(task.labels) },
                                set: { task.labels = Array($0) }
                            )
                        )
                    }

                    // Due Date Picker
                    Text("Due Date").font(.caption).foregroundColor(.secondary)
                    Button(action: { showingDatePicker = true }) {
                        HStack {
                            Text(task.dueDate != nil ? task.dueDate!.formatted(date: .long, time: .omitted) : "No due date")
                            Spacer()
                            if task.dueDate != nil {
                                Button(action: { task.dueDate = nil }) {
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
                                    task.dueDate = Date()
                                    showingDatePicker = false
                                }) {
                                    HStack {
                                        Image(systemName: "sun.max.fill").foregroundColor(.yellow)
                                        Text("Today")
                                    }
                                }

                                Button(action: {
                                    task.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                                    showingDatePicker = false
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.up.and.sun.max.fill").foregroundColor(.orange)
                                        Text("Tomorrow")
                                    }
                                }

                                Button(action: {
                                    task.dueDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
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
                                    get: { task.dueDate ?? Date() },
                                    set: { task.dueDate = $0 }
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
                            priorityView(for: task.priority ?? 4)
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
                                    task.priority = priority
                                    showingPriorityPicker = false
                                }) {
                                    HStack {
                                        priorityView(for: priority)
                                        Spacer()
                                        if task.priority == priority || (task.priority == nil && priority == 4) {
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
                    if !task.subtasks.isEmpty {
                        Text("Subtasks").font(.caption).foregroundColor(.secondary)
                        ForEach($task.subtasks) { $subtask in
                            Toggle(isOn: $subtask.completed) {
                                HStack {
                                    Image(systemName: subtask.completed ? "checkmark.circle.fill" : "circle")
                                    Text(subtask.title)
                                }
                            }
                            .toggleStyle(.plain)
                        }
                    }
                }
                .padding()
            }
        }
        .onDisappear {
            // When the view disappears (e.g., user clicks away), save the changes.
            viewModel.updateTask(task)
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
}