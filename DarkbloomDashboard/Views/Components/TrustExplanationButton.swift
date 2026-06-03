import SwiftUI
import FiveKit

struct TrustExplanationButton: View {
    @Environment(\.labelsVisibility) private var labelsVisibility
    
    @State private var isShowingExplanation: Bool = false
    
    let trust: MachineTrustInfo
    
    var trustColor: Color {
        if !trust.isOnline { return Color.red }
        return trust.isTrusted ? Color.secondary : Color.yellow
    }
    
    var body: some View {
        Button {
            isShowingExplanation.toggle()
        } label: {
            HStack {
                if trust.isOnline {
                    if trust.isTrusted {
                        Text(Image(systemName: "lock.shield.fill"))
                        if labelsVisibility != .hidden {
                            Text("Full Trust")
                        }
                    } else {
                        Text(Image(systemName: "shield.slash.fill"))
                        if labelsVisibility != .hidden {
                            Text("Reduced Trust")
                        }
                    }
                } else {
                    Text(Image(systemName: "circle.fill"))
                    if labelsVisibility != .hidden {
                        Text("Offline")
                    }
                }
            }
            .foregroundStyle(trustColor)
            .contentShape(.rect)
        }
        .buttonStyle(.borderless)
        .help("Why trust is reduced")
        .popover(isPresented: $isShowingExplanation) {
            PopoverContent(isPresented: $isShowingExplanation, trust: trust)
        }
    }
}

extension TrustExplanationButton {
    struct PopoverContent: View {
        @Binding var isPresented: Bool
        
        let trust: MachineTrustInfo
        
        var body: some View {
            #if os(macOS)
            PopoverContent_macOS(trust: trust)
            #else
            PopoverContent_iOS(isPresented: $isPresented, trust: trust)
            #endif
        }
    }
    
    struct PopoverContent_iOS: View {
        @Binding var isPresented: Bool
        
        let trust: MachineTrustInfo
        
        var body: some View {
            NavigationStack {
                Form {
                    Section {
                        if trust.reducedTrustReasons.isEmpty {
                            Text("This machine currently satisfies the tracked Darkbloom trust checks.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(trust.reducedTrustReasons) { reason in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(reason.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(reason.explanation)
                                        .foregroundStyle(.secondary)
                                    Text(reason.recoveryAction)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    } header: {
                        if !trust.reducedTrustReasons.isEmpty {
                            Text("Reasons for reduced trust")
                        }
                    }
                }
                .formStyle(.grouped)
                .navigationTitle(trust.isTrusted ? "Full Trust" : "Reduced Trust")
                .toolbarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        if #available(iOS 26, macOS 26, *) {
                            Button(role: .confirm) {
                                isPresented = false
                            }
                        } else {
                            Button {
                                
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.accent)
                            }
                        }
                    }
                }
            }
        }
    }
    
    struct PopoverContent_macOS: View {
        let trust: MachineTrustInfo
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(trust.isTrusted ? "Full Trust" : "Reduced Trust")
                    .font(.headline)
                
                if trust.reducedTrustReasons.isEmpty {
                    Text("This machine currently satisfies the tracked Darkbloom trust checks.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(trust.reducedTrustReasons) { reason in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(reason.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(reason.explanation)
                                .foregroundStyle(.secondary)
                            Text(reason.recoveryAction)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .scenePadding()
        }
    }
}

#Preview {
    let trusted = MachineTrustInfo(
        status: .online,
        trustLevel: .hardware,
        attested: true,
        acmeVerified: true,
        authenticatedRootEnabled: true,
        mdaSerial: nil,
        mdaVerified: true,
        mdmVerified: true,
        secureBootEnabled: true,
        secureEnclave: true,
        sipEnabled: true,
        runtimeVerified: true
    )
    let untrustedStatus = MachineTrustInfo(
        status: .untrusted,
        trustLevel: .hardware,
        attested: true,
        acmeVerified: true,
        authenticatedRootEnabled: true,
        mdaSerial: nil,
        mdaVerified: true,
        mdmVerified: true,
        secureBootEnabled: true,
        secureEnclave: true,
        sipEnabled: true,
        runtimeVerified: true
    )
    let untrustedSelfSigned = MachineTrustInfo(
        status: .online,
        trustLevel: .selfSigned,
        attested: true,
        acmeVerified: true,
        authenticatedRootEnabled: true,
        mdaSerial: nil,
        mdaVerified: false,
        mdmVerified: false,
        secureBootEnabled: true,
        secureEnclave: true,
        sipEnabled: true,
        runtimeVerified: true
    )
    Form {
        Section("Automatic Labels") {
            TrustExplanationButton(trust: trusted)
            TrustExplanationButton(trust: untrustedSelfSigned)
            TrustExplanationButton(trust: untrustedStatus)
        }
        
        Section("Hidden Labels") {
            TrustExplanationButton(trust: trusted)
            TrustExplanationButton(trust: untrustedSelfSigned)
            TrustExplanationButton(trust: untrustedStatus)
        }
        .labelsHidden()
    }
}
