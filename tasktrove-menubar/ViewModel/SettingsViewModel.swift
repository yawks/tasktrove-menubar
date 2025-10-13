import Foundation
import Combine

@MainActor

class SettingsViewModel: ObservableObject {
    /// allow to set values without triggering unnecessary reloads
    func prefill(endpoint: String, apiKey: String) {
        self.endpoint = endpoint
        self.apiKey = apiKey
    }

    // MARK: - Published Properties
    @Published var endpoint = ""
    @Published var apiKey = ""

    @Published var isLoading = false
    @Published var feedbackMessage: (text: String, isError: Bool)?

    // MARK: - Private Properties
    private let configService: ConfigurationService

    // MARK: - Initializer
    // Designated initializer for dependency injection
    init(configService: ConfigurationService) {
        self.configService = configService
        loadInitialValues()
    }

    // Convenience initializer for SwiftUI previews and default usage
    convenience init() {
        self.init(configService: .shared)
    }

    /// Loads existing configuration to pre-fill the fields.
    func loadInitialValues() {
        if let config = configService.configuration {
            self.endpoint = config.endpoint
            self.apiKey = config.apiKey
        }
    }

    /// Attempts to connect with the provided credentials, and saves them if successful.
        func testAndSaveConfiguration(completion: @escaping (Bool) -> Void) {
        isLoading = true
        feedbackMessage = nil

        Task {
            let newConfig = APIConfiguration(endpoint: endpoint, apiKey: apiKey)

            do {
                let testNetworkService = try NetworkService(configuration: newConfig)
                _ = try await testNetworkService.fetchTasks()
                try configService.save(configuration: newConfig)
                feedbackMessage = ("Configuration saved successfully!", false)
                    completion(true)
            } catch {
                print("error", error)
                feedbackMessage = ("Connection failed: \(error)", true)
                    completion(false)
            }

            isLoading = false
        }
    }

    /// Clears the current configuration.
    func clearConfiguration() {
        do {
            try configService.clearConfiguration()
            self.endpoint = ""
            self.apiKey = ""
            feedbackMessage = ("Configuration cleared.", false)
        } catch {
            feedbackMessage = ("Failed to clear configuration: \(error.localizedDescription)", true)
        }
    }
}
