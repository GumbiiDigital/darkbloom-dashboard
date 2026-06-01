import SwiftUI

struct EarningsTab: View {
    @Environment(ContentViewModel.self) private var contentViewModel
    @Environment(EarningsViewModel.self) private var earningsViewModel
    
    var body: some View {
        Form {
            Section {
                if let balance = contentViewModel.balance {
                    Text(balance.formatted).font(.largeTitle)
                } else {
                    HStack {
                        ProgressView().controlSize(.small)
                        Text("Fetching balances...")
                    }
                }
            } header: {
                Text("Account Balance")
            }
            
            Section {
                if let projectedEarnings = earningsViewModel.projectedEarnings {
                    LabeledContent {
                        Text(projectedEarnings.projectedEarnings24h.formatted(.currency(code: "USD")))
                    } label: {
                        Text("Earnings / Day")
                    }
                    LabeledContent {
                        Text(projectedEarnings.projectedEarningsPerWeek.formatted(.currency(code: "USD")))
                    } label: {
                        Text("Earnings / Week")
                    }
                    LabeledContent {
                        Text(projectedEarnings.projectedEarningsPerMonth.formatted(.currency(code: "USD")))
                    } label: {
                        Text("Earnings / Month")
                    }
                } else {
                    Text("Collecting data... Check back in a few minutes.")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Projected Earnings")
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    EarningsTab()
        .environment(ContentViewModel())
}
