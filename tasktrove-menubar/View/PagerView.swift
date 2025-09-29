import SwiftUI

struct PagerView: View {
    @EnvironmentObject var viewModel: TaskListViewModel

    var body: some View {
        HStack {
            Button(action: {
                viewModel.previousPage()
            }) {
                Image(systemName: "arrow.left")
            }
            .disabled(viewModel.currentPage == 0)

            Spacer()

            Text("Page \(viewModel.currentPage + 1) of \(viewModel.totalPages)")
                .font(.caption)

            Spacer()

            Button(action: {
                viewModel.nextPage()
            }) {
                Image(systemName: "arrow.right")
            }
            .disabled(viewModel.currentPage >= viewModel.totalPages - 1)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct PagerView_Previews: PreviewProvider {
    static var previews: some View {
        // To preview this, we need a view model with some data
        let viewModel = TaskListViewModel(networkService: MockNetworkService())
        viewModel.fetchData() // This is async, so preview might be empty initially

        return PagerView()
            .environmentObject(viewModel)
            .padding()
    }
}