import SwiftUI
import SwiftData
import FiveKit
import OpenAI

enum SidebarTab: Hashable, Identifiable {
    case overview
    case machine(String)
    case machines
    case loadGenerator
    case logs

    var id: String {
        switch self {
            case .overview: "overview"
            case .machine(let id): "machine-\(id)"
            case .machines: "machines"
            case .loadGenerator: "load-generator"
            case .logs: "logs"
        }
    }

    var title: String {
        switch self {
            case .overview: "Overview"
            case .machine(let id): id
            case .machines: "Machines"
            case .loadGenerator: "Load Generator"
            case .logs: "Log Viewer"
        }
    }

    var systemImage: String {
        switch self {
            case .overview: "app"
            case .machine: "macstudio"
            case .machines: "macstudio"
            case .loadGenerator: "bolt.fill"
            case .logs: "text.page"
        }
    }
}

struct SidebarLink: View {
    let value: SidebarTab
    let badge: Int?
    
    init(value: SidebarTab, badge: Int? = nil) {
        self.value = value
        self.badge = badge
    }
    
    var body: some View {
        NavigationLink(value: value) {
            Label(value.title, systemImage: value.systemImage)
                .badge(badge ?? 0)
                .badgeProminence(.increased)
        }
    }
}

struct ContentView: View {
    @State private var contentViewModel = ContentViewModel()
    @State private var logsViewModel = LogsViewModel()
    
    @Bindable private var navigation = NavigationViewModel.shared
    private let settings = Settings.shared
    
    #if os(macOS)
    @ViewBuilder var sidebarNavigation: some View {
        NavigationSplitView {
            List(selection: $navigation.activeTab) {
                SidebarLink(value: .overview)
                if !settings.trackedMachineSerialNumbers.isEmpty {
                    Section {
                        ForEach(settings.trackedMachineSerialNumbers) { serialNo in
                            SidebarLink(value: .machine(serialNo))
                        }
                    } header: {
                        Text("Machines")
                    }
                }
                Section {
                    SidebarLink(value: .loadGenerator)
                    SidebarLink(value: .logs, badge: logsViewModel.unseenLogCount)
                } header: {
                    Text("Utilities")
                }
            }
        } detail: {
            Group {
                switch navigation.activeTab {
                    case .overview:
                        DashboardTab()
                    case .machine(let serialNo):
                        MachineDetailTab(serialNo: serialNo)
                    case .machines:
                        EmptyView() // not supported on macOS
                    case .loadGenerator:
                        LoadGeneratorTab()
                    case .logs:
                        LogsTab()
                }
            }
            .navigationTitle(navigation.activeTab.title)
            .environment(navigation)
            .environment(contentViewModel)
            .environment(logsViewModel)
        }
        .onAppear {
            logsViewModel.startStreaming()
        }
        .onDisappear() {
            logsViewModel.stopStreaming()
        }
    }
    #else
    @ViewBuilder private var tabNavigation: some View {
        TabView(selection: $navigation.activeTab) {
            Tab(
                SidebarTab.overview.title,
                systemImage: SidebarTab.overview.systemImage,
                value: .overview
            ) {
                NavigationStack {
                    DashboardTab()
                        .navigationTitle(SidebarTab.overview.title)
                }
            }
            Tab(
                SidebarTab.machines.title,
                systemImage: SidebarTab.machines.systemImage,
                value: .machines
            ) {
                NavigationStack {
                    MachineListTab()
                        .navigationTitle(SidebarTab.machines.title)
                }
            }
        }
        .environment(navigation)
        .environment(contentViewModel)
        .environment(logsViewModel)
    }
    #endif
    
    @ViewBuilder private var content: some View {
        #if os(macOS)
        sidebarNavigation
        #else
        tabNavigation
        #endif
    }
    
    var body: some View {
        content
            .onChange(of: settings.apiKey) {
                guard let apiKey = settings.apiKey else { return }
                Task {
                    do {
                        try await contentViewModel.update(apiKey: apiKey)
                    } catch {
                        print(error)
                    }
                }
            }
    }
}

#Preview {
    ContentView()
}
