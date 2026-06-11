import Foundation
import Combine

struct APIConfiguration: Equatable {
    var provider: TaskProvider
    var endpoint: String
    var apiKey: String
}

class ConfigurationService: ObservableObject {

    static let shared = ConfigurationService()

    @Published var configuration: APIConfiguration?
    @Published var isConfigured: Bool = false

    private let userDefaults = UserDefaults.standard
    private let endpointKey = "api_endpoint"
    private let apiKeyKey = "api_key"
    private let providerKey = "api_provider"

    private var cancellables = Set<AnyCancellable>()

    private init() {
        load()

        $configuration
            .map { $0 != nil }
            .assign(to: \.isConfigured, on: self)
            .store(in: &cancellables)
    }

    func load() {
        let endpoint = userDefaults.string(forKey: endpointKey) ?? ""
        let apiKey = userDefaults.string(forKey: apiKeyKey) ?? ""
        let providerRaw = userDefaults.string(forKey: providerKey) ?? TaskProvider.taskTrove.rawValue
        let provider = TaskProvider(rawValue: providerRaw) ?? .taskTrove

        if !endpoint.isEmpty && !apiKey.isEmpty {
            self.configuration = APIConfiguration(provider: provider, endpoint: endpoint, apiKey: apiKey)
        } else {
            self.configuration = nil
        }
    }

    func save(configuration: APIConfiguration) throws {
        userDefaults.set(configuration.endpoint, forKey: endpointKey)
        userDefaults.set(configuration.apiKey, forKey: apiKeyKey)
        userDefaults.set(configuration.provider.rawValue, forKey: providerKey)
        self.configuration = configuration
    }

    func clearConfiguration() throws {
        userDefaults.removeObject(forKey: endpointKey)
        userDefaults.removeObject(forKey: apiKeyKey)
        userDefaults.removeObject(forKey: providerKey)
        self.configuration = nil
    }
}
