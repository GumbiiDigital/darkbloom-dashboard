#if os(iOS)

import SwiftUI

struct ContentView_iOS: View {
    @Bindable private var navigation = NavigationController.shared
    private let settings = Settings.shared
    
    var body: some View {
        TabView(selection: $navigation.activeTab) {
            Tab(
                SidebarTab.overview.title,
                systemImage: SidebarTab.overview.systemImage,
                value: .overview
            ) {
                NavigationStack {
                    OverviewTab()
                        .navigationTitle(SidebarTab.overview.title)
                }
            }
            Tab(
                SidebarTab.earnings.title,
                systemImage: SidebarTab.earnings.systemImage,
                value: .earnings
            ) {
                NavigationStack {
                    EarningsTab()
                        .navigationTitle(SidebarTab.earnings.title)
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
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    ContentView_iOS()
        .environment(ContentViewModel())
}

#endif
