#if os(macOS)

import SwiftUI

struct ContentView_macOS: View {
    @Environment(LogsViewModel.self) private var logsViewModel
    @Environment(LocalServiceController.self) private var localServiceController
    
    @Bindable private var navigation = NavigationController.shared
    private let settings = Settings.shared
    
    var body: some View {
        NavigationSplitView {
            List(selection: $navigation.activeTab) {
                SidebarLink(value: .overview)
                SidebarLink(value: .earnings)
                if !settings.trackedMachineSerialNumbers.isEmpty {
                    Section {
                        ForEach(settings.trackedMachineSerialNumbers) { serialNo in
                            SidebarMachineLink(serialNo: serialNo)
                        }
                    } header: {
                        Text("Machines")
                    }
                }
                Section {
                    SidebarLoadTestingLink()
                    SidebarLink(value: .logs, badge: logsViewModel.unseenLogCount)
                } header: {
                    Text("Utilities")
                }
            }
        } detail: {
            Group {
                switch navigation.activeTab {
                    case .overview:
                        OverviewTab()
                    case .earnings:
                        EarningsTab()
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
            localServiceController.setup()
            localServiceController.startObservation()
        }
        .onDisappear() {
            logsViewModel.stopStreaming()
            localServiceController.stopObservation()
        }
    }
}

#Preview {
    ContentView_macOS()
        .environment(ContentViewModel())
        .environment(LogsViewModel())
}

#endif
