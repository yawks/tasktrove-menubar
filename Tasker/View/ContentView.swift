import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var viewModel: TaskListViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Header with filters and refresh button
                HStack(spacing: 16) {
                    // Project Filter
                    Picker("Project", selection: $viewModel.selectedProjectID) {
                        Text("All Projects").tag(nil as UUID?)
                        ForEach(viewModel.allProjects) { project in
                            Text(project.name).tag(project.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)

                    // Label Filter
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
                                    Text(label.name)
                                    if viewModel.selectedLabelIDs.contains(label.id) {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Text("Labels")
                        if !viewModel.selectedLabelIDs.isEmpty {
                            Circle().frame(width: 8, height: 8).foregroundColor(.blue)
                        }
                    }

                    // Sort Order Picker
                    Picker("Sort by", selection: $viewModel.sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)

                    Spacer()

                    Button(action: {
                        viewModel.fetchData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .help("refresh_button_tooltip")
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isLoading) // Disable while loading
                }
                .padding()
                .background(Color(.windowBackgroundColor).opacity(0.8))
                .overlay(
                    viewModel.isLoading ? ProgressView("loading_tasks").frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.black.opacity(0.1)) : nil
                )

                Divider()

                // The list of tasks
                TaskListView()
            }
            .blur(radius: viewModel.errorMessage != nil ? 3 : 0)

            // Error Banner Overlay
            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage) {
                    viewModel.errorMessage = nil // Dismiss the banner
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: viewModel.errorMessage)
        .frame(width: 450, height: 550)
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