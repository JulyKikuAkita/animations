//
//  SlideToCancelText.swift
//  animation
//
//  Created on 1/23/26.
import SwiftUI

struct SlideToCancelTextDemo: View {
    var body: some View {
        HStack {
            CustomTrashCanView(isOpen: false)
            SlideToCancelText(text: "Hello World!")
        }
    }
}

struct SlideToCancelText: View {
    var text: String
    @State private var animate: Bool = false
    var body: some View {
        viewContent()
            .foregroundStyle(.gray.secondary)
            .overlay {
                viewContent()
                    .foregroundStyle(.primary)
                    .mask {
                        GeometryReader {
                            let size = $0.size

                            Rectangle()
                                .frame(width: 15, height: size.height)
                                .blur(radius: 5)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .offset(x: animate ? -size.width * 1.1 : 30)
                        }
                    }
            }
            .compositingGroup()
            .onAppear {
                guard !animate else { return }
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
    }

    func viewContent() -> some View {
        HStack(spacing: 5) {
            Image(systemName: "chevron.left")
                .font(.caption)

            Text(text)
                .font(.callout)
        }
    }
}

struct CustomTrashCanView: View {
    var isOpen: Bool
    var body: some View {
        VStack(spacing: 2) {
            VStack(spacing: 0) {
                UnevenRoundedRectangle(
                    topLeadingRadius: 10,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 10
                )
                .frame(width: 15, height: 6)

                Capsule()
                    .frame(height: 4)
            }
            .compositingGroup()
            .rotationEffect(.init(degrees: isOpen ? -90 : 0), anchor: .bottomLeading)
            .offset(y: isOpen ? 10 : 0)

            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 5,
                bottomTrailingRadius: 5,
                topTrailingRadius: 0
            )
            .frame(width: 20, height: 20)
        }
        .frame(width: 35)
        .foregroundStyle(.gray)
        .compositingGroup()
        .scaleEffect(0.8)
        .animation(.easeInOut(duration: 0.3), value: isOpen)
    }
}

#Preview {
    SlideToCancelTextDemo()
}
