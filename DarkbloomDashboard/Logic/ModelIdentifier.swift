import Foundation

enum ModelKind {
    case macBookPro
    case macMini
    case macStudio
    case macPro
}

extension ModelKind {
    var systemImage: String {
        switch self {
            case .macBookPro: "macbook"
            case .macMini: "macmini"
            case .macStudio: "macstudio"
            case .macPro: "macpro.gen3"
        }
    }
}

enum ModelIdentifier: String, Identifiable {
    
    var id: String {
        rawValue
    }
    
    // MARK: MacBook Pro
    // https://everymac.com/systems/by-identifier/all-macbook-pro-model-identifiers.html
    
    case macBookProM1_13in = "MacBookPro17,1"
    case macBookProM1Pro_14in = "MacBookPro18,3"
    case macBookProM1Max_14in = "MacBookPro18,4"
    case macBookProM1Pro_16in = "MacBookPro18,1"
    case macBookProM1Max_16in = "MacBookPro18,2"
    case macBookProM2_13in = "Mac14,7"
    case macBookProM2Pro_14in = "Mac14,9"
    case macBookProM2Max_14in = "Mac14,5"
    case macBookProM2Pro_16in = "Mac14,10"
    case macBookProM2Max_16in = "Mac14,6"
    case macBookProM3_14in = "Mac15,3"
    case macBookProM3Pro_14in = "Mac15,6"
    case macBookProM3Max_14CPU_30GPU_14in = "Mac15,10"
    case macBookProM3Max_16CPU_40GPU_14in = "Mac15,8"
    case macBookProM3Pro_16in = "Mac15,7"
    case macBookProM3Max_14CPU_30GPU_16in = "Mac15,11"
    case macBookProM3Max_16CPU_40GPU_16in = "Mac15,9"
    case macBookProM4_14in = "Mac16,1"
    case macBookProM4Pro_14in = "Mac16,8"
    case macBookProM4Max_14in = "Mac16,6"
    case macBookProM4Pro_16in = "Mac16,7"
    case macBookProM4Max_16in = "Mac16,5"
    case macBookProM5_14in = "Mac17,2"
    case macBookProM5Pro_14in = "Mac17,9"
    case macBookProM5Max_14in = "Mac17,7"
    case macBookProM5Pro_16in = "Mac17,8"
    case macBookProM5Max_16in = "Mac17,6"
    
    // MARK: Mac Mini
    // https://everymac.com/systems/by-identifier/all-mac-mini-model-identifiers.html
    
    case macMiniM1 = "Macmini9,1"
    case macMiniM2 = "Mac14,3"
    case macMiniM2Pro = "Mac14,12"
    case macMiniM4 = "Mac16,10"
    case macMiniM4Pro = "Mac16,11"
    
    // MARK: Mac Studio
    // https://everymac.com/systems/by-identifier/all-mac-studio-model-identifiers.html
    
    case macStudioM1Max = "Mac13,1"
    case macStudioM1Ultra = "Mac13,2"
    case macStudioM2Max = "Mac14,13"
    case macStudioM2Ultra = "Mac14,14"
    case macStudioM3Ultra = "Mac15,14"
    case macStudioM4Max = "Mac16,9"
    
    // MARK: Mac Pro
    // https://everymac.com/systems/by-identifier/all-mac-pro-model-identifiers.html
    
    case macProM2Ultra = "Mac14,8"
}

extension ModelIdentifier {
    var displayName: String {
        switch self {
            case .macBookProM1_13in: #"MacBook Pro M1 13""#
            case .macBookProM1Pro_14in: #"MacBook Pro M1 Pro 14""#
            case .macBookProM1Max_14in: #"MacBook Pro M1 Max 14""#
            case .macBookProM1Pro_16in: #"MacBook Pro M1 Pro 16""#
            case .macBookProM1Max_16in: #"MacBook Pro M1 Max 16""#
            case .macBookProM2_13in: #"MacBook Pro M2 13""#
            case .macBookProM2Pro_14in: #"MacBook Pro M2 Pro 14""#
            case .macBookProM2Max_14in: #"MacBook Pro M2 Max 14""#
            case .macBookProM2Pro_16in: #"MacBook Pro M2 Pro 16""#
            case .macBookProM2Max_16in: #"MacBook Pro M2 Max 16""#
            case .macBookProM3_14in: #"MacBook Pro M3 14""#
            case .macBookProM3Pro_14in: #"MacBook Pro M3 Pro 14""#
            case .macBookProM3Max_14CPU_30GPU_14in: #"MacBook Pro M3 Max CPU/14 GPU/30 14""#
            case .macBookProM3Max_16CPU_40GPU_14in: #"MacBook Pro M3 Max CPU/16 GPU/40 14""#
            case .macBookProM3Pro_16in: #"MacBook Pro M3 Pro 16""#
            case .macBookProM3Max_14CPU_30GPU_16in: #"MacBook Pro M3 Max CPU/14 GPU/30 16""#
            case .macBookProM3Max_16CPU_40GPU_16in: #"MacBook Pro M3 Max CPU/16 GPU/30 16""#
            case .macBookProM4_14in: #"MacBook Pro M4 14""#
            case .macBookProM4Pro_14in: #"MacBook Pro M4 Pro 14""#
            case .macBookProM4Max_14in: #"MacBook Pro M4 Max 14""#
            case .macBookProM4Pro_16in: #"MacBook Pro M4 Pro 16""#
            case .macBookProM4Max_16in: #"MacBook Pro M4 Max 16""#
            case .macBookProM5_14in: #"MacBook Pro M5 14""#
            case .macBookProM5Pro_14in: #"MacBook Pro M5 Pro 14""#
            case .macBookProM5Max_14in: #"MacBook Pro M5 Max 14""#
            case .macBookProM5Pro_16in: #"MacBook Pro M5 Pro 16""#
            case .macBookProM5Max_16in: #"MacBook Pro M5 Max 16""#
            case .macMiniM1: "Mac mini M1"
            case .macMiniM2: "Mac mini M2"
            case .macMiniM2Pro: "Mac mini M2 Pro"
            case .macMiniM4: "Mac mini M4"
            case .macMiniM4Pro: "Mac mini M4 Pro"
            case .macStudioM1Max: "Mac Studio M1 Max"
            case .macStudioM1Ultra: "Mac Studio M1 Ultra"
            case .macStudioM2Max: "Mac Studio M2 Max"
            case .macStudioM2Ultra: "Mac Studio M2 Ultra"
            case .macStudioM3Ultra: "Mac Studio M3 Ultra"
            case .macStudioM4Max: "Mac Studio M4 Max"
            case .macProM2Ultra: "Mac Pro M2 Ultra"
        }
    }
    
    var modelKind: ModelKind {
        switch self {
            case .macBookProM1_13in,
                    .macBookProM1Pro_14in,
                    .macBookProM1Max_14in,
                    .macBookProM1Pro_16in,
                    .macBookProM1Max_16in,
                    .macBookProM2_13in,
                    .macBookProM2Pro_14in,
                    .macBookProM2Max_14in,
                    .macBookProM2Pro_16in,
                    .macBookProM2Max_16in,
                    .macBookProM3_14in,
                    .macBookProM3Pro_14in,
                    .macBookProM3Max_14CPU_30GPU_14in,
                    .macBookProM3Max_16CPU_40GPU_14in,
                    .macBookProM3Pro_16in,
                    .macBookProM3Max_14CPU_30GPU_16in,
                    .macBookProM3Max_16CPU_40GPU_16in,
                    .macBookProM4_14in,
                    .macBookProM4Pro_14in,
                    .macBookProM4Max_14in,
                    .macBookProM4Pro_16in,
                    .macBookProM4Max_16in,
                    .macBookProM5_14in,
                    .macBookProM5Pro_14in,
                    .macBookProM5Max_14in,
                    .macBookProM5Pro_16in,
                    .macBookProM5Max_16in:
                    .macBookPro
            case .macMiniM1,
                    .macMiniM2,
                    .macMiniM2Pro,
                    .macMiniM4,
                    .macMiniM4Pro:
                    .macMini
            case .macStudioM1Max,
                    .macStudioM1Ultra,
                    .macStudioM2Max,
                    .macStudioM2Ultra,
                    .macStudioM3Ultra,
                    .macStudioM4Max:
                    .macStudio
            case .macProM2Ultra:
                    .macPro
        }
    }
}
