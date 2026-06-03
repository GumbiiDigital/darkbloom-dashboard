import SwiftUI
import Charts
import FiveKit

extension NetworkTab {
    struct TrafficTimeSeriesSection: View {
        let stats: DarkbloomStats
        
        private var tokenSeries: [TokenSeriesEntry] {
            stats.timeSeries.flatMap { entry in
                [
                    TokenSeriesEntry(timestamp: entry.timestamp, kind: .prompt, tokens: entry.promptTokens),
                    TokenSeriesEntry(timestamp: entry.timestamp, kind: .completion, tokens: entry.completionTokens),
                ]
            }
        }
        
        var body: some View {
            Section {
                HStack {
                    Chart(stats.timeSeries) { entry in
                        LineMark(x: .value("timestamp", entry.timestamp, unit: .minute), y: .value("requests", entry.requests))
                    }
                    .padding(8)
                    .background(Color.systemFill, in: .rect(cornerRadius: 8))
                    Chart(tokenSeries) { entry in
                        BarMark(
                            x: .value("timestamp", entry.timestamp, unit: .minute),
                            y: .value("tokens", entry.tokens),
                            stacking: .standard
                        )
                        .foregroundStyle(by: .value("token kind", entry.kind.label))
                    }
                    .chartForegroundStyleScale([
                        TokenSeriesEntry.Kind.prompt.label: Color.accent,
                        TokenSeriesEntry.Kind.completion.label: Color.green,
                    ])
                    .padding(8)
                    .background(Color.systemFill, in: .rect(cornerRadius: 8))
                }
            } header: {
                HStack {
                    VStack(alignment: .leading) {
                        let total = stats.timeSeries.map(\.requests).reduce(0, +)
                        let peak = stats.timeSeries.map(\.requests).max() ?? 0
                        Text("Requests / Minute")
                        Text("\(total) total / \(peak) peak")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading) {
                        let total = stats.timeSeries.map(\.totalTokens).reduce(0, +)
                        let peak = stats.timeSeries.map(\.totalTokens).max() ?? 0
                        Text("Tokens / Minute")
                        Text("\(total) total / \(peak) peak")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        
        private struct TokenSeriesEntry: Identifiable {
            let timestamp: Date
            let kind: Kind
            let tokens: Int
            
            var id: String {
                "\(timestamp.formatted(.iso8601))-\(kind.rawValue)"
            }
            
            enum Kind: String {
                case prompt
                case completion
                
                var label: String {
                    switch self {
                        case .prompt: "Prompt"
                        case .completion: "Completion"
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var viewModel = ContentViewModel()
    
    Form {
        if let stats = viewModel.stats {
            NetworkTab.TrafficTimeSeriesSection(stats: stats)
        }
    }
    .formStyle(.grouped)
    .environment(viewModel)
}
