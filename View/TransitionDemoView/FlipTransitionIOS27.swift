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
    /// Drives both halves of the flip. Keeping it single-valued is load-bearing, not just tidiness:
    /// `FlipEffectModifier` swaps faces at `progress > 0.5` on the assumption that progress and `rotation` reach
    /// their midpoints together. Animating the two directions on different curves puts the swap somewhere other
    /// than the edge-on frame, and the cut becomes visible.
    var animation: Animation = .linear(duration: 1)
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
            /// The source stays in the hierarchy while the cover is up (it keeps reporting geometry), so it has to be
            /// hidden instead of removed — otherwise it shows through underneath the flipping snapshot.
            .opacity(showDestination ? 0 : 1)
            /// Global coordinates: the flip runs inside a fullScreenCover, a separate presentation hierarchy with no
            /// shared coordinate space to convert from.
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
            } preview: {
                /// Without an explicit frame the preview sizes to the content's ideal size, which differs from the
                /// grid-stretched source card — the flip would then start from a box that never matched what the
                /// user just long-pressed.
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

    /// Rasterizes the source card and hands the bitmap to the destination rather than re-building `content` there.
    /// The front face has to *stretch* from source size to destination size; a live copy of `content` would instead
    /// re-run layout at every intermediate size, so text rewraps and stacks reflow and the face visibly reshuffles
    /// instead of growing. A single `.resizable()` texture scales as one unit, and it avoids standing up a second
    /// live copy of the source that would own its own state and animations.
    private func expandDestination() {
        let renderer = ImageRenderer(
            content: content
                /// ImageRenderer renders outside the view tree and inherits none of its environment, so the ambient
                /// color scheme has to be re-injected or the snapshot always comes out in light mode.
                .environment(\.colorScheme, colorScheme)
        )
        renderer.scale = displayScale
        sourceImage = renderer.uiImage
        /// Presenting while the context menu is still on screen collides with its dismissal transition; the short
        /// delay lets the menu start collapsing first. `disablesAnimations` suppresses fullScreenCover's own slide-up
        /// so the flip is the only visible motion.
        /// TODO: this delay is a guess at the menu's teardown, making it the most fragile line here — it belongs in
        /// the config at least, and ideally keys off an actual dismissal signal rather than wall-clock.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            /// TODO: replace with `withoutAnimation { }` from Helpers/Extensions/View+Animation.swift — that helper
            /// documents itself as the preferred spelling and this is one of two hand-rolled copies in this file.
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                showDestination = true
            }
        }
    }
}

/// TODO: gate at iOS 27 like the rest of the file. Only `FlipTransition` presents this and that is 27-only, so the
/// 26 lower bound can never be exercised — `.glassEffect` is the only member that actually needs 26.
@available(iOS 26.0, *)
private struct FlipDestinationView<Destination: View>: View {
    var config: FlipTransitionConfig
    @Binding var sourceRect: CGRect
    @Binding var sourceImage: UIImage?
    @ContentBuilder var destination: (_ dismiss: @escaping () -> Void) -> Destination
    /// View Properties
    @State private var animate: Bool = false
    @State private var rotation: CGFloat = .zero
    /// TODO: `private`, along with `animationTransaction` / `dismissTransactions` below — the only unqualified
    /// members in a file that marks everything else private.
    @Environment(\.dismiss) var dismiss
    var body: some View {
        GeometryReader {
            let size = $0.size
            /// Proportional to the screen, but capped so the card stays a card on iPad instead of spanning the window.
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
                        /// Aspect-fit. The source tile and the destination rarely share an aspect ratio, so one axis
                        /// has slack: `min` keeps the whole destination inside the animating box and letterboxes that
                        /// axis (the gap is covered by the glass background below). `max` would aspect-fill instead —
                        /// no gap, but the overflow is cut by `clipShape`, which crops the destination's own chrome
                        /// while the card is still near source size.
                        let scale = min(transformWidth / maxWidth, transformHeight / maxHeight)

                        destination(dismissTransactions)
                            /// The destination is laid out once, at its final size, and only ever scaled from there.
                            /// Driving this frame with `transformWidth/Height` would re-run its layout on every
                            /// animation frame — text rewrapping and stacks reflowing mid-flip.
                            .frame(width: maxWidth, height: maxHeight)
                            .scaleEffect(scale)
                            /// `scaleEffect` is render-only: the view keeps reporting `maxWidth × maxHeight` upward
                            /// no matter how small it draws. This second frame collapses the reported size down to
                            /// what is actually on screen, so the clip shape, glass background and the 3D rotation
                            /// anchor track the visible card instead of the full-size layout box. `.top` matches the
                            /// front face's alignment so both faces grow from the same edge.
                            .frame(width: transformWidth, height: transformHeight, alignment: .top)
                            /// The back face is seen through the rotation and therefore arrives mirrored;
                            /// pre-mirroring cancels it out so text reads correctly once the card is face-on.
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

    /// TODO: rename this pair — neither involves a `Transaction`, and the plural is inconsistent.
    /// `expand()` / `collapse()` says what happens, and `collapse` is also what callers receive as their
    /// `dismiss` closure.
    func animationTransaction() {
        guard !animate else { return }
        withAnimation(config.animation) {
            animate = true
            rotation = 180
        }
    }

    func dismissTransactions() {
        guard animate else { return }
        /// 180 → 360 rather than back to 0 so the card keeps turning the same way instead of rewinding.
        /// `.logicallyComplete` fires the completion as the values land, so the cover tears down on the frame the
        /// card reaches the source rect rather than after the trailing visual effects settle.
        withAnimation(config.animation, completionCriteria: .logicallyComplete) {
            animate = false
            rotation = 360
        } completion: {
            /// Clear the snapshot before dismissing, and dismiss without animation, so neither the stale front face
            /// nor fullScreenCover's slide-out shows after the flip has already returned home.
            sourceImage = nil
            // TODO: second hand-rolled copy — use `withoutAnimation { dismiss() }`.
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                dismiss()
            }
        }
    }
}

/// Both faces occupy the same space; the flip reads as one card because the opaque face is swapped at the halfway
/// point of the rotation, where the card is edge-on and the cut cannot be seen.
@Animatable
private struct FlipEffectModifier: ViewModifier {
    /// Identifies which face this is, so it is fixed for the lifetime of the modifier — `@Animatable` would otherwise
    /// try to interpolate it. Only `progress` drives the swap.
    @AnimatableIgnored var isFlipped: Bool
    var progress: CGFloat
    func body(content: Content) -> some View {
        content
            .opacity(isFlipped ? (progress > 0.5 ? 1 : 0) : (progress > 0.5 ? 0 : 1))
    }
}
