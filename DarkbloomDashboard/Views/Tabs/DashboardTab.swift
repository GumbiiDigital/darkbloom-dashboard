import SwiftUI
import FiveKit
import OpenAI
import IOKit

struct DashboardTab: View {
    @Environment(ContentViewModel.self) private var viewModel
    @Environment(LocalServiceController.self) private var localServiceController: LocalServiceController?
    
    private let settings = Settings.shared
    
    var body: some View {
        Form {
            APIKeySection()
            
            if let localServiceController, localServiceController.darkbloomExists() {
                LocalDarkbloomSection(localServiceController: localServiceController)
            }
            
            NetworkOverviewSection()
            TrackedMachineListSection()
            
            ForEach(settings.trackedMachineSerialNumbers) { serialNo in
                let machine = viewModel.machineInfo[serialNo]
                MachineInfoSection(serialNo: serialNo, machine: machine)
            }
        }
        .formStyle(.grouped)
    }
}

extension DashboardTab {
    struct APIKeySection: View {
        @AppStorage("darkbloom_api_key_locked") private var apiKeyLocked: Bool = false
        @Bindable private var settings = Settings.shared
        
        var body: some View {
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
        }
    }
    
    struct LocalDarkbloomSection: View {
        @Environment(ContentViewModel.self) private var contentViewModel
        
        @State private var isRestarting: Bool = false
        @State private var restartingStep: String?
        
        let localServiceController: LocalServiceController
        
        private let settings = Settings.shared
        
        private func getSerialNumber() -> String? {
            let platformExpert = IOServiceGetMatchingService(
                kIOMainPortDefault,
                IOServiceMatching("IOPlatformExpertDevice")
            )
            guard platformExpert != 0 else { return nil }
            defer {
                IOObjectRelease(platformExpert)
            }
            guard let serial = IORegistryEntryCreateCFProperty(
                platformExpert,
                "IOPlatformSerialNumber" as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue() as? String else {
                return nil
            }
            return serial
        }
        
        private func restart() async {
            defer { restartingStep = nil }
            
            restartingStep = "Determining darkbloom location..."
            guard let darkbloomPath = try? localServiceController.fetchDarkbloomLocation() else {
                restartingStep = "Unable to find darkbloom."
                try? await Task.sleep(for: .seconds(5))
                return
            }
            
            restartingStep = "Stopping darkbloom service..."
            try? localServiceController.stopDarkbloom(at: darkbloomPath)
            
            // Fetch network info (machine should be offline)
            if let apiKey = settings.apiKey {
                try? await Task.sleep(for: .seconds(5))
                try? await contentViewModel.update(apiKey: apiKey)
            }
            
            restartingStep = "Starting darkbloom service..."
            try? localServiceController.startDarkbloom(at: darkbloomPath)
            
            // If there's no api key, we're done here
            guard let apiKey = settings.apiKey else {
                restartingStep = "Done."
                try? await Task.sleep(for: .seconds(5))
                return
            }
            
            restartingStep = "Getting serial number..."
            guard let serialNumber = getSerialNumber() else {
                restartingStep = "Unable to obtain serial number."
                try? await Task.sleep(for: .seconds(5))
                return
            }
            
            restartingStep = "Waiting for provider to come back online..."
            let onlineCheckStartDate = Date.now
            while true {
                try? await Task.sleep(for: .seconds(5))
                try? await contentViewModel.update(apiKey: apiKey)
                if contentViewModel.machineInfo[serialNumber] != nil {
                    break
                }
                if onlineCheckStartDate.timeIntervalUntilNow > 120 {
                    restartingStep = "Timeout while waiting for provider to come back online."
                    try? await Task.sleep(for: .seconds(5))
                    return
                }
            }
            
            restartingStep = "Waiting for provider to become trusted..."
            let trustCheckStartDate = Date.now
            while true {
                try? await Task.sleep(for: .seconds(5))
                try? await contentViewModel.update(apiKey: apiKey)
                if let machine = contentViewModel.machineInfo[serialNumber], machine.trust.isTrusted {
                    break
                }
                if trustCheckStartDate.timeIntervalUntilNow > 120 {
                    restartingStep = "Timeout while waiting for provider to become trusted."
                    try? await Task.sleep(for: .seconds(5))
                    return
                }
            }
            
            restartingStep = "Warming up models..."
            try? await contentViewModel.warmup(serialNumber: serialNumber)
            
            restartingStep = "Done"
            try? await Task.sleep(for: .seconds(5))
            restartingStep = nil
        }
        
        var body: some View {
            Section {
                LabeledContent {
                    if let isRunning = localServiceController.processIsRunning {
                        Text(isRunning ? "Running" : "Stopped")
                    } else {
                        ProgressView().controlSize(.small)
                    }
                } label: {
                    Text("Process Status")
                }
                .animation(.interactiveSpring, value: localServiceController.processIsRunning)
                
                if let restartingStep {
                    LabeledContent {
                        Text(restartingStep)
                    } label: {
                        Text("Restart Status")
                    }
                    .transition(.opacity)
                }
            } header: {
                HStack {
                    Label("Darkbloom Process", systemImage: "server.rack")
                    Spacer()
                    Button {
                        isRestarting = true
                        Task {
                            await restart()
                            isRestarting = false
                        }
                    } label: {
                        Text("Restart")
                    }
                    .disabled(isRestarting)
                }
            }
            .animation(.interactiveSpring, value: restartingStep)
        }
    }
    
    struct NetworkOverviewSection: View {
        @Environment(ContentViewModel.self) private var viewModel
        
        var body: some View {
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
        }
    }
    
    struct TrackedMachineListSection: View {
        @Environment(ContentViewModel.self) private var viewModel
        
        @State private var showAddMachineAlert: Bool = false
        @State private var newMachineSerialNumber: String = ""
        
        private let settings = Settings.shared
        
        var body: some View {
            Section {
                if settings.trackedMachineSerialNumbers.isEmpty {
                    Text("You haven't tracked any machines yet.")
                } else {
                    ForEach(settings.trackedMachineSerialNumbers) { serialNo in
                        HStack(alignment: .firstTextBaseline) {
                            Text(serialNo)
                            Spacer()
                            if let machine = viewModel.machineInfo[serialNo] {
                                HStack(alignment: .firstTextBaseline) {
                                    switch machine.trust.isTrusted {
                                        case true:
                                            Text(Image(systemName: "lock.shield.fill"))
                                            Text("Full Trust")
                                        case false:
                                            Text(Image(systemName: "shield.slash.fill"))
                                            Text("Reduced Trust")
                                    }
                                }
                                .foregroundStyle(machine.trust.isTrusted ? Color.secondary : Color.yellow)
                            }
                        }
                        .contentShape(.rect)
                        .contextMenu {
                            if #available(iOS 26, macOS 26, *) {
                                Button(role: .destructive) {
                                    settings.trackedMachineSerialNumbers.removeAll(subject: serialNo)
                                }
                            } else {
                                Button("Delete", role: .destructive) {
                                    settings.trackedMachineSerialNumbers.removeAll(subject: serialNo)
                                }
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
            .alert("Add Machine", isPresented: $showAddMachineAlert) {
                TextField("Serial Number", text: $newMachineSerialNumber)
                
                Button("Save") {
                    settings.trackedMachineSerialNumbers.append(newMachineSerialNumber)
                    newMachineSerialNumber = ""
                }
                
                if #available(iOS 26, macOS 26, *) {
                    Button(role: .cancel) {
                        newMachineSerialNumber = ""
                    }
                } else {
                    Button("Cancel", role: .cancel) {
                        newMachineSerialNumber = ""
                    }
                }
            }
        }
    }
    
    struct MachineInfoSection: View {
        let serialNo: String
        let machine: MachineInfo?
        
        var body: some View {
            Section {
                if let machine {
                    LabeledContent {
                        HStack(alignment: .firstTextBaseline) {
                            switch machine.trust.status {
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
                            switch machine.trust.trustLevel {
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
                    if let machine {
                        switch machine.trust.status {
                            case .online, .serving:
                                Text(Image(systemName: "circle.fill")).foregroundStyle(Color.green)
                            case .untrusted:
                                Text(Image(systemName: "circle.fill")).foregroundStyle(Color.yellow)
                        }
                    } else {
                        Text(Image(systemName: "circle.fill")).foregroundStyle(Color.red)
                    }
                    
                    Text(serialNo)
                    if let machine {
                        Text(verbatim: "|")
                        Text(machine.hardware.modelDisplayName)
                    }
                }
            }
        }
    }
}

#Preview {
    DashboardTab()
        .environment(ContentViewModel())
}
