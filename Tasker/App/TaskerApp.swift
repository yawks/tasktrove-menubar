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
                if configService.isConfigured {
                    guard let config = configService.configuration, let password = configService.getPassword() else {
                        return
                    }
                    let networkService = NetworkService(configuration: config, password: password)
                    self.taskListViewModel = TaskListViewModel(networkService: networkService)
                }
            }
        } label: {
            // The icon shown in the menu bar.
            Image(systemName: "checklist")
        }
        .menuBarExtraStyle(.window)
        .onChange(of: configService.isConfigured) { isConfigured in
            // React to configuration changes.
            if isConfigured {
                // If configuration becomes available, create the network service and view model.
                guard let config = configService.configuration, let password = configService.getPassword() else {
                    return
                }
                let networkService = NetworkService(configuration: config, password: password)
                self.taskListViewModel = TaskListViewModel(networkService: networkService)
            } else {
                // If configuration is cleared, destroy the view model.
                self.taskListViewModel = nil
            }
        }
    }
}