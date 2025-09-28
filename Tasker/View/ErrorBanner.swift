import SwiftUI

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)

            Text(message)
                .lineLimit(2)
                .foregroundColor(.white)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(Color.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.red.opacity(0.95))
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

struct ErrorBanner_Previews: PreviewProvider {
    static var previews: some View {
        ErrorBanner(message: "This is a long error message that should wrap to two lines correctly.") {
            print("Dismissed")
        }
        .padding()
    }
}