import Foundation

class SettingsService {

    static let shared = SettingsService()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let sortOption = "settings.sortOption"
        static let filterCategory = "settings.filterCategory"
        static let selectedProjectIDs = "settings.selectedProjectIDs"
        static let selectedLabelIDs = "settings.selectedLabelIDs"
        static let cachedAPIResponse = "cache.apiResponse"
    }

    private init() {}

    // MARK: - Sort Option

    var sortOption: SortOption {
        get {
            guard let rawValue = defaults.string(forKey: Keys.sortOption) else {
                return .dueDate // Default value
            }
            return SortOption(rawValue: rawValue) ?? .dueDate
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.sortOption)
        }
    }

    // MARK: - Filter Category

    var filterCategory: FilterCategory {
        get {
            guard let rawValue = defaults.string(forKey: Keys.filterCategory) else {
                return .all // Default value
            }
            return FilterCategory(rawValue: rawValue) ?? .all
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.filterCategory)
        }
    }

    // MARK: - Selected Project IDs

    var selectedProjectIDs: Set<UUID> {
        get {
            guard let uuidStrings = defaults.array(forKey: Keys.selectedProjectIDs) as? [String] else {
                return []
            }
            return Set(uuidStrings.compactMap { UUID(uuidString: $0) })
        }
        set {
            let uuidStrings = newValue.map { $0.uuidString }
            defaults.set(uuidStrings, forKey: Keys.selectedProjectIDs)
        }
    }

    // MARK: - Selected Label IDs

    var selectedLabelIDs: Set<UUID> {
        get {
            guard let uuidStrings = defaults.array(forKey: Keys.selectedLabelIDs) as? [String] else {
                return []
            }
            return Set(uuidStrings.compactMap { UUID(uuidString: $0) })
        }
        set {
            let uuidStrings = newValue.map { $0.uuidString }
            defaults.set(uuidStrings, forKey: Keys.selectedLabelIDs)
        }
    }

    // MARK: - API Response Cache

    var cachedAPIResponse: APIResponse? {
        get {
            guard let data = defaults.data(forKey: Keys.cachedAPIResponse) else { return nil }
            // Use the same decoder as NetworkService to ensure consistency
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                if let date = dateFormatter.date(from: dateString) { return date }
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if let date = dateFormatter.date(from: dateString) { return date }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateString)")
            }
            return try? decoder.decode(APIResponse.self, from: data)
        }
        set {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(newValue) {
                defaults.set(data, forKey: Keys.cachedAPIResponse)
            }
        }
    }
}