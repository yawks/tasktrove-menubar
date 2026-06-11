import Foundation

enum NetworkServiceFactory {
    static func make(configuration: APIConfiguration) throws -> NetworkServiceProtocol {
        switch configuration.provider {
        case .taskTrove:
            return try NetworkService(configuration: configuration)
        case .vikunja:
            return try VikunjaNetworkService(configuration: configuration)
        }
    }
}
