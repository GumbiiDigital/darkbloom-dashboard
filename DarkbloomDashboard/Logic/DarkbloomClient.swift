import Foundation

private let HOST: URL = URL(string: "https://api.darkbloom.dev/v1")!

enum DarkbloomError: Error {
    case badResponse
}

final class DarkbloomClient {
    let apiKey: String
    let decoder: JSONDecoder
    
    init(apiKey: String) {
        self.apiKey = apiKey
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    func stats() async throws -> DarkbloomStats {
        let url = HOST.appending(path: "stats")
        var req = URLRequest(url: url)
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let (data, res) = try await URLSession.shared.data(for: req)
        guard let httpResponse = res as? HTTPURLResponse else { throw DarkbloomError.badResponse }
        guard httpResponse.statusCode == 200 else { throw DarkbloomError.badResponse }
        return try decoder.decode(DarkbloomStats.self, from: data)
    }
    
    func attestations() async throws -> DarkbloomAttestations {
        let url = HOST.appending(path: "providers/attestation")
        var req = URLRequest(url: url)
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let (data, res) = try await URLSession.shared.data(for: req)
        guard let httpResponse = res as? HTTPURLResponse else { throw DarkbloomError.badResponse }
        guard httpResponse.statusCode == 200 else { throw DarkbloomError.badResponse }
        return try decoder.decode(DarkbloomAttestations.self, from: data)
    }
}

struct DarkbloomStats: Decodable {
    let activeProviders: Int
    let providers: [DarkbloomProviderStat]
}

struct CPUCoreInfo: Decodable, Equatable {
    let total: Int
    let performance: Int
    let efficiency: Int
}

struct DarkbloomProviderStat: Decodable, Equatable {
    let id: String
    let attested: Bool
    let chip: String
    let models: [String]
    let status: DarkbloomProviderStatus
    let trustLevel: DarkbloomProviderTrustLevel
    let runtimeVerified: Bool
    
    let cpuCores: CPUCoreInfo
    let gpuCores: Int
    
    let memoryGb: Int
    let memoryBandwidthGbs: Int
    
    let requestsServed: Int
    let tokensGenerated: Int
    
    let failedChallenges: Int
    
    var isTrusted: Bool {
        trustLevel == .hardware && status != .untrusted
    }
}

struct DarkbloomAttestations: Decodable {
    let providers: [DarkbloomProviderAttestation]
}

struct DarkbloomProviderAttestation: Decodable, Equatable {
    let acmeVerified: Bool
    let authenticatedRootEnabled: Bool
    let chipName: String
    let gpuCores: Int
    let hardwareModel: String
    let mdaSerial: String?
    let mdaVerified: Bool
    let mdmVerified: Bool
    let memoryGb: Int
    let models: [String]?
    let providerId: String
    let secureBootEnabled: Bool
    let secureEnclave: Bool
    let serialNumber: String
    let sipEnabled: Bool
    let status: DarkbloomProviderStatus
    let trustLevel: DarkbloomProviderTrustLevel
    
    var isTrusted: Bool {
        trustLevel == .hardware
        && status != .untrusted
        && authenticatedRootEnabled
        && mdaVerified
        && mdmVerified
        && secureBootEnabled
        && secureEnclave
        && sipEnabled
    }
}

enum DarkbloomProviderStatus: String, Decodable, Equatable {
    case online = "online"
    case serving = "serving"
    case untrusted = "untrusted"
    
    var displayName: String {
        switch self {
            case .online: "Online"
            case .serving: "Serving"
            case .untrusted: "Untrusted"
        }
    }
}

enum DarkbloomProviderTrustLevel: String, Decodable, Equatable {
    case hardware = "hardware"
    case selfSigned = "self_signed"
    case none = "none"
    
    var displayName: String {
        switch self {
            case .hardware: "Hardware"
            case .selfSigned: "Self-Signed"
            case .none: "None"
        }
    }
}
