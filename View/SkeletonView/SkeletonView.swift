//
//  SkeletonView.swift
//  animation
// customized loading view as redacted effect
// note: use transaction modifier to prevent the looping animation being overwritten by other animations
import SwiftUI

struct SkeletonView<S: Shape>: View {
    var shape: S
    var color: Color
    init(_ shape: S, _ color: Color = .gray.opacity(0.3)) {
        self.shape = shape
        self.color = color
    }

    ///
    @State private var isAnimating: Bool = false
    var body: some View {
        shape
            .fill(color)
            /// skeleton effect
            .overlay {
                GeometryReader {
                    let size = $0.size
                    let skeletonWidth = size.width / 3
                    let blurRadius = max(skeletonWidth / 2, 30)
                    let blurDiameter = blurRadius * 2
                    /// Movement Offsets
                    let minX = -(skeletonWidth + blurDiameter)
                    let maxX = size.width + skeletonWidth + blurDiameter

                    Rectangle()
                        .fill(.gray)
                        .frame(width: skeletonWidth, height: size.height * 2)
                        .frame(height: size.height)
                        .blur(radius: blurRadius)
                        .rotationEffect(.init(degrees: rotation))
                        .blendMode(.luminosity) // try softSpotlight effect
                        /// repeating moving animation from left to right
                        .offset(x: isAnimating ? maxX : minX)
                }
            }
            .clipShape(shape)
            .compositingGroup()
            .onAppear {
                guard !isAnimating else { return }
                withAnimation(animation) {
                    isAnimating = true
                }
            }
            .onDisappear {
                isAnimating = false
            }
            .transaction {
                if $0.animation != animation {
                    $0.animation = .none
                }
            }
    }

    /// Customized View  Properties
    var rotation: Double {
        5
    }

    var animation: Animation {
        .easeInOut(duration: 1.5).repeatForever(autoreverses: false)
    }
}

/// testing if this animation interferes with the skeleton animation
#Preview {
    @Previewable
    @State var isTapped = false

    SkeletonView(.circle)
        .frame(width: 100, height: 100)
        .onTapGesture { /// introduce a different animation
            withAnimation(.smooth) {
                isTapped.toggle()
            }
        }
        .padding(.bottom, isTapped ? 15 : 0)
}
