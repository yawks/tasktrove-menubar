import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var endpoint = ""
    @Published var login = ""
    @Published var password = ""

    @Published var isLoading = false
    @Published var feedbackMessage: (text: String, isError: Bool)?

    // MARK: - Private Properties
    private let configService: ConfigurationService

    // MARK: - Initializer
    init(configService: ConfigurationService = .shared) {
        self.configService = configService
        loadInitialValues()
    }

    /// Loads existing configuration to pre-fill the fields.
    func loadInitialValues() {
        if let config = configService.configuration {
            self.endpoint = config.endpoint
            self.login = config.login
        }
        // Password is not pre-filled for security.
    }

    /// Attempts to connect with the provided credentials, and saves them if successful.
    func testAndSaveConfiguration() {
        isLoading = true
        feedbackMessage = nil

        Task {
            let newConfig = APIConfiguration(endpoint: endpoint, login: login)

            do {
                // Create a temporary network service. This can throw if the URL is invalid.
                let testNetworkService = try NetworkService(configuration: newConfig, password: password)

                // Try to fetch tasks to validate the configuration.
                _ = try await testNetworkService.fetchTasks()

                // If successful, save the configuration.
                try configService.save(configuration: newConfig, password: password)

                feedbackMessage = ("Configuration saved successfully!", false)

            } catch {
                // This will now catch both invalid URL errors and other connection errors.
                feedbackMessage = ("Connection failed: \(error.localizedDescription)", true)
            }

            isLoading = false
        }
    }

    /// Clears the current configuration.
    func clearConfiguration() {
        do {
            try configService.clearConfiguration()
            self.endpoint = ""
            self.login = ""
            self.password = ""
            feedbackMessage = ("Configuration cleared.", false)
        } catch {
            feedbackMessage = ("Failed to clear configuration: \(error.localizedDescription)", true)
        }
    }
}