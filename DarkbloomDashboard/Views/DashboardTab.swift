import SwiftUI
import FiveKit
import OpenAI

struct DashboardTab: View {
    @AppStorage("darkbloom_api_key_locked") private var apiKeyLocked: Bool = false
    @AppStorage("tracked_machines") private var rawTrackedMachines: String?
    
    @State private var viewModel = ContentViewModel()
    
    @State private var showAddMachineAlert: Bool = false
    @State private var newMachineSerialNumber: String = ""
    
    @Bindable private var settings = Settings.shared
    
    private var trackedMachines: Binding<[String]> {
        Binding(
            get: { rawTrackedMachines?.split(separator: ",").map(String.init) ?? [] },
            set: { rawTrackedMachines = $0.removingDuplicates().joined(separator: ",") }
        )
    }
    
    var body: some View {
        Form {
            Section {
                LabeledContent {
                    if apiKeyLocked {
                        Text("Hidden")
                            .foregroundStyle(.secondary)
                    } else {
                        SecureField("API Key", text: $settings.apiKey ?? "")
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
                ForEach(trackedMachines.wrappedValue) { serialNo in
                    let provider = viewModel.attestations?.providers.first { $0.serialNumber == serialNo }
                    let providerStats = provider.flatMap { provider in
                        viewModel.stats?.providers.first { $0.id == provider.providerId }
                    }
                    MachineInfoView(serialNo: serialNo, provider: provider, stats: providerStats)
                }
                .onDelete { indexSet in
                    trackedMachines.wrappedValue.remove(atOffsets: indexSet)
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
        }
        .formStyle(.grouped)
        .task(id: settings.apiKey) {
            guard let apiKey = settings.apiKey else { return }
            do {
                try await viewModel.update(apiKey: apiKey)
            } catch {
                print(error)
            }
        }
        .alert("Add Machine", isPresented: $showAddMachineAlert) {
            TextField("Serial Number", text: $newMachineSerialNumber)
            
            Button("Save") {
                trackedMachines.wrappedValue.append(newMachineSerialNumber)
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
        VStack(alignment: .leading) {
            HStack {
                Text(serialNo).bold()
                Spacer()
                if let provider {
                    Text(provider.chipName)
                }
            }
            
            if let provider {
                VStack(alignment: .leading) {
                    LabeledContent {
                        HStack {
                            switch provider.status {
                                case .online:
                                    Image(systemName: "circle.fill")
                                        .foregroundStyle(.green)
                                    Text("Online")
                                case .serving:
                                    Image(systemName: "cpu")
                                        .foregroundStyle(.green)
                                    Text("Serving")
                                case .untrusted:
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundStyle(.red)
                                    Text("Untrusted")
                            }
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(Color.systemFill)
                        .clipShape(.capsule)
                    } label: {
                        Text("Status")
                    }
                    
                    LabeledContent {
                        HStack {
                            switch provider.trustLevel {
                                case .hardware:
                                    Image(systemName: "macbook.badge.shield.checkmark")
                                        .foregroundStyle(.green)
                                    Text("Hardware")
                                case .selfSigned:
                                    Image(systemName: "key.shield.fill")
                                        .foregroundStyle(.yellow)
                                    Text("Self-Signed")
                                case .none:
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundStyle(.red)
                                    Text("None")
                            }
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(Color.systemFill)
                        .clipShape(.capsule)
                    } label: {
                        Text("Trust Level")
                    }
                    
                    LabeledContent {
                        HStack {
                            switch provider.isTrusted {
                                case true:
                                    Image(systemName: "lock.shield.fill")
                                        .foregroundStyle(.green)
                                    Text("Full Trust")
                                case false:
                                    Image(systemName: "shield.slash.fill")
                                        .foregroundStyle(.yellow)
                                    Text("Reduced Trust")
                            }
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(Color.systemFill)
                        .clipShape(.capsule)
                    } label: {
                        Text("Trust Indicator")
                    }
                }
            } else {
                Text("This machine is currently offline.")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondarySystemBackground)
        .clipShape(.rect(cornerRadius: 12))
    }
}

#Preview {
    DashboardTab()
}
