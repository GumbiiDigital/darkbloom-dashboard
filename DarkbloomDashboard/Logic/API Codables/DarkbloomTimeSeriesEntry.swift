import Foundation

struct DarkbloomTimeSeriesEntry: Decodable {
    let timestamp: Date
    let totalTokens: Int
    let promptTokens: Int
    let completionTokens: Int
    let requests: Int
}

extension DarkbloomTimeSeriesEntry: Identifiable {
    var id: String {
        "\(timestamp.formatted(.iso8601))-\(totalTokens)-\(requests)"
    }
}
