import Foundation

class SettingsService {

    static let shared = SettingsService()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let sortOption = "settings.sortOption"
        static let filterCategory = "settings.filterCategory"
        static let selectedProjectIDs = "settings.selectedProjectIDs"
        static let selectedLabelIDs = "settings.selectedLabelIDs"
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
}