//
//  MorphingView.swift
//  animation
//  iOS17


import SwiftUI

struct MorphingDemoView: View {
    var body: some View {
        MorphingView()
            .preferredColorScheme(.dark)
    }
}
struct MorphingView: View {
    /// View Properties
    @State var currentImage: CustomShape  = .heart
    @State var pickerImage: CustomShape  = .heart

    @State var turnOffImageMorph: Bool = false
    @State var blurRadius: CGFloat = .zero
    @State var animateMorph: Bool = false
    var body: some View {
        VStack {
            /// Achieve  Image morph by mask the Canvas shape with image
            GeometryReader { proxy in
                let size = proxy.size
                
                Image("fox")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .offset(x: 20, y: -40)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .overlay {
                        Rectangle()
                            .fill(.teal)
                            .opacity(turnOffImageMorph ? 1 : 0)
                    }
                    .mask {
                        /// Morphing shapes with the help of canvas and filters
                        Canvas { context, size in
                            context.addFilter(.alphaThreshold(min: 0.3)) /// try different value for morph shape change
                            /// blur plays a major role to achieve morphing effect
                            context.addFilter(
                                    .blur(radius: blurRadius >= 20 ? 20 - (blurRadius - 20) : blurRadius)
                            )
                            
                            context.drawLayer { ctx in
                                if let resolvedImage = context.resolveSymbol(id: 1) {
                                    ctx.draw(resolvedImage, at: CGPoint(x: size.width / 2, y: size.height / 2),
                                                 anchor: .center)
                                }
                            }
                        } symbols: {
                            ResolvedImage(currentImage: $currentImage)
                                .tag(1)
                        }
                        .onReceive(
                            /// demo using timer, we can use TimelineView too
                            Timer
                                .publish(every: 0.01, on: .main, in: .common)
                                .autoconnect()) { _ in
                                    if animateMorph {
                                        if blurRadius <= 40 {
                                            blurRadius += 0.5 /// your desire value for animation speed,
                                            
                                            if blurRadius.rounded() == 20 {
                                                /// Update to the next image
                                                currentImage = pickerImage
                                            }
                                        }
                                        
                                        if blurRadius.rounded() == 40 {
                                            /// end animation and reset blur radius to zero
                                            animateMorph = false
                                            blurRadius = 0
                                        }
                                    }
                                }
                    }
                
            }
            .frame(height: 350)
            
            Picker("", selection: $pickerImage) {
                ForEach(CustomShape.allCases, id: \.rawValue) { shape in
                    Image(systemName: shape.rawValue)
                        .tag(shape)
                }
            }
            .pickerStyle(.segmented)
            .overlay {
                Rectangle()
                    .fill(.primary)
                    .opacity(animateMorph ? 0.05 : 0)
            }
            .padding(15)
            .padding(.top, -50)
            .onChange(of: pickerImage) {
                animateMorph = true
            }

            
            Toggle("Turn off Image Morph", isOn: $turnOffImageMorph)
                .fontWeight(.semibold)
                .padding(.horizontal, 15)
                .padding(.top, 10)
        }
        .offset(y: -50)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

struct ResolvedImage: View {
    @Binding var currentImage: CustomShape
    var body: some View {
        Image(systemName: currentImage.rawValue)
            .font(.system(size: 200))
            .animation(
                .interactiveSpring(
                    response: 0.7,
                    dampingFraction: 0.8,
                    blendDuration: 0.8
                ), 
                value: currentImage
            )
            .frame(width: 300, height: 300)
    }
}

#Preview {
    MorphingDemoView()
}
