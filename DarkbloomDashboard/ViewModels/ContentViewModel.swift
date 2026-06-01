import Foundation

struct BalanceChange: Equatable {
    let diff: Double
    let date: Date
}

@MainActor @Observable
final class ContentViewModel {
    private var client: DarkbloomClient?
    
    private var statsTask: Task<Void, any Error>?
    private var attestationsTask: Task<Void, any Error>?
    private var balanceTask: Task<Void, any Error>?
    
    private(set) var stats: DarkbloomStats?
    private(set) var attestations: DarkbloomAttestations?
    private(set) var balance: DarkbloomBalance?
    
    private(set) var balanceChanges: [BalanceChange] = []
    
    init() {
        if let apiKey = Settings.shared.apiKey {
            Task {
                try? await self.update(apiKey: apiKey)
            }
        }
    }
    
    func update(apiKey: String) async throws {
        self.client = DarkbloomClient(apiKey: apiKey)
        
        try? await self.refreshStats()
        try? await self.refreshAttestations()
        try? await self.refreshBalance()
        
        self.statsTask?.cancel()
        self.statsTask = Task {
            while !Task.isCancelled {
                try await Task.sleep(for: .seconds(60))
                try? await self.refreshStats()
            }
        }
        
        self.attestationsTask?.cancel()
        self.attestationsTask = Task {
            while !Task.isCancelled {
                try await Task.sleep(for: .seconds(60))
                try? await self.refreshAttestations()
            }
        }
        
        self.balanceTask?.cancel()
        self.balanceTask = Task {
            while !Task.isCancelled {
                try await Task.sleep(for: .seconds(60))
                try? await self.refreshBalance()
            }
        }
    }
    
    private func refreshStats() async throws {
        do {
            self.stats = try await client?.stats()
        } catch {
            print(error)
            throw error
        }
    }
    
    private func refreshAttestations() async throws {
        do {
            self.attestations = try await client?.attestations()
        } catch {
            print(error)
            throw error
        }
    }
    
    private func fetchBalance() async throws -> DarkbloomBalance? {
        do {
            return try await client?.balance()
        } catch {
            print(error)
            throw error
        }
    }
    
    private func refreshBalance() async throws {
        let date = Date.now
        guard let currentBalance = try await self.fetchBalance() else { return }
        if let previousBalance = self.balance {
            let microUsdDiff = max(0, currentBalance.balanceMicroUsd - previousBalance.balanceMicroUsd)
            let diff = Double(microUsdDiff) / 1_000_000.0
            if diff > 0 {
                let change = BalanceChange(diff: diff, date: date)
                balanceChanges.append(change)
            }
        }
        self.balance = currentBalance
    }
    
    var routableProviderCount: Int? {
        guard let attestations else { return 0 }
        return attestations.providers.count(where: \.isTrusted)
    }
}
