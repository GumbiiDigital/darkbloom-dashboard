import SwiftUI

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
        }
    }
}

struct SidebarMachineLink: View {
    @Environment(ContentViewModel.self) private var viewModel
    
    let serialNo: String
    
    var body: some View {
        let value = SidebarTab.machine(serialNo)
        NavigationLink(value: value) {
            HStack {
                Label(value.title, systemImage: value.systemImage)
                Spacer()
                if let machine = viewModel.machineInfo[serialNo] {
                    if machine.trust.isOnline {
                        if machine.trust.isTrusted {
                            Text(Image(systemName: "checkmark.shield.fill"))
                        } else {
                            Text(Image(systemName: "shield.slash.fill"))
                                .foregroundStyle(Color.yellow)
                        }
                    } else {
                        Text(Image(systemName: "circle.fill"))
                            .foregroundStyle(Color.red)
                    }
                }
            }
        }
    }
}
