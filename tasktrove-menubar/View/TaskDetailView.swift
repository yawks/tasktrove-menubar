import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject var viewModel: TaskListViewModel
    @State private var task: TodoTask // Work on a local copy

    var onDismiss: () -> Void // Callback to dismiss the view

    // State for popovers
    @State private var showingProjectPicker = false
    @State private var showingLabelPicker = false
    @State private var showingDatePicker = false
    @State private var showingPriorityPicker = false

    init(task: TodoTask, onDismiss: @escaping () -> Void) {
        _task = State(initialValue: task)
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with Back button and Title
            HStack {
                Button(action: {
                    viewModel.updateTask(self.task) // Save the local copy
                    self.onDismiss() // Use the callback to dismiss
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
                            if self.task.labels.isEmpty {
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
                                get: { Set(self.task.labels) },
                                set: { self.task.labels = Array($0) }
                            )
                        )
                    }

                    // Due Date Picker
                    Text("Due Date").font(.caption).foregroundColor(.secondary)
                    Button(action: { showingDatePicker = true }) {
                        HStack {
                            Text(self.task.dueDate != nil ? self.task.dueDate!.formatted(date: .long, time: .omitted) : "No due date")
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
                                    self.task.dueDate = Date()
                                    showingDatePicker = false
                                }) {
                                    HStack {
                                        Image(systemName: "sun.max.fill").foregroundColor(.yellow)
                                        Text("Today")
                                    }
                                }

                                Button(action: {
                                    self.task.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                                    showingDatePicker = false
                                }) {
                                    HStack {
                                        Image(systemName: "sunrise.fill").foregroundColor(.orange)
                                        Text("Tomorrow")
                                    }
                                }

                                Button(action: {
                                    self.task.dueDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
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
                                    get: { self.task.dueDate ?? Date() },
                                    set: { self.task.dueDate = $0 }
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
                    if !task.subtasks.isEmpty {
                        Text("Subtasks").font(.caption).foregroundColor(.secondary)
                        ForEach($task.subtasks) { $subtask in
                            Button(action: {
                                $subtask.completed.wrappedValue.toggle()
                            }) {
                                HStack {
                                    Image(systemName: $subtask.completed.wrappedValue ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor($subtask.completed.wrappedValue ? .green : .secondary)
                                    Text($subtask.title.wrappedValue)
                                        .strikethrough($subtask.completed.wrappedValue, color: .secondary)
                                        .foregroundColor($subtask.completed.wrappedValue ? .secondary : .primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
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
}