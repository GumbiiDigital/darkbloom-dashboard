import Foundation

@MainActor @Observable
final class NavigationViewModel {
    static let shared = NavigationViewModel()
    
    var activeTab: SidebarTab = .overview
    
    private init() {}
}
