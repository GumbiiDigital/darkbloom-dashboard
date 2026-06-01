import Foundation

enum SidebarTab: Hashable, Identifiable {
    case overview
    case machine(String)
    case machines
    case loadGenerator
    case logs

    var id: String {
        switch self {
            case .overview: "overview"
            case .machine(let id): "machine-\(id)"
            case .machines: "machines"
            case .loadGenerator: "load-generator"
            case .logs: "logs"
        }
    }

    var title: String {
        switch self {
            case .overview: "Overview"
            case .machine(let id): id
            case .machines: "Machines"
            case .loadGenerator: "Load Generator"
            case .logs: "Log Viewer"
        }
    }

    var systemImage: String {
        switch self {
            case .overview: "app"
            case .machine: "macstudio"
            case .machines: "macstudio"
            case .loadGenerator: "bolt.fill"
            case .logs: "text.page"
        }
    }
}
