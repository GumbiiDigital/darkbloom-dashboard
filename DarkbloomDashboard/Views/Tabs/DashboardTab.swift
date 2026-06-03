import SwiftUI
import FiveKit
import OpenAI

struct DashboardTab: View {
    @Environment(ContentViewModel.self) private var viewModel
    
    #if os(macOS)
    @Environment(LocalServiceController.self) private var localServiceController: LocalServiceController?
    #endif
    
    private let settings = Settings.shared
    
    var body: some View {
        Form {
            APIKeySection()
            
            #if os(macOS)
            if let localServiceController, localServiceController.darkbloomExists() {
                LocalDarkbloomSection(localServiceController: localServiceController)
            }
            #endif
            
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
    struct TrustExplanationButton: View {
        @State private var isShowingExplanation: Bool = false

        let trust: MachineTrustInfo

        var body: some View {
            Button {
                isShowingExplanation.toggle()
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.borderless)
            .help("Why trust is reduced")
            .popover(isPresented: $isShowingExplanation, arrowEdge: .trailing) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(trust.isTrusted ? "Full Trust" : "Reduced Trust")
                        .font(.headline)

                    if trust.reducedTrustReasons.isEmpty {
                        Text("This machine currently satisfies the tracked Darkbloom trust checks.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(trust.reducedTrustReasons) { reason in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(reason.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(reason.explanation)
                                    .foregroundStyle(.secondary)
                                Text(reason.recoveryAction)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(width: 360, alignment: .leading)
                .padding()
            }
        }
    }

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
    
    #if os(macOS)
    struct LocalDarkbloomSection: View {
        @Environment(ContentViewModel.self) private var contentViewModel
        
        @State private var isRestarting: Bool = false
        @State private var restartingStep: String?
        @State private var restartSelection: String = "all"
        @State private var remoteRestartUser: String = ""
        @State private var remoteRestartHost: String = ""
        
        let localServiceController: LocalServiceController
        
        private let settings = Settings.shared
        private let allRestartSelection = "all"

        private var restartableSerialNumbers: [String] {
            settings.trackedMachineSerialNumbers
        }

        private var isRemoteRestartSelection: Bool {
            let nonRemoteTargets: [String] = [
                allRestartSelection,
                localServiceController.currentMachineSerialNumber
            ].compactMap(\.self)
            return !nonRemoteTargets.contains(restartSelection)
        }
        
        private func restart(serialNumber: String) async {
            restartingStep = "Determining darkbloom location..."
            let localSerialNumber = localServiceController.currentMachineSerialNumber
            if serialNumber == localSerialNumber {
                guard let darkbloomPath = try? localServiceController.fetchDarkbloomLocation() else {
                    restartingStep = "Unable to find darkbloom."
                    try? await Task.sleep(for: .seconds(5))
                    return
                }

                restartingStep = "Stopping darkbloom service on this Mac..."
                try? localServiceController.stopDarkbloom(at: darkbloomPath)

                // Fetch network info (machine should be offline)
                if let apiKey = settings.apiKey {
                    try? await Task.sleep(for: .seconds(5))
                    try? await contentViewModel.update(apiKey: apiKey)
                }

                restartingStep = "Starting darkbloom service on this Mac..."
                try? localServiceController.startDarkbloom(at: darkbloomPath)
            } else if let target = settings.remoteRestartTargets[serialNumber] {
                restartingStep = "Restarting \(target.displayName) over SSH..."
                do {
                    try localServiceController.restartRemoteDarkbloom(target: target)
                } catch {
                    restartingStep = "Unable to restart \(target.displayName): \(error.localizedDescription)"
                    try? await Task.sleep(for: .seconds(8))
                    return
                }
            } else {
                restartingStep = "No restart route configured for \(serialNumber)."
                try? await Task.sleep(for: .seconds(5))
                return
            }

            // If there's no api key, we're done here
            guard let apiKey = settings.apiKey else {
                restartingStep = "Done."
                try? await Task.sleep(for: .seconds(5))
                return
            }
            
            restartingStep = "Waiting for provider to come back online..."
            let onlineCheckStartDate = Date.now
            while true {
                try? await Task.sleep(for: .seconds(5))
                try? await contentViewModel.update(apiKey: apiKey)
                if contentViewModel.machineInfo[serialNumber]?.trust.isOnline == true {
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
        }

        private func restartSelectedMachines() async {
            defer { restartingStep = nil }

            let serialNumbers: [String]
            if restartSelection == allRestartSelection {
                serialNumbers = restartableSerialNumbers
            } else {
                serialNumbers = [restartSelection]
            }

            guard !serialNumbers.isEmpty else {
                restartingStep = "No machines selected."
                try? await Task.sleep(for: .seconds(5))
                return
            }

            for serialNumber in serialNumbers {
                restartingStep = "Preparing \(label(for: serialNumber))..."
                await restart(serialNumber: serialNumber)
            }
        }

        private func label(for serialNumber: String) -> String {
            if let target = settings.remoteRestartTargets[serialNumber] {
                return "\(target.displayName) (\(serialNumber))"
            }
            if serialNumber == localServiceController.currentMachineSerialNumber {
                return "This Mac (\(serialNumber))"
            }
            return serialNumber
        }

        private func loadRemoteRestartFields(serialNumber: String) {
            guard serialNumber != allRestartSelection else {
                remoteRestartUser = ""
                remoteRestartHost = ""
                return
            }
            let target = settings.remoteRestartTargets[serialNumber]
            remoteRestartUser = target?.user ?? ""
            remoteRestartHost = target?.host ?? ""
        }

        private func saveRemoteRestartTarget() {
            let trimmedUser = remoteRestartUser.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedHost = remoteRestartHost.trimmingCharacters(in: .whitespacesAndNewlines)
            guard isRemoteRestartSelection, !trimmedUser.isEmpty, !trimmedHost.isEmpty else { return }
            settings.setRemoteRestartTarget(
                MachineRestartTarget(
                    serialNumber: restartSelection,
                    displayName: restartSelection,
                    user: trimmedUser,
                    host: trimmedHost
                )
            )
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

                Picker("Restart Target", selection: $restartSelection) {
                    Text("All tracked machines").tag(allRestartSelection)
                    ForEach(restartableSerialNumbers, id: \.self) { serialNumber in
                        Text(label(for: serialNumber)).tag(serialNumber)
                    }
                }

                if isRemoteRestartSelection {
                    LabeledContent {
                        TextField("macOS account name", text: $remoteRestartUser)
                            .textFieldStyle(.roundedBorder)
                    } label: {
                        Text("SSH User")
                    }

                    LabeledContent {
                        TextField("Tailscale host or IP", text: $remoteRestartHost)
                            .textFieldStyle(.roundedBorder)
                    } label: {
                        Text("SSH Host")
                    }

                    HStack {
                        Spacer()
                        Button("Save SSH Target") {
                            saveRemoteRestartTarget()
                        }
                        .disabled(
                            remoteRestartUser.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            remoteRestartHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }
                }
                
                if let restartingStep {
                    LabeledContent {
                        Text(restartingStep)
                    } label: {
                        Text("Restart Status")
                    }
                    .transition(.opacity)
                }
            } header: {
                HStack(alignment: .bottom) {
                    Label("Darkbloom Process", systemImage: "server.rack")
                    Spacer()
                    Button {
                        isRestarting = true
                        Task {
                            await restartSelectedMachines()
                            isRestarting = false
                        }
                    } label: {
                        Text("Restart")
                    }
                    .disabled(isRestarting)
                }
            }
            .animation(.interactiveSpring, value: restartingStep)
            .onAppear {
                loadRemoteRestartFields(serialNumber: restartSelection)
            }
            .onChange(of: restartSelection) { _, serialNumber in
                loadRemoteRestartFields(serialNumber: serialNumber)
            }
        }
    }
    #endif
    
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
                                if !machine.trust.isTrusted {
                                    TrustExplanationButton(trust: machine.trust)
                                }
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
                HStack(alignment: .bottom) {
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
