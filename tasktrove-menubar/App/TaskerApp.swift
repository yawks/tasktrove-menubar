import SwiftUI

@main
struct TaskerApp: App {
    // Observe the shared configuration service
    @StateObject private var configService = ConfigurationService.shared

    // The TaskListViewModel is now created dynamically when configuration is available.
    @State private var taskListViewModel: TaskListViewModel?

    var body: some Scene {
        MenuBarExtra {
            // Using a Group to attach the onAppear modifier to the view's content
            Group {
                // Conditionally show SettingsView or ContentView
                if configService.isConfigured, let viewModel = taskListViewModel {
                    ContentView()
                        .environmentObject(viewModel)
                } else {
                    SettingsView()
                }
            }
            .onAppear {
                // Initial setup when the app starts.
                setupServices()
            }
        } label: {
            // The icon shown in the menu bar.
            Image(systemName: "checklist")
        }
        .menuBarExtraStyle(.window)
        .onChange(of: configService.isConfigured) { _ in
            // React to configuration changes.
            setupServices()
        }
    }

    /// Sets up the necessary services based on the current configuration.
    /// If configuration is invalid, it will be cleared.
    private func setupServices() {
        if configService.isConfigured {
            guard let config = configService.configuration, let password = configService.getPassword() else {
                return
            }

            do {
                let networkService = try NetworkService(configuration: config, password: password)
                self.taskListViewModel = TaskListViewModel(networkService: networkService)
            } catch {
                // If creating the service fails (e.g., invalid URL), clear the bad config.
                print("Failed to create network service with saved config: \(error.localizedDescription). Clearing configuration.")
                try? configService.clearConfiguration()
                self.taskListViewModel = nil
            }

        } else {
            // If configuration is cleared, destroy the view model.
            self.taskListViewModel = nil
        }
    }
}