import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var contentViewModel = ContentViewModel()
    @State private var earningsViewModel = EarningsViewModel()
    @State private var logsViewModel = LogsViewModel()
    
    private let settings = Settings.shared
    
    @ViewBuilder private var platformContent: some View {
        #if os(macOS)
        ContentView_macOS()
        #elseif os(iOS)
        ContentView_iOS()
        #else
        #error("Unsupported platform.")
        #endif
    }
    
    var body: some View {
        platformContent
            .environment(contentViewModel)
            .environment(earningsViewModel)
            .environment(logsViewModel)
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
