//
//  MorphActionMenuiOS26.swift
//  animation
//
import SwiftUI

@available(iOS 26.0, *)
struct GlassMorphMenuiOS26Demo: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        NavigationStack {
            List {
                Section("Preview") {
                    Rectangle()
                        .foregroundStyle(.clear)
                        .background {
                            Image(.aiGrn)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .contentShape(.rect)
                                .onTapGesture {
                                    withAnimation(.bouncy(duration: 0.75, extraBounce: 0.02)) {
                                        progress = 0
                                    }
                                }
                        }
                        .overlay {
                            ExpandableGlassMenuContainer(
                                alignment: .topLeading, progress: progress
                            ) {
                                VStack(alignment: .leading, spacing: 12) {
                                    DummyMenuRow(image: "paperplane", title: "Send")
                                    DummyMenuRow(image: "arrow.trianglehead.2.counterclockwise", title: "Swap")
                                    DummyMenuRow(image: "arrow.down", title: "Receive")
                                }
                                .frame(width: 320)
                                .padding(10)

                            } label: {
                                Image(systemName: "square.and.arrow.up.fill")
                                    .font(.title3)
                                    .frame(width: 55, height: 55)
                                    .contentShape(.rect)
                                    .onTapGesture {
                                        withAnimation(.bouncy(duration: 0.75, extraBounce: 0.02)) {
                                            progress = 1
                                        }
                                    }
                            }
                            .frame(
                                width: .infinity,
                                height: .infinity,
                                alignment: .bottomTrailing
                            )
                            .padding(15)
                        }
                        .frame(height: 300)
                }
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))

                Section("Properties") {
                    Slider(value: $progress)
                }
            }
            .navigationTitle("Morphing Menu Demo")
        }
    }
}

@available(iOS 26.0, *)
struct ExpandableGlassMenuContainer<Content: View, Label: View>: View, Animatable {
    var alignment: Alignment
    var progress: CGFloat
    var labelSize: CGSize = .init(width: 65, height: 55)
    var cornerRadius: CGFloat = 30

    @ViewBuilder var content: Content
    @ViewBuilder var label: Label

    /// View Properties
    @State private var contentSize: CGSize = .zero

    var body: some View {
        GlassEffectContainer {
            let widthDiff = contentSize.width - labelSize.width
            let heightDiff = contentSize.height - labelSize.height

            let rWidth = widthDiff * contentOpacity
            let rHeight = heightDiff * contentOpacity

            ZStack(alignment: alignment) {
                content
                    .compositingGroup()
                    .scaleEffect(contentScale)
                    .blur(radius: 14 * blurProgress)
                    .opacity(contentOpacity)
                    .onGeometryChange(for: CGSize.self) {
                        $0.size
                    } action: { newValue in
                        contentSize = newValue
                    }
                    .fixedSize()
                    .frame(
                        width: labelSize.width + rWidth,
                        height: labelSize.height + rHeight
                    )

                label
                    .compositingGroup()
                    .blur(radius: 14 * blurProgress)
                    .opacity(1 - labelOpacity)
                    .frame(
                        width: labelSize.width,
                        height: labelSize.height
                    )
            }
            .compositingGroup()
            .clipShape(.rect(cornerRadius: cornerRadius))
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
        }
        .scaleEffect(
            x: 1 - (blurProgress * 0.35),
            y: 1 + (blurProgress * 0.45),
            anchor: scaleAnchor
        )
        .offset(y: offset * blurProgress)
    }

    var labelOpacity: CGFloat { min(progress / 0.35, 1) }

    var contentOpacity: CGFloat { max(progress - 0.35, 0) / 0.65 }

    var contentScale: CGFloat {
        let minAspectScale = min(
            labelSize.width / contentSize.width,
            labelSize.height / contentSize.height
        )
        return minAspectScale + (1 - minAspectScale) * progress
    }

    /// 0 > 0.5 -> 0
    var blurProgress: CGFloat {
        progress > 0.5 ? (1 - progress) / 0.5 : (progress / 0.5)
    }

    var offset: CGFloat {
        switch alignment {
        case .bottom, .bottomLeading, .bottomTrailing: -75
        case .top, .topLeading, .topTrailing: 75
        default: 0
        }
    }

    /// Converting Alignment into UnitPoint for ScaleEffect
    var scaleAnchor: UnitPoint {
        switch alignment {
        case .bottomLeading: .bottomLeading
        case .bottom: .bottom
        case .bottomTrailing: .bottomTrailing
        case .topLeading: .topLeading
        case .top: .top
        case .topTrailing: .topTrailing
        case .leading: .leading
        case .trailing: .trailing
        default: .center
        }
    }

    /// progress valur is subtle to animate naturally so need to adopt Animatable protocol to visual the value change
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
}

@available(iOS 26.0, *)
#Preview {
    GlassMorphMenuiOS26Demo()
}
