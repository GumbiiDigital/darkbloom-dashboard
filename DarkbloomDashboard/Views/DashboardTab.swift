import SwiftUI
import FiveKit
import OpenAI

struct DashboardTab: View {
    @AppStorage("darkbloom_api_key_locked") private var apiKeyLocked: Bool = false
    
    @Environment(ContentViewModel.self) private var viewModel
    
    @State private var showAddMachineAlert: Bool = false
    @State private var newMachineSerialNumber: String = ""
    
    @Bindable private var settings = Settings.shared
    
    var body: some View {
        Form {
            Section {
                LabeledContent {
                    HStack(alignment: .firstTextBaseline) {
                        if apiKeyLocked {
                            Text("Hidden")
                                .foregroundStyle(.secondary)
                        } else {
                            SecureField("API Key", text: $settings.apiKey ?? "")
                                .textFieldStyle(.roundedBorder)
                                .labelsHidden()
                        }
                        
                        Button {
                            apiKeyLocked.toggle()
                        } label: {
                            if apiKeyLocked {
                                Text("Edit")
                            } else {
                                Text("Save")
                            }
                        }
                    }
                } label: {
                    Text("API Key")
                }
            } footer: {
                if settings.apiKey == nil || settings.apiKey?.isEmpty == true {
                    Link(
                        "Get your API key here",
                        destination: URL(string: "https://console.darkbloom.dev/api-console")!
                    )
                }
            }
            
            Section {
                if let stats = viewModel.stats {
                    LabeledContent {
                        Text(stats.activeProviders, format: .number)
                    } label: {
                        Text("Active Providers")
                    }
                    
                    if let routableProviderCount = viewModel.routableProviderCount {
                        LabeledContent {
                            Text(routableProviderCount, format: .number)
                        } label: {
                            Text("Trusted Providers")
                        }
                    }
                }
            } header: {
                Label("Network", systemImage: "network")
            }
            
            Section {
                if settings.trackedMachineSerialNumbers.isEmpty {
                    Text("You haven't tracked any machines yet.")
                } else {
                    ForEach(settings.trackedMachineSerialNumbers) { serialNo in
                        HStack(alignment: .firstTextBaseline) {
                            Text(serialNo)
                            Spacer()
                            if let provider = viewModel.attestations?.providers.first(where: { $0.serialNumber == serialNo }) {
                                HStack(alignment: .firstTextBaseline) {
                                    switch provider.isTrusted {
                                        case true:
                                            Text(Image(systemName: "lock.shield.fill"))
                                            Text("Full Trust")
                                        case false:
                                            Text(Image(systemName: "shield.slash.fill"))
                                            Text("Reduced Trust")
                                    }
                                }
                                .foregroundStyle(provider.isTrusted ? Color.secondary : Color.yellow)
                            }
                        }
                        .contentShape(.rect)
                        .contextMenu {
                            Button(role: .destructive) {
                                settings.trackedMachineSerialNumbers.removeAll(subject: serialNo)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        settings.trackedMachineSerialNumbers.remove(atOffsets: indexSet)
                    }
                }
            } header: {
                HStack {
                    Label("Machines", systemImage: "macstudio.fill")
                    Spacer()
                    Button {
                        showAddMachineAlert = true
                    } label: {
                        Text("Add Machine")
                    }
                }
            }
            
            ForEach(settings.trackedMachineSerialNumbers) { serialNo in
                let provider = viewModel.attestations?.providers.first { $0.serialNumber == serialNo }
                let providerStats = provider.flatMap { provider in
                    viewModel.stats?.providers.first { $0.id == provider.providerId }
                }
                MachineInfoView(serialNo: serialNo, provider: provider, stats: providerStats)
            }
        }
        .formStyle(.grouped)
        .alert("Add Machine", isPresented: $showAddMachineAlert) {
            TextField("Serial Number", text: $newMachineSerialNumber)
            
            Button("Save") {
                settings.trackedMachineSerialNumbers.append(newMachineSerialNumber)
                newMachineSerialNumber = ""
            }
            
            Button(role: .cancel) {
                newMachineSerialNumber = ""
            }
        }
    }
}

struct MachineInfoView: View {
    let serialNo: String
    let provider: DarkbloomProviderAttestation?
    let stats: DarkbloomProviderStat?
    
    var body: some View {
        Section {
            if let provider {
                LabeledContent {
                    HStack(alignment: .firstTextBaseline) {
                        switch provider.status {
                            case .online:
                                Text(Image(systemName: "checkmark.circle"))
                                Text("Online")
                            case .serving:
                                Text(Image(systemName: "checkmark.circle.fill"))
                                Text("Serving")
                            case .untrusted:
                                Text(Image(systemName: "exclamationmark.triangle"))
                                Text("Untrusted")
                        }
                    }
                } label: {
                    Text("Status")
                }
                
                LabeledContent {
                    HStack(alignment: .firstTextBaseline) {
                        switch provider.trustLevel {
                            case .hardware:
                                Text(Image(systemName: "macbook.badge.shield.checkmark"))
                                Text("Hardware")
                            case .selfSigned:
                                Text(Image(systemName: "key.shield.fill"))
                                Text("Self-Signed")
                            case .none:
                                Text(Image(systemName: "exclamationmark.triangle"))
                                Text("None")
                        }
                    }
                } label: {
                    Text("Trust Level")
                }
            } else {
                Text("This machine is currently offline.")
            }
        } header: {
            HStack(alignment: .bottom) {
                if let provider {
                    switch provider.status {
                        case .online, .serving:
                            Text(Image(systemName: "circle.fill")).foregroundStyle(Color.green)
                        case .untrusted:
                            Text(Image(systemName: "circle.fill")).foregroundStyle(Color.yellow)
                    }
                } else {
                    Text(Image(systemName: "circle.fill")).foregroundStyle(Color.red)
                }
                
                Text(serialNo)
                if let provider {
                    Text(verbatim: "|")
                    Text(provider.chipName)
                }
            }
        }
    }
}

#Preview {
    DashboardTab()
        .environment(ContentViewModel())
}
