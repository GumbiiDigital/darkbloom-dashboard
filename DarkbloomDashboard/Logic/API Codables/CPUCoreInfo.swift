import Foundation

struct CPUCoreInfo: Decodable, Equatable {
    let total: Int
    let performance: Int
    let efficiency: Int
}
