import SwiftUI
import Combine
// Import ViewModel for TaskListViewModel, SortOption, FilterCategory

struct ContentView: View {
    @EnvironmentObject var viewModel: TaskListViewModel
    @State private var showingSettings = false
    @State private var showingProjectPicker = false
    @State private var showingLabelPicker = false
    @State private var isFiltersExpanded = false
    @State private var showingSortPicker = false
    @State private var isCreatingTask = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Header with Title and action buttons
                HStack {
                    Text("Tasks")
                        .font(.title2.bold())

                    Button("New") {
                        let newTask = TodoTask(
                            id: UUID().uuidString,
                            title: "",
                            description: nil,
                            completed: false,
                            priority: 4,
                            dueDate: nil,
                            dueTime: nil,
                            projectId: nil,
                            sectionId: nil,
                            labels: [],
                            subtasks: [],
                            comments: [],
                            attachments: [],
                            createdAt: ISO8601DateFormatter().string(from: Date()),
                            completedAt: nil,
                            recurring: nil,
                            recurringMode: nil,
                            estimation: nil
                        )
                        viewModel.selectedTask = newTask
                        isCreatingTask = true
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    // Sort Button
                    Button(action: { showingSortPicker = true }) {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .buttonStyle(.plain)
                    .help("Change sort order")
                    .popover(isPresented: $showingSortPicker) {
                        VStack(alignment: .leading) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: {
                                    viewModel.sortOption = option
                                    showingSortPicker = false
                                }) {
                                    HStack {
                                        switch option {
                                        case .defaultOrder:
                                            Image(systemName: "list.bullet")
                                        case .dueDate:
                                            Image(systemName: "calendar")
                                        case .priority:
                                            Image(systemName: "flag")
                                        }
                                        Text(option.rawValue)
                                        Spacer()
                                        if viewModel.sortOption == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }

                    // Refresh Button
                    Button(action: { viewModel.fetchData() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                    .help("Refresh tasks")
                    .disabled(viewModel.isLoading)

                                        // Settings Button
                    Button(action: { showingSettings.toggle() }) {
                        Image(systemName: "gear")
                    }
                    .buttonStyle(.plain)
                    .help("Settings")

                    // Quit Button
                    Button(action: { NSApplication.shared.terminate(nil) }) {
                        Image(systemName: "power")
                    }
                    .buttonStyle(.plain)
                    .help("Quit application")
                }
                .padding()
                .frame(height: 80)
                .overlay(
                    viewModel.isLoading ? ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.black.opacity(0.1)) : nil
                )

                Divider()

                if let task = viewModel.selectedTask {
                    TaskDetailView(
                        task: task,
                        isCreating: isCreatingTask,
                        onDismiss: {
                            viewModel.selectedTask = nil
                            isCreatingTask = false
                        }
                    )
                } else {
                    VStack(spacing: 0) {
                        // The list of tasks
                        TaskListView(isFiltersExpanded: isFiltersExpanded)

                        // --- Bottom Controls ---
                        VStack {
                            // Pager control - Should always be visible, but part of the animated block
                            if viewModel.totalPages > 1 {
                                Divider()
                                PagerView()
                            }

                            if isFiltersExpanded {
                            // Expanded Filter Panel
                            VStack {
                                // Header with collapse button
                                HStack {
                                    Text("Filters")
                                        .font(.headline)
                                    Spacer()
                                    Button(action: { isFiltersExpanded = false }) {
                                        Image(systemName: "chevron.down")
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal)
                                .padding(.top, 8)

                                // Quick Filter Buttons
                                VStack(spacing: 8) {
                                    HStack(spacing: 10) {
                                        FilterButton(title: "Inbox", icon: "tray", category: .inbox, viewModel: viewModel)
                                        FilterButton(title: "Today", icon: "calendar", category: .today, viewModel: viewModel)
                                    }
                                    HStack(spacing: 10) {
                                        FilterButton(title: "Upcoming", icon: "clock", category: .upcoming, viewModel: viewModel)
                                        FilterButton(title: "Completed", icon: "checkmark.circle", category: .completed, viewModel: viewModel)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 8)


                                // Project and Label Pickers
                                VStack(spacing: 8) {
                                    // Project Picker Button
                                    Button(action: { showingProjectPicker = true }) {
                                        HStack {
                                            if viewModel.selectedProjects.isEmpty {
                                                Text("Projects")
                                                Spacer()
                                            } else {
                                                ScrollView(.horizontal, showsIndicators: false) {
                                                    HStack {
                                                        ForEach(viewModel.selectedProjects) { project in
                                                            ItemPillView(item: project, iconName: "folder.fill")
                                                        }
                                                    }
                                                }
                                            }
                                            Image(systemName: "chevron.right")
                                        }
                                        .padding(8)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                    .popover(isPresented: $showingProjectPicker) {
                                        MultiSelectPickerView(
                                            title: "Filter by Project",
                                            items: viewModel.allProjects,
                                            iconName: "folder.fill",
                                            selections: $viewModel.selectedProjectIDs
                                        )
                                    }
                                    .disabled(viewModel.filterCategory == .inbox)


                                    // Label Picker Button
                                    Button(action: { showingLabelPicker = true }) {
                                        HStack {
                                            if viewModel.selectedLabels.isEmpty {
                                                Text("Labels")
                                                Spacer()
                                            } else {
                                                ScrollView(.horizontal, showsIndicators: false) {
                                                    HStack {
                                                        ForEach(viewModel.selectedLabels) { label in
                                                            ItemPillView(item: label, iconName: "tag.fill")
                                                        }
                                                    }
                                                }
                                            }
                                            Image(systemName: "chevron.right")
                                        }
                                        .padding(8)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                    .popover(isPresented: $showingLabelPicker) {
                                        MultiSelectPickerView(
                                            title: "Filter by Label",
                                            items: viewModel.allLabels,
                                            iconName: "tag.fill",
                                            selections: $viewModel.selectedLabelIDs
                                        )
                                    }
                                    .disabled(viewModel.filterCategory == .completed)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                            .background(Color(.windowBackgroundColor).opacity(0.8))
                            .transition(.move(edge: .bottom))
                        } else {
                            // Collapsed Filter Button
                            Divider()
                            HStack {
                                Button("Filters") {
                                    isFiltersExpanded = true
                                }
                                .buttonStyle(.link)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.windowBackgroundColor).opacity(0.8))
                        }
                    }
                    .animation(.spring(), value: isFiltersExpanded)
                    }
                }
            }
            .blur(radius: viewModel.errorMessage != nil ? 3 : 0)
            .sheet(isPresented: Binding(
                get: {
                    showingSettings || viewModel.showSettingsOnAuthError
                },
                set: { newValue in
                    // Ne jamais fermer automatiquement sur perte de focus
                    showingSettings = newValue
                }
            )) {
                let onClose: () -> Void = {
                    showingSettings = false
                    viewModel.showSettingsOnAuthError = false
                }
                if let config = viewModel.lastAuthConfig, viewModel.showSettingsOnAuthError {
                    SettingsView(prefillConfig: config, onClose: onClose)
                } else {
                    SettingsView(onClose: onClose)
                }
            }
            .interactiveDismissDisabled(true)

            // Error Banner Overlay
            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage) {
                    viewModel.errorMessage = nil // Dismiss the banner
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Detail View Loader
            if viewModel.isLoadingDetail {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
        .animation(.spring(), value: viewModel.errorMessage)
    .frame(minWidth: 450, maxWidth: 450, minHeight: 400, maxHeight: 1000)
        .onReceive(Timer.publish(every: 300, on: .main, in: .common).autoconnect()) { _ in
            // Ne rafraîchit pas si le formulaire de connexion est affiché suite à une erreur d'authentification
            if viewModel.errorMessage == nil && !viewModel.isLoading && !viewModel.showSettingsOnAuthError {
                viewModel.fetchData()
            }
        }
    }
}

// A helper view for the filter buttons at the bottom.
struct FilterButton: View {
    let title: String
    let icon: String
    let category: FilterCategory
    @ObservedObject var viewModel: TaskListViewModel

    private var isSelected: Bool {
        viewModel.filterCategory == category
    }

    var body: some View {
        Button(action: {
            if isSelected {
                viewModel.filterCategory = .all // Toggle off to default
            } else {
                viewModel.filterCategory = category
            }
        }) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .contentShape(Rectangle()) // Makes the whole area clickable
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
