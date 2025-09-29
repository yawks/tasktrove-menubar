import Foundation
import Combine

/// Represents the configuration needed to connect to the API.
struct APIConfiguration: Equatable {
    var endpoint: String
    var login: String
    // The password is not part of the main struct for security reasons,
    // as it's handled directly by the Keychain.
}

/// A service to manage loading and saving the API configuration.
/// It uses UserDefaults for non-sensitive data and Keychain for the password.
class ConfigurationService: ObservableObject {

    static let shared = ConfigurationService()

    @Published var configuration: APIConfiguration?
    @Published var isConfigured: Bool = false

    private let userDefaults = UserDefaults.standard
    private let keychain = KeychainHelper.standard

    private let endpointKey = "api_endpoint"
    private let loginKey = "api_login"
    private let passwordAccountKey = "api_password"

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
        let login = userDefaults.string(forKey: loginKey) ?? ""

        // Only create a configuration object if the essential parts exist.
        if !endpoint.isEmpty && !login.isEmpty {
            self.configuration = APIConfiguration(endpoint: endpoint, login: login)
        } else {
            self.configuration = nil
        }
    }

    /// Saves the configuration and password.
    /// - Parameters:
    ///   - configuration: The API configuration to save.
    ///   - password: The password to save securely in the Keychain.
    func save(configuration: APIConfiguration, password: String) throws {
        userDefaults.set(configuration.endpoint, forKey: endpointKey)
        userDefaults.set(configuration.login, forKey: loginKey)

        // Only save the password if it's not empty.
        if !password.isEmpty {
            try keychain.save(password, for: passwordAccountKey)
        }

        // Update the published property to reflect the change immediately.
        self.configuration = configuration
    }

    /// Retrieves the password from the Keychain.
    func getPassword() -> String? {
        return try? keychain.load(for: passwordAccountKey)
    }

    /// Deletes all saved configuration data.
    func clearConfiguration() throws {
        userDefaults.removeObject(forKey: endpointKey)
        userDefaults.removeObject(forKey: loginKey)
        try keychain.delete(for: passwordAccountKey)
        self.configuration = nil
    }
}