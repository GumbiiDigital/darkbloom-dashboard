import Foundation

struct DarkbloomProviderLocation: Decodable {
    let key: String
    let scope: DarkbloomLocationScope
    let city: String
    let region: String
    let regionCode: String
    let country: String
    let countryCode: String
    let latitude: Double
    let longitude: Double
    let providers: Int
    let hardwareAttested: Int
    let gpuCores: Int
    let memoryGb: Int
}
