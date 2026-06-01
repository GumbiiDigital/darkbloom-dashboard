import SwiftUI
import FiveKit

struct LoadGeneratorTab: View {
    @State private var loadTest = LoadTestingViewModel()
    
    private let settings = Settings.shared
    
    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("Requests", value: $loadTest.requestsToSend, format: .number)
                    
                    Button {
                        guard let apiKey = settings.apiKey else { return }
                        Task {
                            try? await loadTest.run(apiKey: apiKey)
                        }
                    } label: {
                        Text("Run")
                    }
                    .disabled(loadTest.inProgress || settings.apiKey == nil)
                }
                
                HStack {
                    if loadTest.inProgress {
                        ProgressView().controlSize(.small)
                    }
                    
                    Spacer()
                    
                    LabeledPill {
                        Text(loadTest.requestsInFlight, format: .number)
                    } label: {
                        Text("Inflight")
                    }
                    
                    LabeledPill(.positive) {
                        Text(loadTest.requestsDone, format: .number)
                    } label: {
                        Text("Succeeded")
                    }
                    
                    LabeledPill(.negative) {
                        Text(loadTest.requestsFailed, format: .number)
                    } label: {
                        Text("Failed")
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    LoadGeneratorTab()
}
