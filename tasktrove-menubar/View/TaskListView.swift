import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var viewModel: TaskListViewModel

    var body: some View {
        List(viewModel.paginatedTasks) { task in
            TaskRowView(task: task)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
        }
        .listStyle(.plain) // Use a plain style for a more compact look
    }
}

// A preview provider to help develop the UI in isolation.
struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TaskListViewModel(networkService: MockNetworkService())
        // Manually trigger fetch for the preview
        viewModel.fetchData()

        return TaskListView()
            .environmentObject(viewModel)
            .frame(width: 400, height: 500)
    }
}