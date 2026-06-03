import SwiftUI
import FiveKit

struct OverviewTab: View {
    @Environment(APIDataController.self) private var viewModel
    
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
            
            if let stats = viewModel.stats {
                NetworkOverviewSection(stats: stats)
            }
            
            TrackedMachineListSection()
            
            ForEach(settings.trackedMachineSerialNumbers) { serialNo in
                MachineInfoSection(serialNo: serialNo, machine: viewModel.machineInfo[serialNo])
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    #if os(macOS)
    OverviewTab()
        .environment(APIDataController())
        .environment(LocalServiceController())
    #else
    OverviewTab()
        .environment(APIDataController())
    #endif
}
