import SwiftUI

// 1. Protocol for items that can be displayed in the picker
protocol SelectableItem: Identifiable, Hashable {
    var id: UUID { get }
    var name: String { get }
    var color: String { get }
}

// 2. Make existing models conform to the protocol
// Conformance is now handled in the model files directly.


// Custom ToggleStyle for checkmark lists
struct CheckmarkToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack {
                configuration.label
                Spacer()
                if configuration.isOn {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// 3. The custom multi-select picker view
struct MultiSelectPickerView<Item: SelectableItem & Hashable>: View {
    let title: String
    let items: [Item]
    let iconName: String
    @Binding var selections: Set<UUID>
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
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
                let isSelectedBinding = Binding<Bool>(
                    get: { self.selections.contains(item.id) },
                    set: { isSelected in
                        if isSelected {
                            self.selections.insert(item.id)
                        } else {
                            self.selections.remove(item.id)
                        }
                    }
                )

                Toggle(isOn: isSelectedBinding) {
                    HStack {
                        Image(systemName: iconName)
                            .foregroundColor(Color(hex: item.color) ?? .secondary)
                        Text(item.name)
                    }
                }
                .toggleStyle(CheckmarkToggleStyle())
            }
            .listStyle(.plain)
        }
        .frame(width: 300, height: 400)
    }
}