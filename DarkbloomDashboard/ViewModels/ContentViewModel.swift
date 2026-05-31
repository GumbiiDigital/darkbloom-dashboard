import Foundation

@MainActor @Observable
final class ContentViewModel {
    private var client: DarkbloomClient?
    
    private var statsTask: Task<Void, any Error>?
    private var attestationsTask: Task<Void, any Error>?
    
    private(set) var stats: DarkbloomStats?
    private(set) var attestations: DarkbloomAttestations?
    
    init() {
        if let apiKey = Settings.shared.apiKey {
            Task {
                try? await self.update(apiKey: apiKey)
            }
        }
    }
    
    func update(apiKey: String) async throws {
        self.client = DarkbloomClient(apiKey: apiKey)
        
        try await self.refreshStats()
        try await self.refreshAttestations()
        
        self.statsTask?.cancel()
        self.statsTask = Task {
            while !Task.isCancelled {
                try await Task.sleep(for: .seconds(60))
                try await self.refreshStats()
            }
        }
        
        self.attestationsTask?.cancel()
        self.attestationsTask = Task {
            while !Task.isCancelled {
                try await Task.sleep(for: .seconds(60))
                try await self.refreshAttestations()
            }
        }
    }
    
    private func refreshStats() async throws {
        self.stats = try await client?.stats()
    }
    
    private func refreshAttestations() async throws {
        self.attestations = try await client?.attestations()
    }
    
    var routableProviderCount: Int? {
        guard let attestations else { return 0 }
        return attestations.providers.count(where: \.isTrusted)
    }
}
