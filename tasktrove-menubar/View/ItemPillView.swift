import SwiftUI

struct ItemPillView<Item: SelectableItem>: View {
    let item: Item
    let iconName: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .foregroundColor(Color(hex: item.color) ?? .secondary)
            Text(item.name)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.2))
        .cornerRadius(8)
    }
}