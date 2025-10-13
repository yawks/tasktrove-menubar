import SwiftUI

struct SettingsView: View {
    var prefillConfig: (endpoint: String, apiKey: String)? = nil
    var onClose: (() -> Void)? = nil
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        VStack(spacing: 20) {
            // Préremplir si besoin (reconnexion après 403)
            if let config = prefillConfig {
                Color.clear.onAppear {
                    // Only prefill if the current values differ to avoid unnecessary updates/reloading
                    if viewModel.endpoint != config.endpoint ||
                        viewModel.apiKey != config.apiKey {
                        viewModel.prefill(endpoint: config.endpoint, apiKey: config.apiKey)
                    }
                }
            }
            Text("API Configuration")
                .font(.title)

            VStack(alignment: .leading, spacing: 12) {
                TextField("API Endpoint (e.g., https://api.example.com/api)", text: $viewModel.endpoint)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("Clé API (Bearer Token)", text: $viewModel.apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            if let feedback = viewModel.feedbackMessage {
                Text(feedback.text)
                    .foregroundColor(feedback.isError ? .red : .green)
                    .font(.caption)
            }

            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }

                Spacer()
                Button("Cancel") {
                    onClose?()
                }
                .keyboardShortcut(.cancelAction)

                Button("Clear") {
                    viewModel.clearConfiguration()
                    onClose?()
                }
                .focusable()
                .accessibilityLabel("Clear configuration")
                .foregroundColor(.red)

                Button("Test & Save") {
                    viewModel.testAndSaveConfiguration { _ in }
                    onClose?()
                }
                .focusable()
                .accessibilityLabel("Test and save configuration")
                .disabled(viewModel.isLoading)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(width: 450)
        .focusSection()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
