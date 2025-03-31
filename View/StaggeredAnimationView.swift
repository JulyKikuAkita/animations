//
//  StaggeredAnimationView.swift
//  animation
//  Using a custom Transition with delay animation to achieve staggered effect
//
import SwiftUI

struct StaggeredAnimationDemoView: View {
    @State private var showList: Bool = false
    @State private var showGrid: Bool = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    HStack {
                        Button("Toggle List") {
                            showList.toggle()
                        }

                        Spacer(minLength: 0)

                        Button("Toggle Grid") {
                            showGrid.toggle()
                        }
                    }

                    if showList {
                        let config = StaggeredConfig(
                            offset: .init(width: 150, height: 50),
                            scale: 0.85,
                            scaleAnchor: .center
                        )

                        ForEach(1 ... 7, id: \.self) { _ in
                            StaggeredAnimationView(config: config) {
                                dummyListView()
                            }
                        }
                    }

                    if showGrid {
                        LazyVGrid(columns: Array(repeating: GridItem(), count: 2)) { StaggeredAnimationView {
                            ForEach(1 ... 6, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(.black.gradient)
                                    .frame(height: 150)
                            }
                        }
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(15)
                // width of the view should be constant even when no view is present
                // for the staggered animation
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Staggered Animation")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    func dummyListView() -> some View {
        HStack(spacing: 10) {
            Circle()
                .frame(width: 45, height: 45)

            VStack(alignment: .leading, spacing: 5) {
                RoundedRectangle(cornerRadius: 5)
                    .frame(height: 10)
                    .padding(.trailing, 20)

                RoundedRectangle(cornerRadius: 5)
                    .frame(height: 10)
                    .padding(.trailing, 140)

                RoundedRectangle(cornerRadius: 5)
                    .frame(width: 100, height: 10)
            }
        }
    }
}

// work with scrollView, grid etc
struct StaggeredAnimationView<Content: View>: View {
    var config: StaggeredConfig = .init()
    @ViewBuilder var content: Content
    var body: some View {
        Group(subviews: content) { collection in
            ForEach(collection.indices, id: \.self) { index in
                collection[index]
                    .transition(CustomStaggeredTransition(index: index, config: config))
            }
        }
    }
}

private struct CustomStaggeredTransition: Transition {
    var index: Int
    var config: StaggeredConfig
    func body(content: Content, phase: TransitionPhase) -> some View {
        let animationDelay: Double = min(Double(index) * config.delay, config.maxDelay)

        let isIdentity: Bool = phase == .identity
        let didDisappear: Bool = phase == .didDisappear
        let posX: CGFloat = config.offset.width
        let posY: CGFloat = config.offset.height

        let reverseX: CGFloat = config.disappearInSameDirection ? posX : -posX
        let disabledX: CGFloat = config.noDisappearAnimation ? 0 : reverseX

        let reverseY: CGFloat = config.disappearInSameDirection ? posY : -posY
        let disabledY: CGFloat = config.noDisappearAnimation ? 0 : reverseY

        let offsetX = isIdentity ? 0 : didDisappear ? disabledX : posX
        let offsetY = isIdentity ? 0 : didDisappear ? disabledY : posY

        content
            .opacity(isIdentity ? 1 : 0)
            .blur(radius: isIdentity ? 0 : config.blurRadius)
            .compositingGroup()
            .scaleEffect(isIdentity ? 1 : config.scale, anchor: config.scaleAnchor)
            .offset(x: offsetX, y: offsetY)
            .animation(config.animation.delay(animationDelay), value: phase)
    }
}

struct StaggeredConfig {
    var delay: Double = 0.04
    var maxDelay: Double = 0.3
    var blurRadius: CGFloat = 6
    var offset: CGSize = .init(width: 0, height: 100)
    var scale: CGFloat = 0.95
    var scaleAnchor: UnitPoint = .center
    var animation: Animation = .smooth(duration: 0.3, extraBounce: 0)
    var disappearInSameDirection: Bool = false
    var noDisappearAnimation: Bool = false
}

#Preview {
    StaggeredAnimationDemoView()
}
