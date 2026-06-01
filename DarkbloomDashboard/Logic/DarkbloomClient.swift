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
    
    private func fetch<T>(_ url: URL) async throws -> T where T: Decodable {
        var req = URLRequest(url: url)
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let (data, res) = try await URLSession.shared.data(for: req)
        guard let httpResponse = res as? HTTPURLResponse else { throw DarkbloomError.badResponse }
        guard httpResponse.statusCode == 200 else { throw DarkbloomError.badResponse }
        return try decoder.decode(T.self, from: data)
    }
    
    func stats() async throws -> DarkbloomStats {
        let url = HOST.appending(path: "stats")
        return try await fetch(url)
    }
    
    func attestations() async throws -> DarkbloomAttestations {
        let url = HOST.appending(path: "providers/attestation")
        return try await fetch(url)
    }
    
    func balance() async throws -> DarkbloomBalance {
        let url = HOST.appending(path: "payments/balance")
        return try await fetch(url)
    }
}
