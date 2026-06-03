import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var dataController = APIDataController()
    @State private var earningsController = EarningsViewModel()
    
    #if os(macOS)
    @State private var loadTestingController = LoadTestingController()
    @State private var localServiceController = LocalServiceController()
    @State private var localLogController = LocalLogController()
    #endif
    
    private let settings = Settings.shared
    
    @ViewBuilder private var platformContent: some View {
        Group {
            #if os(macOS)
            ContentView_macOS()
                .environment(localServiceController)
                .environment(loadTestingController)
                .environment(localLogController)
            #elseif os(iOS)
            ContentView_iOS()
            #else
            #error("Unsupported platform.")
            #endif
        }
        .environment(dataController)
        .environment(earningsController)
    }
    
    var body: some View {
        platformContent
            .task(id: dataController.balanceChanges) {
                await earningsController.calculateProjections(basedOn: dataController.balanceChanges)
            }
            .onChange(of: settings.apiKey) {
                guard let apiKey = settings.apiKey else { return }
                Task {
                    do {
                        try await dataController.update(apiKey: apiKey)
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
