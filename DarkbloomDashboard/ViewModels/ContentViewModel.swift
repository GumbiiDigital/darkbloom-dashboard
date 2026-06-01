import Foundation

@MainActor @Observable
final class ContentViewModel {
    private var client: DarkbloomClient?
    
    private var statsTask: Task<Void, any Error>?
    private var attestationsTask: Task<Void, any Error>?
    private var balanceTask: Task<Void, any Error>?
    
    private(set) var stats: DarkbloomStats?
    private(set) var attestations: DarkbloomAttestations?
    private(set) var balance: DarkbloomBalance?
    
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
        try await self.refreshBalance()
        
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
        
        self.balanceTask?.cancel()
        self.balanceTask = Task {
            while !Task.isCancelled {
                try await Task.sleep(for: .seconds(60))
                try await self.refreshBalance()
            }
        }
    }
    
    private func refreshStats() async throws {
        self.stats = try await client?.stats()
    }
    
    private func refreshAttestations() async throws {
        self.attestations = try await client?.attestations()
    }
    
    private func refreshBalance() async throws {
        self.balance = try await client?.balance()
    }
    
    var routableProviderCount: Int? {
        guard let attestations else { return 0 }
        return attestations.providers.count(where: \.isTrusted)
    }
}
