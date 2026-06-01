import SwiftUI
import FiveKit

struct MachineDetailTab: View {
    @Environment(ContentViewModel.self) private var viewModel
    
    let serialNo: String
    
    var body: some View {
        Form {
            if let machine = viewModel.machineInfo[serialNo] {
                Section {
                    LabeledContent {
                        Text(machine.providerId)
                    } label: {
                        Text("Provider ID")
                    }
                }
                HardwareSection(hardware: machine.hardware)
                #if os(macOS)
                TrustSection(trust: machine.trust, showAll: true)
                #else
                TrustSection(trust: machine.trust, showAll: false)
                #endif
                NetworkSection(activity: machine.activity)
            }
        }
        .formStyle(.grouped)
    }
}

extension MachineDetailTab {
    struct HardwareSection: View {
        let hardware: MachineHardwareInfo
        
        var body: some View {
            Section {
                LabeledContent {
                    Text(hardware.modelDisplayName)
                } label: {
                    Text("Model")
                }
                LabeledContent {
                    Text("\(hardware.memoryGb) GB")
                } label: {
                    Text("Unified Memory")
                }
                LabeledContent {
                    Text("\(hardware.memoryBandwidthGbs) GB/s")
                } label: {
                    Text("Memory Bandwidth")
                }
            } header: {
                Text("Hardware")
            }
        }
    }
    
    struct TrustSection: View {
        let trust: MachineTrustInfo
        let showAll: Bool
        
        var body: some View {
            Section {
                LabeledContent {
                    Text(trust.trustLevel.displayName)
                } label: {
                    Text("Trust Level")
                }
                if showAll || !trust.mdaVerified {
                    LabeledContent {
                        Text(trust.mdaVerified ? "Yes" : "No")
                    } label: {
                        Text("Mobile Device Attestation (MDA)")
                    }
                }
                if showAll || !trust.mdmVerified {
                    LabeledContent {
                        Text(trust.mdmVerified ? "Yes" : "No")
                    } label: {
                        Text("Mobile Device Management (MDM)")
                    }
                }
                if showAll || !trust.authenticatedRootEnabled {
                    LabeledContent {
                        Text(trust.authenticatedRootEnabled ? "Yes" : "No")
                    } label: {
                        Text("Authenticated Root")
                    }
                }
                if showAll || !trust.sipEnabled {
                    LabeledContent {
                        Text(trust.sipEnabled ? "Yes" : "No")
                    } label: {
                        Text("System Integrity Protection")
                    }
                }
                if showAll || !trust.secureBootEnabled {
                    LabeledContent {
                        Text(trust.secureBootEnabled ? "Yes" : "No")
                    } label: {
                        Text("Secure Boot")
                    }
                }
                if showAll || !trust.secureEnclave {
                    LabeledContent {
                        Text(trust.secureEnclave ? "Yes" : "No")
                    } label: {
                        Text("Secure Enclave")
                    }
                }
            } header: {
                HStack {
                    Text("Trust & Attestation")
                    Spacer()
                    if trust.isTrusted {
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
            .animation(.snappy, value: trust)
        }
    }
    
    struct NetworkSection: View {
        let activity: MachineActivityInfo
        
        var body: some View {
            Section {
                LabeledContent {
                    Text(activity.requestsServed, format: .number)
                        .contentTransition(.numericText())
                } label: {
                    Text("Requests Served")
                }
                LabeledContent {
                    Text(activity.tokensGenerated, format: .number)
                        .contentTransition(.numericText())
                } label: {
                    Text("Tokens Generated")
                }
            } header: {
                Text("Network")
            }
            .animation(.snappy, value: activity)
        }
    }
}

#Preview {
    MachineDetailTab(serialNo: "NJD6MGW279")
        .environment(ContentViewModel())
}
