import Foundation

struct DarkbloomRequestFlow: Decodable {
    let key: String
    let from: DarkbloomRequestFlowLocation
    let to: DarkbloomRequestFlowLocation
    let requests: Int
    let promptTokens: Int
    let completionTokens: Int
}
