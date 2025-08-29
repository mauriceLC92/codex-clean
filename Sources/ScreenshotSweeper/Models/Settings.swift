import Foundation

struct Settings: Codable {
    enum DestinationMode: Codable {
        case trash
        case folder(bookmark: Data)
    }

    var cleanupEnabled: Bool = true
    /// Stored as hour/minute components.
    var cleanupTime: DateComponents = DateComponents(hour: 23, minute: 59)
    var destinationMode: DestinationMode = .trash
    var prefix: String = "Screenshot"
    var isCaseSensitive: Bool = true
    var totalCleaned: Int = 0
    var lastRun: Date? = nil
}

extension Settings {
    private static let defaultsKey = "settings"

    static func load() -> Settings {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: defaultsKey),
           let s = try? JSONDecoder().decode(Settings.self, from: data) {
            return s
        }
        return Settings()
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }
}
