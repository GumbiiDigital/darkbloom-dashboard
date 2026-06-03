import SwiftUI
import Charts
import MapKit
import FiveKit

struct NetworkTab: View {
    @Environment(ContentViewModel.self) private var contentViewModel
    
    var body: some View {
        Form {
            if let stats = contentViewModel.stats {
                NetworkStatsSection(stats: stats)
                TrafficTimeSeriesSection(stats: stats)
                TokenDistributionSection(stats: stats)
                TrafficFlowSection(stats: stats)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    NetworkTab()
        .environment(ContentViewModel())
        .frame(minHeight: 600)
}
