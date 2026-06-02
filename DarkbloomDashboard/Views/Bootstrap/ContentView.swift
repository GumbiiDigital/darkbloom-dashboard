import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var contentViewModel = ContentViewModel()
    @State private var earningsViewModel = EarningsViewModel()
    
    #if os(macOS)
    @State private var loadTestingViewModel = LoadTestingViewModel()
    @State private var localServiceController = LocalServiceController()
    @State private var logsViewModel = LogsViewModel()
    #endif
    
    private let settings = Settings.shared
    
    @ViewBuilder private var platformContent: some View {
        Group {
            #if os(macOS)
            ContentView_macOS()
                .environment(localServiceController)
                .environment(loadTestingViewModel)
                .environment(logsViewModel)
            #elseif os(iOS)
            ContentView_iOS()
            #else
            #error("Unsupported platform.")
            #endif
        }
        .environment(contentViewModel)
        .environment(earningsViewModel)
    }
    
    var body: some View {
        platformContent
            .onChange(of: contentViewModel.balanceChanges) {
                earningsViewModel.calculateProjections(basedOn: contentViewModel.balanceChanges)
            }
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
