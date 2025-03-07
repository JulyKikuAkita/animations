//
//  RippleTransitionDemoView.swift
//  animation
//
//  Created by IFang Lee on 2/22/25.
//

import SwiftUI

struct RippleTransitionDemoView: View {
    let imageNames = ["AI_grn", "AI_pink"]
    @State private var count: Int = 0
    @State private var rippleLocation: CGPoint = .zero
    @State private var showOverlayView: Bool = false
    @State private var overlayRippleLocation: CGPoint = .zero

    var body: some View {
        NavigationStack {
            VStack {
                GeometryReader {
                    let size = $0.size

                    ForEach(0..<imageNames.count, id: \.self) { index in
                        if count == index {
                            ImageView(index, size: size)
                                .transition(.ripple(location: rippleLocation))
                        }
                    }
                }
                .frame(width: 350, height: 450)
                .coordinateSpace(.named("RIPPLEVIEW"))
                .onTapGesture(count: 1, coordinateSpace: .named("RIPPLEVIEW")) { location in
                    rippleLocation = location
                    withAnimation(.linear(duration: 1)) {
                        count = (count + 1) % 2
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottomTrailing) {
                GeometryReader {
                    let frame = $0.frame(in: .global)

                    Button {
                        overlayRippleLocation = .init(x: frame.midX, y: frame.midY)
                        withAnimation(.linear(duration: 1)) {
                            showOverlayView = true
                        }

                    } label: {
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(.indigo.gradient, in: .circle)
                            .clipShape(.rect)
                    }
                }
                .frame(width: 50, height: 50)
                .padding(15)
            }
            .navigationTitle("Ripple Transition")
        }
        .overlay {
            if showOverlayView {
                ZStack {
                    Rectangle()
                        .fill(.indigo.gradient)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.55)) {
                                showOverlayView = false
                            }
                        }

                    Text("Tap anywhere to dismiss!")
                }
                .transition(.reverseRipple(location: overlayRippleLocation))
            }
        }
    }

    private func ImageView(_ index: Int, size: CGSize) -> some View {
        Image(imageNames[index])
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size.width, height: size.height)
            .clipShape(.rect(cornerRadius: 30))
    }
}

#Preview {
    RippleTransitionDemoView()
}
