//
//  FloatingButton.swift
//  animation

import SwiftUI

/// Custom button
struct FloatingButton<Label: View>: View {
    var buttonSize: CGFloat
    /// Actions
    var actions: [FloatingAction]
    var label: (Bool) -> Label
    init(buttonSize: CGFloat = 50, @FloatingActionBuilder  actions: @escaping () -> [FloatingAction], @ViewBuilder label: @escaping (Bool) -> Label) {
        self.buttonSize = buttonSize
        self.actions = actions()
        self.label = label
    }
    
    /// View Properties
    @State private var isExpanded: Bool = false
    var body: some View {
        Button {
            isExpanded.toggle()
        } label: {
            label(isExpanded)
                .frame(width: buttonSize, height: buttonSize)
                .contentShape(.rect)
        }
        .buttonStyle(NoAnimationButtonStyle())
        .background {
            ForEach(actions) { action in
                ActionView(action)
            }
        }
        .animation(.snappy(duration: 0.4, extraBounce: 0), value: isExpanded)
    }
    
    /// Action view
    @ViewBuilder
    func ActionView(_ action: FloatingAction) -> some View {
        Image(systemName: action.symbol)
            .font(action.font)
            .foregroundStyle(action.tint)
            .frame(width: buttonSize, height: buttonSize)
            .background(action.background.gradient, in: .circle)
            .shadow(color: .orange.opacity(0.5), radius: 6)
            .contentShape(.circle)
            .rotationEffect(.init(degrees: progress(action) * -90))
            .offset(x: isExpanded ? -offset / 2 : 0)
            .rotationEffect(.init(degrees: progress(action) * 90))
    }
    
    private var offset: CGFloat {
        let buttonSize = buttonSize + 10
        var base: CGFloat = 1
        switch actions.count {
        case 1:
            base = buttonSize * 2
        case 2:
            base = buttonSize * 1.25
        default:
            base = buttonSize
        }
        return Double(actions.count) * base
    }
    
    private func progress(_ action: FloatingAction) -> CGFloat {
        let index = CGFloat(actions.firstIndex(where: { $0.id == action.id }) ?? 0)
        return actions.count == 1 ? 1 : index / CGFloat(actions.count - 1)
    }
}

/// Custom button style
fileprivate struct NoAnimationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

/// expanded buttons state
struct FloatingAction: Identifiable {
    private(set) var id: UUID = .init()
    var symbol: String
    var font: Font = .title3
    var tint: Color = .white
    var background: Color = .orange
    var action: () -> ()
}

/// SwiftUI View like builder to get array of actions using ResultBuilder
@resultBuilder
struct FloatingActionBuilder {
    static func buildBlock(_ components: FloatingAction...) -> [FloatingAction] {
        components.compactMap({ $0 })
    }
}

#Preview {
    ContentView()
}
