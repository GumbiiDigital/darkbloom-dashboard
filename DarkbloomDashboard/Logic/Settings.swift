import Foundation

@MainActor @Observable
final class Settings {
    static let shared = Settings()
    
    private let defaults: UserDefaults = UserDefaults.standard
    
    var apiKey: String? {
        didSet { defaults.set(apiKey, forKey: "darkbloom_api_key") }
    }
    
    var trackedMachineSerialNumbers: [String] {
        didSet {
            defaults.set(
                trackedMachineSerialNumbers.joined(separator: ","),
                forKey: "tracked_machine_serial_numbers"
            )
        }
    }
    
    var loadTestingApiKeys: [String] {
        didSet {
            defaults.set(
                loadTestingApiKeys.joined(separator: ","),
                forKey: "load_testing_api_keys"
            )
        }
    }
    
    private init() {
        self.apiKey = defaults.string(forKey: "darkbloom_api_key")
        self.trackedMachineSerialNumbers = defaults
            .string(forKey: "tracked_machine_serial_numbers")
            .map { $0.split(separator: ",").map(String.init) } ?? []
        self.loadTestingApiKeys = defaults
            .string(forKey: "load_testing_api_keys")
            .map { $0.split(separator: ",").map(String.init) } ?? []
    }
}
