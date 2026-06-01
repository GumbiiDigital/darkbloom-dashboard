import SwiftUI
import FiveKit

struct SidebarLink: View {
    let value: SidebarTab
    let badge: Int?
    
    init(value: SidebarTab, badge: Int? = nil) {
        self.value = value
        self.badge = badge
    }
    
    var body: some View {
        NavigationLink(value: value) {
            Label(value.title, systemImage: value.systemImage)
                .badge(badge ?? 0)
                .badgeProminence(.increased)
                .animation(.smooth, value: badge)
        }
    }
}
