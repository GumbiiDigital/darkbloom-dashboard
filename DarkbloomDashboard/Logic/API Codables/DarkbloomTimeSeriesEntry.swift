import Foundation

struct DarkbloomTimeSeriesEntry: Decodable {
    let timestamp: Date
    let totalTokens: Int
    let promptTokens: Int
    let completionTokens: Int
    let requests: Int
}
