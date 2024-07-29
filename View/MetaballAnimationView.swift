//
//  MetaballAnimationView.swift
//  animation

import SwiftUI

struct MetaballAnimationDemoView: View {
    var body: some View {
        MetaballAnimationView()
            .preferredColorScheme(.dark)
    }
}
struct MetaballAnimationView: View {
    @State private var dragOffset: CGSize = .zero
    var body: some View {
        VStack {
            SingleMetaBall()
        }
    }
    
    @ViewBuilder
    func SingleMetaBall() -> some View {
        Canvas {
 context,
 size in
            context.addFilter(.alphaThreshold(min: 0.5, color: .orange))
            /// blur radius used to determines the amount of elasticity between 2 elements
            context.addFilter(.blur(radius: 30))
            
            context.drawLayer { ctx in
                for index in [1, 2] {
                    if let resolvedView = context.resolveSymbol(id: index) {
                        ctx.draw(resolvedView,
                                 at: CGPoint(x: size.width / 2, y: size.height / 2))
                    }
                }
            }
        } symbols: {
            Ball()
                .tag(1)
            
            Ball(offset: dragOffset)
                .tag(2)
        }
        .gesture(
            DragGesture()
                .onChanged({ value in
                    dragOffset = value.translation
                }).onEnded({ _ in
                    withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.7)) {
                        dragOffset = .zero
                    }
                })
            // todo: 2:57
            // https://www.youtube.com/watch?v=hfKGLJejAEw
        )
    }
    
    @ViewBuilder
    func Ball(offset: CGSize = .zero) -> some View {
        Circle()
            .fill(.white)
            .frame(width: 150, height: 150)
            .offset(offset)
    }
}

#Preview {
    MetaballAnimationDemoView()
}
