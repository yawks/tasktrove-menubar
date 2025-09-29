import SwiftUI

// 1. Protocol for items that can be displayed in the picker
protocol SelectableItem: Identifiable, Hashable {
    var id: UUID { get }
    var name: String { get }
    var color: String { get }
}

// 2. Make existing models conform to the protocol
extension Project: SelectableItem {}
extension Label: SelectableItem {}


// 3. The custom multi-select picker view
struct MultiSelectPickerView<Item: SelectableItem>: View {
    let title: String
    let items: [Item]
    let iconName: String
    @Binding var selections: Set<UUID>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button("Done") {
                    // This button's action is handled by the popover's dismissal
                    // but it's good practice to have a dismiss button.
                    // We can connect this to the popover's isPresented state if needed.
                }
            }
            .padding()

            Divider()

            // "Select All" / "Deselect All" button
            Button(action: {
                if selections.count == items.count {
                    selections.removeAll()
                } else {
                    selections = Set(items.map { $0.id })
                }
            }) {
                Text(selections.count == items.count ? "Deselect All" : "Select All")
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // List of selectable items
            List(items) { item in
                Button(action: {
                    if selections.contains(item.id) {
                        selections.remove(item.id)
                    } else {
                        selections.insert(item.id)
                    }
                }) {
                    HStack {
                        Image(systemName: iconName)
                            .foregroundColor(Color(hex: item.color) ?? .secondary)
                        Text(item.name)
                        Spacer()
                        if selections.contains(item.id) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
        .frame(width: 300, height: 400)
    }
}