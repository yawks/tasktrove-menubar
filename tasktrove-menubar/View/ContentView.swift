import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var viewModel: TaskListViewModel
    @State private var showingSettings = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Header with Title and action buttons
                HStack {
                    Text("Tasks")
                        .font(.title2.bold())
                    Spacer()

                    // Sort Menu
                    Picker(selection: $viewModel.sortOption,
                           label: Image(systemName: "arrow.up.arrow.down")
                            .help("sort_by_tooltip")
                    ) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)

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

                // Pager control
                if viewModel.totalPages > 1 {
                    Divider()
                    PagerView()
                }

                // --- Bottom Controls ---
                VStack {
                    Divider()

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
                        Picker("Project", selection: $viewModel.selectedProjectID) {
                            Text("All Projects").tag(nil as UUID?)
                            ForEach(viewModel.allProjects) { project in
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(Color(hex: project.color) ?? .gray)
                                    Text(project.name)
                                }.tag(project.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                        .disabled(viewModel.filterCategory == .inbox)


                        Menu {
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
                                            .foregroundColor(Color(hex: label.color) ?? .gray)
                                        Text(label.name)
                                        if viewModel.selectedLabelIDs.contains(label.id) {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("Labels")
                                if !viewModel.selectedLabelIDs.isEmpty {
                                    Circle().frame(width: 8, height: 8).foregroundColor(.blue)
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(viewModel.filterCategory == .completed)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.windowBackgroundColor).opacity(0.8))
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