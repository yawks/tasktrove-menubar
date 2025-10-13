import SwiftUI

struct SubtaskRowView: View {
    // Using a Binding allows the view to modify the subtask directly.
    // This is suitable for simple cases, but the change must be propagated
    // up to the ViewModel to trigger a network request.
    let subtask: TodoSubtask
    let task: TodoTask // The parent task is needed to trigger the update

    // We get the view model from the environment
    @EnvironmentObject var viewModel: TaskListViewModel

    var body: some View {
        HStack(spacing: 12) {
            let isCompleted = subtask.completed ?? false
            Image(systemName: isCompleted ? "checkmark.square.fill" : "square")
                .foregroundColor(isCompleted ? .green : .secondary)
                .onTapGesture {
                    viewModel.toggleSubtaskCompletion(for: subtask, in: task)
                }

            Text(subtask.title)
                .strikethrough(isCompleted, color: .secondary)
                .foregroundColor(isCompleted ? .secondary : .primary)

            Spacer()
        }
        .padding(.leading, 20) // Indent subtasks for clarity
    }
}