import Foundation

struct DarkbloomBalance: Decodable, Equatable {
    let balanceMicroUsd: Int
    let balanceUsd: Double
}

extension DarkbloomBalance {
    var formatted: String {
        balanceUsd.formatted(.currency(code: "USD"))
    }
}
