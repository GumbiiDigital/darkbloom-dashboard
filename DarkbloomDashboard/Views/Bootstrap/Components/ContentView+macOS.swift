#if os(macOS)

import SwiftUI

struct ContentView_macOS: View {
    @Environment(LogsViewModel.self) private var logsViewModel
    
    @Bindable private var navigation = NavigationController.shared
    private let settings = Settings.shared
    
    var body: some View {
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
    ContentView_macOS()
        .environment(ContentViewModel())
        .environment(LogsViewModel())
}

#endif
