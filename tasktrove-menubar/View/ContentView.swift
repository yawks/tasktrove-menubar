import SwiftUI
import Combine
// Import ViewModel for TaskListViewModel, SortOption, FilterCategory

struct ContentView: View {
    @EnvironmentObject var viewModel: TaskListViewModel
    @State private var showingSettings = false
    @State private var showingSortPicker = false
    @State private var isCreatingTask = false
    @State private var showingProjectFilterPicker = false
    @State private var showingLabelFilterPicker = false

    var body: some View {
        // Settings displayed inline (not as a sheet) so the MenuBarExtra window never loses focus.
        if showingSettings || viewModel.showSettingsOnAuthError {
            let onClose: () -> Void = {
                showingSettings = false
                viewModel.showSettingsOnAuthError = false
            }
            if let config = viewModel.lastAuthConfig, viewModel.showSettingsOnAuthError {
                SettingsView(prefillConfig: config, onClose: onClose)
            } else {
                SettingsView(onClose: onClose)
            }
        } else {

        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Header with Title and action buttons
                HStack {
                    Text("Tasks")
                        .font(.title2.bold())

                    Button("New") {
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
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
                            createdAt: formatter.string(from: Date()),
                            completedAt: nil,
                            recurring: nil,
                            recurringMode: "dueDate",
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
                        TaskListView(isFiltersExpanded: viewModel.isFiltersExpanded)

                        Spacer(minLength: 0)

                        if viewModel.totalPages > 1 {
                            Divider()
                            PagerView()
                        }

                        // Always-visible footer bar
                        Divider()
                        HStack {
                            Button(action: { viewModel.isFiltersExpanded.toggle() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "line.3.horizontal.decrease")
                                    Text("Filters")
                                }
                            }
                            .buttonStyle(.link)
                            Spacer()
                            if !viewModel.selectedProjects.isEmpty || !viewModel.selectedLabels.isEmpty
                                || viewModel.filterCategory != .all {
                                Button(action: {
                                    viewModel.selectedProjectIDs.removeAll()
                                    viewModel.selectedLabelIDs.removeAll()
                                    viewModel.filterCategory = .all
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Clear all filters")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .frame(height: 40)
                        .background(Color(.windowBackgroundColor))
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .blur(radius: viewModel.errorMessage != nil ? 3 : 0)

            // Filter drawer — in the outer ZStack so it anchors to the window bottom,
            // not to the inner VStack whose bounds may clip the overlay.
            if viewModel.selectedTask == nil && viewModel.isFiltersExpanded {
                VStack(spacing: 0) {
                    HStack {
                        Text("Filters").font(.headline)
                        Spacer()
                        Button(action: { viewModel.isFiltersExpanded = false }) {
                            Image(systemName: "chevron.down")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)

                    Divider()

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
                    .padding(.vertical, 10)

                    Divider()

                    HStack(spacing: 10) {
                        Button(action: { showingProjectFilterPicker = true }) {
                            HStack {
                                if !viewModel.selectedProjects.isEmpty {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(Color(hex: viewModel.selectedProjects.first?.color ?? "") ?? .accentColor)
                                } else {
                                    Image(systemName: "folder")
                                        .foregroundColor(.secondary)
                                }
                                Text(viewModel.selectedProjects.isEmpty
                                     ? "Projects"
                                     : viewModel.selectedProjects.map(\.name).joined(separator: ", "))
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .disabled(viewModel.filterCategory == .inbox)
                        .popover(isPresented: $showingProjectFilterPicker) {
                            VStack(alignment: .leading, spacing: 8) {
                                if !viewModel.selectedProjectIDs.isEmpty {
                                    Button(action: {
                                        viewModel.selectedProjectIDs.removeAll()
                                        showingProjectFilterPicker = false
                                    }) {
                                        HStack {
                                            Image(systemName: "xmark.circle")
                                            Text("Clear selection")
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    Divider()
                                }
                                ForEach(viewModel.allProjects) { project in
                                    Button(action: {
                                        if viewModel.selectedProjectIDs.contains(project.id) {
                                            viewModel.selectedProjectIDs.remove(project.id)
                                        } else {
                                            viewModel.selectedProjectIDs.insert(project.id)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "folder.fill")
                                                .foregroundColor(Color(hex: project.color) ?? .secondary)
                                            Text(project.name)
                                            Spacer()
                                            if viewModel.selectedProjectIDs.contains(project.id) {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.accentColor)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                            .frame(width: 220)
                        }

                        Button(action: { showingLabelFilterPicker = true }) {
                            HStack {
                                if !viewModel.selectedLabels.isEmpty {
                                    Image(systemName: "tag.fill")
                                        .foregroundColor(Color(hex: viewModel.selectedLabels.first?.color ?? "") ?? .accentColor)
                                } else {
                                    Image(systemName: "tag")
                                        .foregroundColor(.secondary)
                                }
                                Text(viewModel.selectedLabels.isEmpty
                                     ? "Labels"
                                     : viewModel.selectedLabels.map(\.name).joined(separator: ", "))
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .disabled(viewModel.filterCategory == .completed)
                        .popover(isPresented: $showingLabelFilterPicker) {
                            VStack(alignment: .leading, spacing: 8) {
                                if !viewModel.selectedLabelIDs.isEmpty {
                                    Button(action: {
                                        viewModel.selectedLabelIDs.removeAll()
                                        showingLabelFilterPicker = false
                                    }) {
                                        HStack {
                                            Image(systemName: "xmark.circle")
                                            Text("Clear selection")
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    Divider()
                                }
                                ForEach(viewModel.allLabels) { label in
                                    Button(action: {
                                        if viewModel.selectedLabelIDs.contains(label.id) {
                                            viewModel.selectedLabelIDs.remove(label.id)
                                        } else {
                                            viewModel.selectedLabelIDs.insert(label.id)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "tag.fill")
                                                .foregroundColor(Color(hex: label.color) ?? .secondary)
                                            Text(label.name)
                                            Spacer()
                                            if viewModel.selectedLabelIDs.contains(label.id) {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.accentColor)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                            .frame(width: 220)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 8, y: -2)
                .padding(.horizontal, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Error Banner Overlay
            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage) {
                    viewModel.errorMessage = nil
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
        .animation(.spring(duration: 0.3), value: viewModel.isFiltersExpanded)
        .frame(minWidth: 450, maxWidth: 450, minHeight: 400, maxHeight: 1000)
        .onReceive(Timer.publish(every: 300, on: .main, in: .common).autoconnect()) { _ in
            if viewModel.errorMessage == nil && !viewModel.isLoading && !viewModel.showSettingsOnAuthError {
                viewModel.fetchData()
            }
        }

        } // end else (settings not shown)
    } // end body
} // end ContentView

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
