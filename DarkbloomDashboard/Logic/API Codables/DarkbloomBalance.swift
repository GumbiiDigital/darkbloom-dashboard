import Foundation

struct DarkbloomBalance: Decodable, Equatable {
    let balanceMicroUsd: Int
    let balanceUsd: String
}

extension DarkbloomBalance {
    var usd: Double {
        Double(balanceMicroUsd) / 1_000_000.0
    }
    
    var formatted: String {
        usd.formatted(.currency(code: "USD"))
    }
}
