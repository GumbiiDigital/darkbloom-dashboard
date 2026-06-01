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
        
        do {
            try await self.refreshStats()
        } catch {
            print(error)
        }
        do {
            try await self.refreshAttestations()
        } catch {
            print(error)
        }
        do {
            try await self.refreshBalance()
        } catch {
            print(error)
        }
        
        self.statsTask?.cancel()
        self.statsTask = Task {
            while !Task.isCancelled {
                try await Task.sleep(for: .seconds(60))
                do {
                    try await self.refreshStats()
                } catch {
                    print(error)
                }
            }
        }
        
        self.attestationsTask?.cancel()
        self.attestationsTask = Task {
            while !Task.isCancelled {
                try await Task.sleep(for: .seconds(60))
                do {
                    try await self.refreshAttestations()
                } catch {
                    print(error)
                }
            }
        }
        
        self.balanceTask?.cancel()
        self.balanceTask = Task {
            while !Task.isCancelled {
                try await Task.sleep(for: .seconds(60))
                do {
                    try await self.refreshBalance()
                } catch {
                    print(error)
                }
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
        let date = Date.now
        guard let currentBalance = try await client?.balance() else { return }
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
