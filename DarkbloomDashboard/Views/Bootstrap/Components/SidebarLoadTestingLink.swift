import SwiftUI
import FiveKit

struct SidebarLoadTestingLink: View {
    @Environment(LoadTestingViewModel.self) private var viewModel
    
    var body: some View {
        let value = SidebarTab.loadGenerator
        NavigationLink(value: value) {
            HStack {
                Label(value.title, systemImage: value.systemImage)
                Spacer()
                if viewModel.inProgress {
                    ProgressView()
                        .controlSize(.small)
                        .transition(.opacity)
                }
            }
            .animation(.smooth, value: viewModel.inProgress)
        }
    }
}

#Preview {
    List {
        SidebarLoadTestingLink()
            .environment(LoadTestingViewModel())
    }
    .listStyle(.sidebar)
}
