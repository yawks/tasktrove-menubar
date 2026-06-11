import SwiftUI

struct SettingsView: View {
    var prefillConfig: (endpoint: String, apiKey: String)? = nil
    var onClose: (() -> Void)? = nil
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        VStack(spacing: 20) {
            if let config = prefillConfig {
                Color.clear.onAppear {
                    if viewModel.endpoint != config.endpoint || viewModel.apiKey != config.apiKey {
                        viewModel.prefill(endpoint: config.endpoint, apiKey: config.apiKey)
                    }
                }
            }

            Text("Configuration")
                .font(.title)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Provider")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ProviderSegmentedPicker(selection: $viewModel.selectedProvider)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Endpoint URL")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField(viewModel.selectedProvider.endpointPlaceholder, text: $viewModel.endpoint)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    if viewModel.selectedProvider == .vikunja {
                        Text("Include /api/v1 — e.g. https://vikunja.example.com/api/v1")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.selectedProvider.tokenLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Token", text: $viewModel.apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
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
                    viewModel.testAndSaveConfiguration { success in
                        if success { onClose?() }
                    }
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

/// Pure-SwiftUI segmented control for provider selection.
/// Avoids NSSegmentedControl (`.segmented` Picker style) which steals focus
/// from the MenuBarExtra window and causes it to close on click.
private struct ProviderSegmentedPicker: View {
    @Binding var selection: TaskProvider

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(TaskProvider.allCases.enumerated()), id: \.element.id) { index, provider in
                Button(action: { selection = provider }) {
                    Text(provider.displayName)
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(selection == provider
                            ? Color.accentColor
                            : Color(.controlBackgroundColor))
                        .foregroundColor(selection == provider ? .white : .primary)
                }
                .buttonStyle(.plain)
                if index < TaskProvider.allCases.count - 1 {
                    Divider()
                }
            }
        }
        .frame(height: 28)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(.separatorColor), lineWidth: 1))
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
