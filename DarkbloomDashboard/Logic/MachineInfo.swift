import Foundation

struct MachineInfo: Equatable {
    let providerId: String
    let serialNumber: String
    let trust: MachineTrustInfo
    let hardware: MachineHardwareInfo
    let activity: MachineActivityInfo
}

struct MachineTrustInfo: Equatable {
    let status: DarkbloomProviderStatus
    let trustLevel: DarkbloomProviderTrustLevel
    let attested: Bool
    let acmeVerified: Bool
    let authenticatedRootEnabled: Bool
    let mdaSerial: String?
    let mdaVerified: Bool
    let mdmVerified: Bool
    let secureBootEnabled: Bool
    let secureEnclave: Bool
    let sipEnabled: Bool
    let runtimeVerified: Bool
    
    var isOnline: Bool {
        let onlineStatus: Set<DarkbloomProviderStatus> = [.online, .serving]
        return onlineStatus.contains(status)
    }
    
    /// Returns whether the machine is likely to be in a trusted state.
    var isTrusted: Bool {
        let trustedStatus: Set<DarkbloomProviderStatus> = [.online, .serving]
        let isTrustedStatus = trustedStatus.contains(status)
        let isTrustedHardware = trustLevel == .hardware
        let isTrustedEnvironment = authenticatedRootEnabled && secureEnclave && secureBootEnabled && sipEnabled
        let isMdaAndMdmVerified = mdaVerified && mdmVerified
        return (
            isTrustedStatus
            && isTrustedHardware
            && isTrustedEnvironment
            && isMdaAndMdmVerified
            && runtimeVerified
            && attested
        )
    }
}

struct MachineHardwareInfo: Equatable {
    let modelIdentifier: String
    let chipName: String
    let cpuCores: CPUCoreInfo
    let gpuCores: Int
    let memoryGb: Int
    let memoryBandwidthGbs: Int
    
    var modelDisplayName: String {
        if let model = ModelIdentifier(rawValue: modelIdentifier) {
            model.displayName
        } else {
            "\(modelIdentifier) (\(chipName))"
        }
    }
}

struct MachineActivityInfo: Equatable {
    let requestsServed: Int
    let tokensGenerated: Int
    let lastChallengeVerified: String
    let failedChallenges: Int
    
    var lastChallengeDate: Date? {
        guard !lastChallengeVerified.isEmpty else { return nil }
        return ISO8601DateFormatter().date(from: lastChallengeVerified)
    }
}
