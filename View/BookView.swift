//
//  BookView.swift
//  animation

import SwiftUI

struct BookView: View {
    /// View properties
    @State private var progress: CGFloat = 0
    var profile: Profile
    var body: some View {
        VStack {
            OpenableBookView(config: .init(progress: progress)) { size in
                FrontView(size, profile.profilePicture)
            } insideLeft: { _ in
                LeftView()
            } insideRight: { _ in
                RightView()
            }
            .onTapGesture {
                withAnimation(.snappy(duration: 1.0)) {
                    progress = (progress == 1.0 ? 0.2 : 1.0)
                }
            }

//            VStack { /// debug slider
//                Slider(value: $progress)

//                Button("Toggle") {
//                    withAnimation(.snappy(duration: 1.0)) {
//                        // progress need to be animatable data otherwise the value jumping from 0 to 1 directly instead of progressing to 1
//                        progress = ( progress == 1.0 ? 0.2 : 1.0)
//                    }
//                }
//                .buttonStyle(.borderedProminent)
//            }
            .padding()
//            .background(.background, in: .rect(cornerRadius: 10))
//            .padding(.top, 50)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.gray.opacity(0.15))
    }

    @ViewBuilder
    func FrontView(_ size: CGSize, _ coverImage: String) -> some View {
        Image(coverImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
//            .offset(y: 10)
            .frame(width: size.width, height: size.height)
    }

    @ViewBuilder
    func LeftView() -> some View {
        VStack(spacing: 5) {
            Image("fox")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(.circle)
                .shadow(color: .black.opacity(0.15), radius: 5, x: 5, y: 5)

            Text(profile.username)
                .fontWidth(.condensed)
                .fontWeight(.bold)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }

    @ViewBuilder
    func RightView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.system(size: 14))

            Text("Nanachi is a shiba inu with amazing mellow temperament which is not known for this breed. He might be a far relative from fox but he have never met one in his life.")
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

/// Interactive Book Card View
struct OpenableBookView<Front: View, InsideLeft: View, InsideRight: View>: View, Animatable {
    var config: Config = .init()
    @ViewBuilder var front: (CGSize) -> Front
    @ViewBuilder var insideLeft: (CGSize) -> InsideLeft
    @ViewBuilder var insideRight: (CGSize) -> InsideRight

    var animatableData: CGFloat {
        get { config.progress }
        set { config.progress = newValue }
    }

    var body: some View {
        GeometryReader {
            let size = $0.size

            /// limiting progress between 1 and 0
            let progress = max(min(config.progress, 1), 0)
            let rotation = progress * -180
            let cornerRadius = config.cornerRadius
            let shadowColor = config.shadowColor

            ZStack {
                insideRight(size)
                    .frame(width: size.width, height: size.height)
                    .clipShape(.rect(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: cornerRadius,
                        topTrailingRadius: cornerRadius
                    ))
                    .shadow(color: shadowColor.opacity(0.1 * progress), radius: 5, x: 5, y: 0)
                    .overlay(alignment: .leading) { // adding a divider between left and right view
                        Rectangle()
                            .fill(config.dividerBackground.shadow(.inner(color: shadowColor.opacity(0.15), radius: 2)))
                            .frame(width: 6)
                            .offset(x: -3)
                            .clipped()
                    }

                front(size)
                    .frame(width: size.width, height: size.height)
                    /// disable interaction once it's flipped
                    .allowsTightening(-rotation < 90)
                    .overlay { /// display insideLeft view when book is opened
                        if -rotation > 90 {
                            insideLeft(size)
                                .frame(width: size.width, height: size.height)
                                .scaleEffect(x: -1) /// flip the text to the right direction
                                .transition(.identity)
                        }
                    }
                    .clipShape(.rect(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: cornerRadius,
                        topTrailingRadius: cornerRadius
                    ))
                    .shadow(color: shadowColor.opacity(0.1), radius: 5, x: 5, y: 0)
                    .rotation3DEffect(
                        .init(degrees: rotation),
                        axis: (x: 0.0, y: 1.0, z: 0.0),
                        anchor: .leading,
                        perspective: 0.3 // avoid stretching image
                    )
            }
            .offset(x: (config.width / 2) * progress) // center the book when opened
        }
        .frame(width: config.width, height: config.height)
    }

    /// Configuration
    struct Config {
        var width: CGFloat = 150
        var height: CGFloat = 200
        var progress: CGFloat = 0
        var cornerRadius: CGFloat = 10
        var dividerBackground: Color = .white
        var shadowColor: Color = .black
    }
}

#Preview {
    BookView(profile: profiles.first!)
}
