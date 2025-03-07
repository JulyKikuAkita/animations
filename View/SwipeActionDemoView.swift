//
//  SwipeActionDemoView.swift
//  animation

import SwiftUI

struct SwipeActionDemoView: View {
    var body: some View {
        NavigationStack {
            SwipeActionHomeView()
                .navigationTitle("Messages")
        }
    }
}

struct SwipeActionHomeView: View {
    /// Sample array of colors
    @State private var colors: [Color] = [.black, .yellow, .purple, .brown]
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 10) {
                ForEach(colors, id: \.self) { color in
                    SwipeAction(cornerRadius: 15, direction: color == .black ? .leading : .trailing) {
                        CardView(color)
                    } actions: {
                        Action(tint: .green, icon: "star.fill", isEnabled: color == .black) {
                            print("Bookmark")
                        }

                        Action(tint: .red, icon: "trash.fill") {
                            withAnimation(.easeInOut) {
                                colors.removeAll(where: { $0 == color })
                            }
                        }
                    }
                }
            }
            .padding([.leading, .trailing], 10)
        }
        .scrollIndicators(.hidden)
    }

    /// Sample card view
    @ViewBuilder
    func CardView(_ color: Color) -> some View {
        HStack(spacing: 12) {
            Circle()
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 6, content: {
                RoundedRectangle(cornerRadius: 5)
                    .frame(width: 80, height: 5)

                RoundedRectangle(cornerRadius: 5)
                    .frame(width: 60, height: 5)
            })

            Spacer(minLength: 0)
        }
        .foregroundStyle(.white.opacity(0.4))
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(color.gradient)
    }
}

/// Custom swipe action view
struct SwipeAction<Content: View>: View {
    var cornerRadius:CGFloat = 0
    var direction: SwipeDirection = .trailing
    @ViewBuilder var content: Content
    @ActionBuilder var actions: [Action]
    /// View properties
    @Environment(\.colorScheme) private var scheme
    /// View unique ID
    let viewID = UUID()
    /// Animation properties
    @State private var isEnabled: Bool = true /// disable interaction when animation is still in progress
    @State private var scrollOffset: CGFloat = .zero /// hide action item view when during animation

    var body: some View {
        ScrollViewReader { scrollProxy in /// reset scroll view to original position  when swipe action is pressed
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    content
                        .rotationEffect(.init(degrees: direction == .leading ? -180 : 0))
                        /// to take full available space
                        .containerRelativeFrame(.horizontal)
                        .background(scheme == .dark ? .black : .white)
                        .background {
                            if let firstAction = filterActions.first {
                                Rectangle()
                                    .fill(firstAction.tint)
                                    .opacity(scrollOffset == .zero ? 0 : 1)
                            }
                        }
                        .id(viewID)
                        .transition(.identity)
                        .overlay {
                            GeometryReader {
                                let minX = $0.frame(in: .scrollView(axis: .horizontal)).minX

                                Color.clear
                                    .preference(key: CGFloatKey.self, value: minX)
                                    .onPreferenceChange(CGFloatKey.self) {
                                        scrollOffset = $0
                                    }
                            }
                        }

                    ActionButtons {
                        withAnimation(.snappy) {
                            scrollProxy.scrollTo(viewID, anchor: direction == .trailing ? .topLeading : .topTrailing)
                        }
                    }
                    .opacity(scrollOffset == .zero ? 0 : 1)
                }
                .scrollTargetLayout()
                /// limit the swipe direction with visual effect api
                .visualEffect { content, geometryProxy in
                    content
                        .offset(x: scrollOffset(geometryProxy))
                }
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned) /// (where the magic is) ViewAligned scroll target behavior requires scrollTargetLayout() to be added inside the scrollView
            .background {
                if let lastAction = filterActions.last {
                    Rectangle()
                        .fill(lastAction.tint)
                        .opacity(scrollOffset == .zero ? 0 : 1)
                }
            }
            .clipShape(.rect(cornerRadius: cornerRadius))
            .rotationEffect(.init(degrees: direction == .leading ? 180 : 0))
        }
        .allowsHitTesting(isEnabled)
        .transition(CustomTransition())
    }

    /// Action buttons
    @ViewBuilder
    func ActionButtons(resetPosition: @escaping () -> ()) -> some View {
        /// default each button will have 100 width
        Rectangle()
            .fill(.clear)
            .frame(width: CGFloat(filterActions.count) * 100)
            .overlay(alignment: direction.alignment) {
                HStack(spacing: 0) {
                    ForEach(filterActions) { button in
                        Button(action: {
                            Task {
                                isEnabled = false
                                resetPosition()
                                try? await Task.sleep(for: .seconds(0.25)) // scroll action approx. takes 0.25 secs to complete (optionally if want immediate run button action
                                button.action()
                                try? await Task.sleep(for: .seconds(0.1))
                                isEnabled = true
                            }
                        }, label: {
                            Image(systemName: button.icon)
                                .font(button.iconFont)
                                .foregroundStyle(button.iconTint)
                                .frame(width: 100)
                                .frame(maxHeight: .infinity)
                                .contentShape(.rect)
                        })
                        .buttonStyle(.plain)
                        .background(button.tint)
                        .rotationEffect(.init(degrees: direction == .leading ? -180 : 0))
                    }
                }
            }
    }

    nonisolated func scrollOffset(_ proxy: GeometryProxy) -> CGFloat {
        let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX

        return (minX > 0 ? -minX : 0)
    }

    var filterActions: [Action] {
        return actions.filter({ $0.isEnabled })
    }
}

@resultBuilder
struct ActionBuilder {
    static func buildBlock(_ components: Action...) -> [Action] {
        return components
    }
}

/// Custom Transition as identity transition still not flaky on fading out the view when delete it
struct CustomTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .mask {
                GeometryReader {
                    let size = $0.size

                    Rectangle()
                        .offset(y: phase == .identity ? 0 : -size.height)
                }
                .containerRelativeFrame(.horizontal)
            }
    }
}
enum SwipeDirection {
    case leading, trailing

    var alignment: Alignment {
        switch self {
        case .leading:
                .leading
        case .trailing:
                .trailing
        }
    }
}
#Preview {
    SwipeActionDemoView()
}
