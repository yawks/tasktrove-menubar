import Foundation
import Combine

/// Represents the configuration needed to connect to the API.
struct APIConfiguration: Equatable {
    var endpoint: String
    var apiKey: String
}

/// A service to manage loading and saving the API configuration.
/// It uses UserDefaults for non-sensitive data.
class ConfigurationService: ObservableObject {

    static let shared = ConfigurationService()

    @Published var configuration: APIConfiguration?
    @Published var isConfigured: Bool = false

    private let userDefaults = UserDefaults.standard
    // KeychainHelper is no longer used.

    private let endpointKey = "api_endpoint"
    private let apiKeyKey = "api_key"

    private var cancellables = Set<AnyCancellable>()

    private init() {
        load()

        // Automatically update the `isConfigured` flag when the configuration changes.
        $configuration
            .map { $0 != nil }
            .assign(to: \.isConfigured, on: self)
            .store(in: &cancellables)
    }

    /// Loads the configuration from UserDefaults and Keychain.
    func load() {
        let endpoint = userDefaults.string(forKey: endpointKey) ?? ""
        let apiKey = userDefaults.string(forKey: apiKeyKey) ?? ""

        // Only create a configuration object if the essential parts exist.
        if !endpoint.isEmpty && !apiKey.isEmpty {
            self.configuration = APIConfiguration(endpoint: endpoint, apiKey: apiKey)
        } else {
            self.configuration = nil
        }
    }

    /// Saves the configuration and password.
    /// - Parameters:
    ///   - configuration: The API configuration to save.
    ///   - password: The password to save securely in the Keychain.
    func save(configuration: APIConfiguration) throws {
        userDefaults.set(configuration.endpoint, forKey: endpointKey)
        userDefaults.set(configuration.apiKey, forKey: apiKeyKey)
        self.configuration = configuration
    }



    /// Deletes all saved configuration data.
    func clearConfiguration() throws {
        userDefaults.removeObject(forKey: endpointKey)
        userDefaults.removeObject(forKey: apiKeyKey)
        self.configuration = nil
    }
}