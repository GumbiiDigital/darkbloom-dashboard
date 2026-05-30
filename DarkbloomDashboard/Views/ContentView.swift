import SwiftUI
import SwiftData
import FiveKit
import OpenAI

enum SidebarTab: String, CaseIterable, Hashable, Identifiable {
    case overview
    case loadGenerator
    case logs

    var id: String { rawValue }

    var title: String {
        switch self {
            case .overview: "Overview"
            case .loadGenerator: "Load Generator"
            case .logs: "Logs"
        }
    }

    var systemImage: String {
        switch self {
            case .overview: "app"
            case .loadGenerator: "bolt.fill"
            case .logs: "text.page"
        }
    }
}

struct SidebarLink: View {
    let value: SidebarTab
    
    var body: some View {
        NavigationLink(value: value) {
            Label(value.title, systemImage: value.systemImage)
        }
    }
}

struct ContentView: View {
    @State private var activeTab: SidebarTab = .overview
    
    @State private var logsViewModel = LogsViewModel()
    
    var body: some View {
        NavigationSplitView {
            List(selection: $activeTab) {
                SidebarLink(value: .overview)
                SidebarLink(value: .loadGenerator)
                SidebarLink(value: .logs)
            }
        } detail: {
            switch activeTab {
                case .overview:
                    DashboardTab()
                case .loadGenerator:
                    LoadGeneratorTab()
                case .logs:
                    LogsTab()
                        .environment(logsViewModel)
            }
        }
        .onAppear {
            logsViewModel.startStreaming()
        }
        .onDisappear() {
            logsViewModel.stopStreaming()
        }
    }
}

#Preview {
    ContentView()
}
