import Foundation

@MainActor @Observable
final class Settings {
    static let shared = Settings()
    
    private let defaults: UserDefaults = UserDefaults.standard
    
    var apiKey: String? {
        didSet { defaults.set(apiKey, forKey: "darkbloom_api_key") }
    }
    
    private init() {
        self.apiKey = defaults.string(forKey: "darkbloom_api_key")
    }
}
