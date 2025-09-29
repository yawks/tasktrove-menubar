import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("API Configuration")
                .font(.title)

            VStack(alignment: .leading, spacing: 12) {
                TextField("API Endpoint (e.g., https://api.example.com/api)", text: $viewModel.endpoint)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("Login", text: $viewModel.login)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                SecureField("Password", text: $viewModel.password)
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

                Button("Clear") {
                    viewModel.clearConfiguration()
                }
                .foregroundColor(.red)

                Button("Test & Save") {
                    viewModel.testAndSaveConfiguration()
                }
                .disabled(viewModel.isLoading)
            }
        }
        .padding(30)
        .frame(width: 450)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}