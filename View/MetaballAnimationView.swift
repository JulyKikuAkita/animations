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
    /// View Properties
    @State private var dragOffset: CGSize = .zero
    @State private var startClubAnimation: Bool = false
    @State private var type: String = "Single"
    var body: some View {
        VStack {
            Text("Metaball Animation")
                .font(.title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)
            
            Picker(selection: $type) {
                Text("Metaball")
                    .tag("Single")
                Text("Clubbed")
                    .tag("Clubbed")
            } label: {
            }
            .pickerStyle(.segmented)
            
            if type == "Single" {
                SingleMetaBall()
            } else {
                ClubbedView()
            }
        }
    }
    @ViewBuilder
    func ClubbedView() -> some View {
        Rectangle()
            .fill(
                .linearGradient(
                    colors: [.red, .pink, .purple],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .mask {
                TimelineView(.animation(minimumInterval: 6.6, paused: false)) { _ in
                    Canvas { context, size in
                        context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                        /// blur radius used to determines the amount of elasticity between 2 elements
                        context.addFilter(.blur(radius: 30))
                        
                        context.drawLayer { ctx in
                            for index in 1...15 {
                                if let resolvedView = context.resolveSymbol(id: index) {
                                    ctx.draw(resolvedView,
                                             at: CGPoint(x: size.width / 2, y: size.height / 2))
                                }
                            }
                        }
                    } symbols: {
                        ForEach(1...15, id: \.self) { index in
                            /// Generate custom offset each time to have view show up at random place and clubbed with each other
                            let offset = (startClubAnimation ? CGSize(
                                width: .random(in: -180...180),
                                height: .random(in: -240...240)) : .zero
                            )
                            
                            ClubbedRoundedRectangle(offset: offset)
                                .tag(index)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture{
                startClubAnimation.toggle()
            }
            
    }
    
    @ViewBuilder
    func ClubbedRoundedRectangle(offset: CGSize) -> some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(.white)
            .frame(width: 120, height: 120)
            .offset(offset)
        /// animation duration should less than timeline refresh rate, at line53
            .animation(.easeInOut(duration: 10), value: offset)
    }
    
    @ViewBuilder
    func SingleMetaBall() -> some View {
        Rectangle()
            .fill(
                .linearGradient(
                    colors: [.orange, .yellow, .brown],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .mask {
                Canvas { context, size in
                    context.addFilter(.alphaThreshold(min: 0.5, color: .orange))
                    /// blur radius used to determines the amount of elasticity between 2 elements
                    context.addFilter(.blur(radius: 35))
                    
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
