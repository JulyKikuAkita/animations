//
//  SkeletonView.swift
//  animation
// note: use redacted modifier for skeleton effect
import SwiftUI

extension View {
    func skeleton(isRedacted: Bool) -> some View {
        modifier(SkeletonViewModifier(isRedacted: isRedacted))
    }
}

struct SkeletonViewModifier: ViewModifier {
    var isRedacted: Bool = false
    @State private var isAnimating: Bool = false
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content
            .redacted(reason: isRedacted ? .placeholder : [])
            /// Skeleton effect
            .overlay {
                if isRedacted {
                    GeometryReader {
                        let size = $0.size
                        let skeletonWidth = size.width / 3
                        let blurRadius = max(skeletonWidth / 2, 30)
                        let blurDiameter = blurRadius * 2
                        /// Movement Offsets
                        let minX = -(skeletonWidth + blurDiameter)
                        let maxX = size.width + skeletonWidth + blurDiameter

                        Rectangle()
                            .fill(scheme == .dark ? .white : .black)
                            .frame(width: skeletonWidth, height: size.height * 2)
                            .frame(height: size.height)
                            .blur(radius: blurRadius)
                            .rotationEffect(.init(degrees: rotation))
                            /// repeating moving animation from left to right
                            .offset(x: isAnimating ? maxX : minX)
                    }
                    .mask {
                        content
                            .redacted(reason: .placeholder)
                    }
                    .blendMode(.softLight)
                    .task {
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

#Preview {
    @Previewable @State var showSkeleton = true
    CardPlacerHolderView(
        card: Card(
            image: "fox",
            title: "Redacted Demo Card",
            subTitle: "From June 9th 2025"
        )
    )
    .padding(10)
    .skeleton(isRedacted: showSkeleton)
    .onTapGesture {
        showSkeleton.toggle()
    }
}
