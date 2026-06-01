import Foundation

struct DarkbloomStats: Decodable {
    let activeProviders: Int
    let providers: [DarkbloomProviderStat]
}
