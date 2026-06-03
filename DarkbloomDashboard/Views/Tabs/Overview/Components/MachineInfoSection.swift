import SwiftUI
import FiveKit

extension OverviewTab {
    struct MachineInfoSection: View {
        let serialNo: String
        let machine: MachineInfo?
        
        var body: some View {
            Section {
                if let machine {
                    LabeledContent {
                        HStack(alignment: .firstTextBaseline) {
                            switch machine.trust.status {
                                case .online:
                                    Text(Image(systemName: "checkmark.circle"))
                                    Text("Online")
                                case .serving:
                                    Text(Image(systemName: "checkmark.circle.fill"))
                                    Text("Serving")
                                case .untrusted:
                                    Text(Image(systemName: "exclamationmark.triangle"))
                                    Text("Untrusted")
                            }
                        }
                    } label: {
                        Text("Status")
                    }
                    
                    LabeledContent {
                        HStack(alignment: .firstTextBaseline) {
                            switch machine.trust.trustLevel {
                                case .hardware:
                                    Text(Image(systemName: "macbook.badge.shield.checkmark"))
                                    Text("Hardware")
                                case .selfSigned:
                                    Text(Image(systemName: "key.shield.fill"))
                                    Text("Self-Signed")
                                case .none:
                                    Text(Image(systemName: "exclamationmark.triangle"))
                                    Text("None")
                            }
                        }
                    } label: {
                        Text("Trust Level")
                    }
                } else {
                    Text("This machine is currently offline.")
                }
            } header: {
                HStack(alignment: .bottom) {
                    if let machine {
                        switch machine.trust.status {
                            case .online, .serving:
                                Text(Image(systemName: "circle.fill")).foregroundStyle(Color.green)
                            case .untrusted:
                                Text(Image(systemName: "circle.fill")).foregroundStyle(Color.yellow)
                        }
                    } else {
                        Text(Image(systemName: "circle.fill")).foregroundStyle(Color.red)
                    }
                    
                    Text(serialNo)
                    if let machine {
                        Text(verbatim: "|")
                        Text(machine.hardware.modelDisplayName)
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var viewModel = APIDataController()
    
    Form {
        OverviewTab.MachineInfoSection(
            serialNo: "NJD6MGW279",
            machine: viewModel.machineInfo["NJD6MGW279"]
        )
        .environment(viewModel)
    }
    .formStyle(.grouped)
}
