import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var selectedProvider: TaskProvider = .taskTrove
    @Published var endpoint = ""
    @Published var apiKey = ""
    @Published var isLoading = false
    @Published var feedbackMessage: (text: String, isError: Bool)?

    // MARK: - Private Properties
    private let configService: ConfigurationService

    // MARK: - Initializers
    init(configService: ConfigurationService) {
        self.configService = configService
        loadInitialValues()
    }

    convenience init() {
        self.init(configService: .shared)
    }

    func prefill(endpoint: String, apiKey: String) {
        self.endpoint = endpoint
        self.apiKey = apiKey
    }

    func loadInitialValues() {
        if let config = configService.configuration {
            self.selectedProvider = config.provider
            self.endpoint = config.endpoint
            self.apiKey = config.apiKey
        }
    }

    func testAndSaveConfiguration(completion: @escaping (Bool) -> Void) {
        isLoading = true
        feedbackMessage = nil

        Task {
            let newConfig = APIConfiguration(provider: selectedProvider, endpoint: endpoint, apiKey: apiKey)
            do {
                let service = try NetworkServiceFactory.make(configuration: newConfig)
                _ = try await service.fetchTasks()
                try configService.save(configuration: newConfig)
                feedbackMessage = ("Configuration saved successfully!", false)
                completion(true)
            } catch {
                print("error", error)
                feedbackMessage = ("Connection failed: \(error.localizedDescription)", true)
                completion(false)
            }
            isLoading = false
        }
    }

    func clearConfiguration() {
        do {
            try configService.clearConfiguration()
            self.endpoint = ""
            self.apiKey = ""
            self.selectedProvider = .taskTrove
            feedbackMessage = ("Configuration cleared.", false)
        } catch {
            feedbackMessage = ("Failed to clear configuration: \(error.localizedDescription)", true)
        }
    }
}
