import SwiftUI
import FiveKit

enum PillContentStyle {
    case neutral
    case positive
    case negative
    case warning
    
    @ViewBuilder var background: some View {
        switch self {
            case .neutral: Color.gray.opacity(0.33)
            case .positive: Color.green.saturation(0.75).opacity(0.25)
            case .negative: Color.red.saturation(0.75).opacity(0.25)
            case .warning: Color.yellow.saturation(0.75).opacity(0.25)
        }
    }
}

struct Pill<Content: View>: View {
    @Environment(\.controlSize) private var controlSize
    
    let style: PillContentStyle
    let content: () -> Content
    
    init(
        _ style: PillContentStyle = .neutral,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.content = content
    }
    
    var verticalSpacing: CGFloat {
        switch controlSize {
            case .mini: 0
            case .small: 2
            case .regular: 4
            case .large: 6
            case .extraLarge: 8
            @unknown default: 4
        }
    }
    
    var horizontalSpacing: CGFloat {
        switch controlSize {
            case .mini: 2
            case .small: 4
            case .regular: 8
            case .large: 12
            case .extraLarge: 16
            @unknown default: 8
        }
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            content()
        }
        .padding(.vertical, verticalSpacing)
        .padding(.horizontal, horizontalSpacing)
        .background {
            style.background
        }
        .clipShape(.capsule)
    }
}

struct LabeledPill<Label: View, Content: View>: View {
    @Environment(\.controlSize) private var controlSize
    
    let style: PillContentStyle
    let content: () -> Content
    let label: () -> Label
    
    init(
        _ style: PillContentStyle = .neutral,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.style = style
        self.content = content
        self.label = label
    }
    
    var verticalSpacing: CGFloat {
        switch controlSize {
            case .mini: 0
            case .small: 2
            case .regular: 4
            case .large: 6
            case .extraLarge: 8
            @unknown default: 4
        }
    }
    
    var horizontalSpacing: CGFloat {
        switch controlSize {
            case .mini: 2
            case .small: 4
            case .regular: 8
            case .large: 12
            case .extraLarge: 16
            @unknown default: 8
        }
    }
    
    var centerSpacing: CGFloat {
        switch controlSize {
            case .mini: 3
            case .small: 6
            case .regular: 12
            case .large: 16
            case .extraLarge: 20
            @unknown default: 12
        }
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            HStack {
                label()
            }
            .padding(.vertical, verticalSpacing)
            .padding(.leading, horizontalSpacing)
            .padding(.trailing, centerSpacing / 2)
            .background(Color.systemFill)
            
            HStack {
                content()
            }
            .padding(.vertical, verticalSpacing)
            .padding(.leading, centerSpacing / 2)
            .padding(.trailing, horizontalSpacing)
            .background {
                style.background
            }
        }
        .clipShape(.capsule)
    }
}

#Preview {
    HStack {
        VStack(alignment: .leading) {
            Pill(.neutral) {
                Text("Idle")
            }
            
            Pill(.positive) {
                Text("Online")
            }
            
            Pill(.warning) {
                Text("Degraded")
            }
            
            Pill(.negative) {
                Text("Offline")
            }
        }
        
        VStack(alignment: .leading) {
            LabeledPill(.neutral) {
                Text("Idle")
            } label: {
                Text("Status")
            }
            
            LabeledPill(.positive) {
                Text("Online")
            } label: {
                Text("Status")
            }
            
            LabeledPill(.warning) {
                Text("Degraded")
            } label: {
                Text("Status")
            }
            
            LabeledPill(.negative) {
                Text("Offline")
            } label: {
                Text("Status")
            }
        }
    }
    .scenePadding()
}
