import Foundation

enum DarkbloomProviderStatus: String, Decodable, Equatable {
    case online = "online"
    case serving = "serving"
    case untrusted = "untrusted"
}

extension DarkbloomProviderStatus {
    var displayName: String {
        switch self {
            case .online: "Online"
            case .serving: "Serving"
            case .untrusted: "Untrusted"
        }
    }
}
