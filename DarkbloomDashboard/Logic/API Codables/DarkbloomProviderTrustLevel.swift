import Foundation

enum DarkbloomProviderTrustLevel: String, Decodable, Equatable {
    case hardware = "hardware"
    case selfSigned = "self_signed"
    case none = "none"
}

extension DarkbloomProviderTrustLevel {
    var displayName: String {
        switch self {
            case .hardware: "Hardware"
            case .selfSigned: "Self-Signed"
            case .none: "None"
        }
    }
}
