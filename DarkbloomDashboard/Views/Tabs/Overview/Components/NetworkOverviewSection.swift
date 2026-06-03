import SwiftUI
import FiveKit

extension OverviewTab {
    struct NetworkOverviewSection: View {
        @Environment(ContentViewModel.self) private var viewModel
        
        let stats: DarkbloomStats
        
        var body: some View {
            Section {
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
            } header: {
                Label("Network", systemImage: "network")
            }
        }
    }
}

#Preview {
    @Previewable @State var viewModel = ContentViewModel()
    
    Form {
        if let stats = viewModel.stats {
            OverviewTab.NetworkOverviewSection(stats: stats)
                .environment(viewModel)
        }
    }
    .formStyle(.grouped)
}
