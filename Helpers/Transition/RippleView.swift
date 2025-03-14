//
//  RippleView.swift
//  animation
//
// 1. create a custom Ripple view
// 2. turn the view to view modifier
// 3. use the view modifier to create transition
//

import SwiftUI

extension AnyTransition {
    static func ripple(location: CGPoint) -> AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: Ripple(location: location, isIdentity: false),
                identity: Ripple(location: location, isIdentity: true)
            ),
            removal: .modifier(
                // view will be remove immediately if set the value to 1
                active: IdentityTransition(opacity: 0.99),
                identity: IdentityTransition(opacity: 1)
            )
        )
    }

    static func reverseRipple(location: CGPoint) -> AnyTransition {
        .modifier(
            active: Ripple(location: location, isIdentity: false),
            identity: Ripple(location: location, isIdentity: true)
        )
    }
}

private struct IdentityTransition: ViewModifier {
    var opacity: Double = 0
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
    }
}

private struct Ripple: ViewModifier {
    var location: CGPoint
    var isIdentity: Bool

    func body(content: Content) -> some View {
        content
            .mask(alignment: .topLeading) {
                MaskRippleView()
                    .ignoresSafeArea()
            }
    }

    private func MaskRippleView() -> some View {
        GeometryReader {
            let size = $0.size
            let progress: CGFloat = isIdentity ? 1 : 0
            let circleSize: CGFloat = 50
            let circleRadius: CGFloat = circleSize / 2

            let fillCircleScale: CGFloat = max(size.width / circleRadius, size.height / circleRadius) + 4
            let defaultScale: CGFloat = isIdentity ? 1 : 0

            ZStack(alignment: .center) {
                Circle()
                    .frame(width: circleSize, height: circleSize)

                Circle()
                    .frame(width: circleSize + 10, height: circleSize + 10)
                    .blur(radius: 3)

                Circle()
                    .frame(width: circleSize + 20, height: circleSize + 20)
                    .blur(radius: 7)

                Circle()
                    .opacity(0.5)
                    .frame(width: circleSize + 20, height: circleSize + 20)
                    .blur(radius: 7)
            }
            .frame(width: circleSize, height: circleSize)
            .compositingGroup()
            .scaleEffect(defaultScale + (fillCircleScale * progress), anchor: .center)
            .offset(x: location.x - circleRadius, y: location.y - circleRadius)
        }
    }
}

// show Ripple view (not in use for ripple transition)
struct RippleView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 30)
            .fill(.green.gradient)
            .mask(alignment: .topLeading) {
                GeometryReader {
                    let size = $0.size

                    // update per need
                    let circleSize: CGFloat = 100
                    let circleRadius: CGFloat = circleSize / 2

                    let fillCircleScale: CGFloat = max(size.width / circleRadius, size.height / circleRadius) + 4

                    ZStack(alignment: .center) {
                        Circle()
                            .frame(width: circleSize, height: circleSize)

                        Circle()
                            .frame(width: circleSize + 10, height: circleSize + 10)
                            .blur(radius: 3)

                        Circle()
                            .frame(width: circleSize + 20, height: circleSize + 20)
                            .blur(radius: 7)

                        Circle()
                            .opacity(0.5)
                            .frame(width: circleSize + 20, height: circleSize + 20)
                            .blur(radius: 7)
                    }
                    .frame(width: circleSize, height: circleSize)
//                    .compositingGroup()
//                    .scaleEffect(fillCircleScale, anchor: .center)
                }
            }
    }
}

#Preview {
    RippleTransitionDemoView()
}
