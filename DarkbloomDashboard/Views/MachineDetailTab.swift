import SwiftUI
import FiveKit

struct MachineDetailTab: View {
    @Environment(ContentViewModel.self) private var viewModel
    
    let serialNo: String
    
    var providerAttestation: DarkbloomProviderAttestation? {
        viewModel.attestations?.providers.first(where: { $0.serialNumber == serialNo })
    }
    
    func providerStats(for id: String) -> DarkbloomProviderStat? {
        viewModel.stats?.providers.first(where: { $0.id == id })
    }
    
    var body: some View {
        Form {
            if let providerAttestation {
                Section {
                    LabeledContent {
                        Text(providerAttestation.providerId)
                    } label: {
                        Text("Provider ID")
                    }
                }
                HardwareSection(providerAttestation: providerAttestation)
                TrustSection(providerAttestation: providerAttestation)
                if let providerStats = providerStats(for: providerAttestation.providerId) {
                    NetworkSection(providerAttestation: providerAttestation, providerStats: providerStats)
                }
            }
        }
        .formStyle(.grouped)
    }
}

extension MachineDetailTab {
    struct HardwareSection: View {
        let providerAttestation: DarkbloomProviderAttestation
        
        var body: some View {
            Section {
                LabeledContent {
                    if let hwModel = ModelIdentifier(rawValue: providerAttestation.hardwareModel) {
                        Text(hwModel.displayName)
                    } else {
                        Text(providerAttestation.hardwareModel)
                    }
                } label: {
                    Text("Model")
                }
                if ModelIdentifier(rawValue: providerAttestation.hardwareModel) == nil {
                    LabeledContent {
                        Text(providerAttestation.chipName)
                    } label: {
                        Text("Chip Name")
                    }
                }
                LabeledContent {
                    Text("\(providerAttestation.memoryGb) GB")
                } label: {
                    Text("Unified Memory")
                }
            } header: {
                Text("Hardware")
            }
        }
    }
    
    struct TrustSection: View {
        let providerAttestation: DarkbloomProviderAttestation
        
        var body: some View {
            Section {
                LabeledContent {
                    Text(providerAttestation.trustLevel.displayName)
                } label: {
                    Text("Trust Level")
                }
                LabeledContent {
                    Text(providerAttestation.mdaVerified ? "Yes" : "No")
                } label: {
                    Text("Mobile Device Attestation (MDA)")
                }
                LabeledContent {
                    Text(providerAttestation.mdmVerified ? "Yes" : "No")
                } label: {
                    Text("Mobile Device Management (MDM)")
                }
                LabeledContent {
                    Text(providerAttestation.authenticatedRootEnabled ? "Yes" : "No")
                } label: {
                    Text("Authenticated Root")
                }
                LabeledContent {
                    Text(providerAttestation.sipEnabled ? "Yes" : "No")
                } label: {
                    Text("System Integrity Protection")
                }
                LabeledContent {
                    Text(providerAttestation.secureBootEnabled ? "Yes" : "No")
                } label: {
                    Text("Secure Boot")
                }
                LabeledContent {
                    Text(providerAttestation.secureEnclave ? "Yes" : "No")
                } label: {
                    Text("Secure Enclave")
                }
            } header: {
                HStack {
                    Text("Trust & Attestation")
                    Spacer()
                    if providerAttestation.isTrusted {
                        HStack {
                            Text(Image(systemName: "shield.fill"))
                            Text("Trusted")
                        }
                        .foregroundStyle(.green)
                    } else {
                        HStack {
                            Text(Image(systemName: "shield.slash.fill"))
                            Text("Reduced Trust")
                        }
                        .foregroundStyle(.yellow)
                    }
                }
            }
        }
    }
    
    struct NetworkSection: View {
        let providerAttestation: DarkbloomProviderAttestation
        let providerStats: DarkbloomProviderStat
        
        var body: some View {
            Section {
                LabeledContent {
                    Text(providerStats.requestsServed, format: .number)
                        .contentTransition(.numericText())
                } label: {
                    Text("Requests Served")
                }
                LabeledContent {
                    Text(providerStats.tokensGenerated, format: .number)
                        .contentTransition(.numericText())
                } label: {
                    Text("Tokens Generated")
                }
            } header: {
                Text("Network")
            }
            .animation(.snappy, value: providerStats)
        }
    }
}

#Preview {
    MachineDetailTab(serialNo: "NJD6MGW279")
        .environment(ContentViewModel())
}
