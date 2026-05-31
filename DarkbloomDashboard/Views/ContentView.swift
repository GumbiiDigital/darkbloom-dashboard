import SwiftUI
import SwiftData
import FiveKit
import OpenAI

enum SidebarTab: Hashable, Identifiable {
    case overview
    case machine(String)
    case loadGenerator
    case logs

    var id: String {
        switch self {
            case .overview: "overview"
            case .machine(let id): "machine-\(id)"
            case .loadGenerator: "load-generator"
            case .logs: "logs"
        }
    }

    var title: String {
        switch self {
            case .overview: "Overview"
            case .machine(let id): id
            case .loadGenerator: "Load Generator"
            case .logs: "Log Viewer"
        }
    }

    var systemImage: String {
        switch self {
            case .overview: "app"
            case .loadGenerator: "bolt.fill"
            case .machine: "macstudio"
            case .logs: "text.page"
        }
    }
}

struct SidebarLink: View {
    let value: SidebarTab
    
    var body: some View {
        NavigationLink(value: value) {
            Label(value.title, systemImage: value.systemImage)
        }
    }
}

struct ContentView: View {
    @State private var activeTab: SidebarTab = .overview
    
    @State private var logsViewModel = LogsViewModel()
    
    var body: some View {
        NavigationSplitView {
            List(selection: $activeTab) {
                SidebarLink(value: .overview)
                if !Settings.shared.trackedMachineSerialNumbers.isEmpty {
                    Section {
                        ForEach(Settings.shared.trackedMachineSerialNumbers) { serialNo in
                            SidebarLink(value: .machine(serialNo))
                        }
                    } header: {
                        Text("Machines")
                    }
                }
                Section {
                    SidebarLink(value: .loadGenerator)
                    SidebarLink(value: .logs)
                } header: {
                    Text("Utilities")
                }
            }
        } detail: {
            switch activeTab {
                case .overview:
                    DashboardTab()
                case .machine(let serialNo):
                    EmptyView()
                case .loadGenerator:
                    LoadGeneratorTab()
                case .logs:
                    LogsTab()
                        .environment(logsViewModel)
            }
        }
        .onAppear {
            logsViewModel.startStreaming()
        }
        .onDisappear() {
            logsViewModel.stopStreaming()
        }
    }
}

#Preview {
    ContentView()
}
