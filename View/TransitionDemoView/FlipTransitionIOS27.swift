//
//  FlipTransitionIOS27.swift
//  animation
//
//  Created on 8/29/26.
// Similar to sports app

import SwiftUI

@available(iOS 27.0, *)
struct FlipTransitionIOS27Demo: View {
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                Grid {
                    GridRow {
                        FlipTransition {
                            DummyLabel(
                                title: "Distance",
                                subTitle: "Today",
                                highlight: "1.2KM",
                                highlightColor: .cyan
                            )
                        } destination: { dismiss in
                            Button("Dismiss") {
                                dismiss()
                            }

                        } contextActions: {
                            Button("Share", systemImage: "square.and.arrow.up") {}
                        }

                        FlipTransition {
                            DummyLabel(
                                title: "Step Count",
                                subTitle: "Today",
                                highlight: "777",
                                highlightColor: .indigo
                            )
                        } destination: { _ in
                            DummyLabelFullPage(title: "Distance", symbol: "figure.walk")

                        } contextActions: {}
                    }
                }
                .padding(15)
            }
            .navigationTitle("Summary")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }
}

@available(iOS 27.0, *)
#Preview {
    FlipTransitionIOS27Demo()
}

private struct FlipTransitionConfig {
    var contextMenuTitle: String = "Edit"
    var contextMenuSymbol: String? = "pencil"
    var sourceCornerRadius: CGFloat = 20
    var destinationCornerRadius: CGFloat = 35
    var sourceExtendedBackgroundColor: Color = .init(UIColor.systemGray6)
}

@available(iOS 27.0, *)
struct FlipTransition<Content: View, Destination: View, ContextActions: View>: View {
    fileprivate var config: FlipTransitionConfig = .init()
    @ContentBuilder var content: Content
    @ContentBuilder var destination: (_ dismiss: @escaping () -> Void) -> Destination
    @ContentBuilder var contextActions: ContextActions

    /// View Properties
    @State private var sourceImage: UIImage?
    @State private var sourceRect: CGRect = .zero
    @State private var showDestination: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    var body: some View {
        content
            .contentShape(
                .contextMenuPreview,
                .rect(cornerRadius: config.sourceCornerRadius)
            )
            .opacity(showDestination ? 0 : 1)
            .onGeometryChange(for: CGRect.self, of: {
                $0.frame(in: .global)
            }, action: { newValue in
                sourceRect = newValue
            })
            .contextMenu {
                Button(action: expandDestination) {
                    Group {
                        if let symbol = config.contextMenuSymbol {
                            Image(systemName: symbol)
                        }
                        Text(config.contextMenuTitle)
                    }
                }
                contextActions
            } preview: { /// set context menu preview position
                content
                    .frame(width: sourceRect.width, height: sourceRect.height)
            }
            .fullScreenCover(isPresented: $showDestination) {
                FlipDestinationView(
                    config: config,
                    sourceRect: $sourceRect,
                    sourceImage: $sourceImage,
                    destination: destination
                )
                /// iOS27+ fail case modifier - incase transaction fails not animate the full screen cover
                .navigationTransition(.crossFade)
            }
    }

    /// TODO: add comment why this is better than pass the source view (content) to the destination view directly
    /// convert source view to an image instead of directly pass to destination
    ///  we can use the resizable source for flip effect
    private func expandDestination() {
        // create an image, not display source view again on transition
        let renderer = ImageRenderer(
            content: content
                .environment(\.colorScheme, colorScheme)
        )
        renderer.scale = displayScale
        sourceImage = renderer.uiImage
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                showDestination = true
            }
        }
    }
}

@available(iOS 26.0, *)
private struct FlipDestinationView<Destination: View>: View {
    var config: FlipTransitionConfig
    @Binding var sourceRect: CGRect
    @Binding var sourceImage: UIImage?
    @ContentBuilder var destination: (_ dismiss: @escaping () -> Void) -> Destination
    /// View Properties
    @State private var animate: Bool = false
    @State private var rotation: CGFloat = .zero
    @Environment(\.dismiss) var dismiss
    var body: some View {
        GeometryReader {
            let size = $0.size
            let maxWidth = min(size.width * 0.88, 500)
            let maxHeight = min(size.height * 0.5, 500)

            let transformWidth = animate ? maxWidth : sourceRect.width
            let transformHeight = animate ? maxHeight : sourceRect.height

            let transformX = animate ? 0 : sourceRect.minX
            let transformY = animate ? 0 : sourceRect.minY

            let transformAlignment: Alignment = animate ? .center : .topLeading

            ZStack {
                Rectangle()
                    .fill(.clear)
                    .overlay {
                        if let sourceImage {
                            Image(uiImage: sourceImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(
                                    maxWidth: .infinity, maxHeight: .infinity,
                                    alignment: .top // change flip card content alignment; deault  center
                                )
                                /// fill empty space when destination image > source image
                                .background(config.sourceExtendedBackgroundColor)
                                .clipShape(.rect(cornerRadius: config.destinationCornerRadius))
                                .compositingGroup()
                                .modifier(FlipEffectModifier(
                                    isFlipped: false, progress: animate ? 1 : 0
                                ))
                        }
                    }
                    .overlay {
                        // use max for aspect fill // todo: comment explain why
                        let scale = min(transformWidth / maxWidth, transformHeight / maxHeight)

                        destination(dismissTransactions)
                            .frame(width: maxWidth, height: maxHeight)
                            .scaleEffect(scale)
                            .frame(width: transformWidth, height: transformHeight, alignment: .top)
                            // flip content 180
                            .scaleEffect(x: -1)
                            .background {
                                // workaround for glass background using background closure
                                // attach glass effect to destination build cause weird flip animation color change
                                Rectangle()
                                    .fill(.clear)
                                    .glassEffect(.clear, in: .rect(cornerRadius: config.destinationCornerRadius))
                            }
                            .clipShape(.rect(cornerRadius: config.destinationCornerRadius))
                            .compositingGroup()
                            .modifier(FlipEffectModifier(
                                isFlipped: true, progress: animate ? 1 : 0
                            ))
                    }
            }
            .frame(width: transformWidth, height: transformHeight)
            .compositingGroup()
            .rotation3DEffect(
                .init(degrees: rotation),
                axis: (x: 0, y: 1, z: 0),
                anchor: .center,
                perspective: 0.5
            )
            .offset(x: transformX, y: transformY)
            .frame(
                maxWidth: .infinity, maxHeight: .infinity,
                alignment: transformAlignment
            )
            .ignoresSafeArea()
        }
        .presentationBackground {
            Rectangle()
                .fill(.black.opacity(animate ? 0.35 : 0))
                .onTapGesture(perform: dismissTransactions)
        }
        .onAppear(perform: animationTransaction)
    }

    func animationTransaction() {
        guard !animate else { return }
        withAnimation(.linear(duration: 1)) {
            animate = true
            rotation = 180
        }
    }

    func dismissTransactions() {
        guard animate else { return }
        withAnimation(.linear(duration: 1), completionCriteria: .logicallyComplete) {
            animate = false
            rotation = 360
        } completion: {
            sourceImage = nil
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                dismiss()
            }
        }
    }
}

@Animatable
private struct FlipEffectModifier: ViewModifier {
    @AnimatableIgnored var isFlipped: Bool
    var progress: CGFloat
    func body(content: Content) -> some View {
        content
            .opacity(isFlipped ? (progress > 0.5 ? 1 : 0) : (progress > 0.5 ? 0 : 1))
    }
}
