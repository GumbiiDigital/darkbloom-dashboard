import SwiftUI
import FiveKit

struct LogsTab: View {
    @Environment(LogsViewModel.self) private var viewModel
    
    var body: some View {
        Form {
            Section {
                if viewModel.logs.isEmpty {
                    Text("Waiting for logs to come in...")
                } else {
                    ForEach(viewModel.logs.sorted(by: \.date, ascending: false)) { entry in
                        LogEntryView(entry: entry)
                    }
                }
            } header: {
                HStack(alignment: .bottom) {
                    Text("Darkbloom Logs")
                    Spacer()
                    LabeledPill {
                        Text("LIVE")
                    } label: {
                        Text(Image(systemName: "record.circle"))
                            .foregroundStyle(Color.green)
                            .phaseAnimator([false, true]) { placeholder, phase in
                                placeholder.opacity(phase ? 1 : 0.75)
                            }
                    }
                    .font(.caption)
                    .controlSize(.small)
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct LogEntryView: View {
    let entry: DarkbloomLogEntry
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(entry.date, style: Text.DateStyle.date)
                Text(entry.date, style: Text.DateStyle.time)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            Text(entry.message)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    LogsTab()
        .environment(LogsViewModel())
}
