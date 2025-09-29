import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var viewModel: TaskListViewModel
    @State private var showingSettings = false
    @State private var showingProjectPicker = false
    @State private var showingLabelPicker = false
    @State private var isFiltersExpanded = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Header with Title and action buttons
                HStack {
                    Text("Tasks")
                        .font(.title2.bold())
                    Spacer()

                    // Sort Menu
                    Menu {
                        Picker("Sort by", selection: $viewModel.sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.inline)
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .help("sort_by_tooltip")
                    }
                    .menuStyle(.borderlessButton)

                    // Refresh Button
                    Button(action: { viewModel.fetchData() }) {
                        Image(systemName: "arrow.clockwise")
                            .help("refresh_button_tooltip")
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isLoading)

                    // Settings Button
                    Button(action: { showingSettings.toggle() }) {
                        Image(systemName: "gear")
                            .help("settings_button_tooltip")
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .overlay(
                    viewModel.isLoading ? ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.black.opacity(0.1)) : nil
                )

                Divider()

                // The list of tasks
                TaskListView()

                // Pager control - Should always be visible
                if viewModel.totalPages > 1 {
                    Divider()
                    PagerView()
                }

                // --- Bottom Controls ---
                VStack {
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
            .blur(radius: viewModel.errorMessage != nil ? 3 : 0)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }

            // Error Banner Overlay
            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage) {
                    viewModel.errorMessage = nil // Dismiss the banner
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: viewModel.errorMessage)
        .frame(minWidth: 450, maxWidth: 450, minHeight: 400, maxHeight: 800)
        .onAppear {
            viewModel.filterCategory = .all // Reset to default view
            if viewModel.allTasks.isEmpty {
                viewModel.fetchData()
            }
        }
        .onReceive(Timer.publish(every: 300, on: .main, in: .common).autoconnect()) { _ in
            // Only refresh if there's no error banner shown and not currently loading
            if viewModel.errorMessage == nil && !viewModel.isLoading {
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