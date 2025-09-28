import SwiftUI

@main
struct TaskerApp: App {
    // The ViewModel is instantiated here as a StateObject, making it the source
    // of truth for the entire application lifecycle.
    @StateObject private var viewModel = TaskListViewModel(networkService: MockNetworkService())

    var body: some Scene {
        MenuBarExtra {
            // This is the content of the popover.
            ContentView()
                .environmentObject(viewModel)
        } label: {
            // This is the icon shown in the menu bar.
            // Using a system image is a good starting point.
            Image(systemName: "checklist")
        }
        .menuBarExtraStyle(.window) // Use .window to get a fully interactive popover
    }
}