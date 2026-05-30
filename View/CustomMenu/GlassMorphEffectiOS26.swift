//
//  GlassMorphEffectiOS26.swift
//  animation
//  (Header comment was previously misnamed `MorphActionButtoniOS26.swift`
//   — that's a different file. Fixed in this pass.)
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 26+ only — `@available(iOS 26.0, *)` on every type.
//
//  Learning point
//  ──────────────
//  Horizontal expandable glass button: a single capsule grows
//  rightward to reveal a row of action items, all rendered as ONE
//  Liquid-Glass surface using `.glassEffectUnion(id:namespace:)`.
//  The icon morphs between `ellipsis` (collapsed) and `xmark`
//  (expanded) via `matchedGeometryEffect` in the same namespace.
//  At any progress value 0…1 the result is a single coherent glass
//  blob — not a button + N separate buttons.
//
//  Why `glassEffectUnion`?
//  ───────────────────────
//  Without it, each item gets its own glass material and they
//  COMPOUND visually — light bouncing off light. Marking them with
//  the same `id` in a shared namespace tells the system "render
//  these as ONE glass region for material purposes," and the union
//  does the right thing on overlap, edges, and refraction.
//
//  The `Animatable` conformance on `ExpandableHorizontalGlassContainer`
//  ─────────────────────────────────────────────────────────────────
//  Required because we drive the expansion off `progress: CGFloat`
//  and want SwiftUI to interpolate `progress` at frame rate during
//  spring animations. Without `AnimatableData`, `progress` would
//  step, not animate.
//
//  Key APIs
//  ────────
//  • `.glassEffect(.regular.interactive(...), in: .capsule)` —
//    iOS 26. The `.interactive(...)` flavor adds press-state shine.
//  • `.glassEffectUnion(id:namespace:)` — iOS 26. Marks views as
//    belonging to a single glass region.
//  • `Animatable` + `AnimatableData` — manual conformance to
//    interpolate the `progress` driver smoothly.
//  • `ForEach(subviews:)` (iOS 18+) — extracts collection from a
//    ViewBuilder so the container can iterate without forcing the
//    caller to use Identifiable.
//  • `@Entry` + container values — clean way to attach per-item
//    metadata that the parent reads back via `containerValues`.
//  • `matchedGeometryEffect` — the icon swap (`ellipsis`↔`xmark`).
//
//  How to apply
//  ────────────
//  Use when you want a "more actions" button that EXPANDS in place
//  rather than opening a menu sheet — toolbar-style augmentation,
//  inline edit toggles, message reactions. The glass-union pattern
//  generalises to any Liquid-Glass UI where multiple sub-elements
//  should read as one material.
//
//  See also
//  ────────
//  • GlassMorphEffectMenuiOS26.swift — sibling demo using the SAME
//    pattern but for a menu pop-out (alignment-aware container).
//    Read both side-by-side; the contrast is the lesson.
//  • CustomSideMenu+iOS26.swift — different iOS 26 menu pattern
//    (slide-out side menu).
//
import SwiftUI

@available(iOS 26.0, *)
struct GlassMorphiOS26ButtonDemo: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        NavigationStack {
            List {
                Section("Preview") {
                    ZStack {
                        ExpandableHorizontalGlassContainer(
                            progress: progress)
                        { /// label view
                            ZStack {
                                Image(systemName: "ellipsis")
                                    .opacity(1 - progress)

                                Image(systemName: "xmark")
                                    .opacity(progress)
                            }
                        } content: {
                            /// any custom view
                            Image(.fox)
                                .containerValue(\.unionID, "0")
                                .containerValue(\.contentPadding, -7.5)
                        }
                        .font(.title3)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background {
                        Image(.aiGrn)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                    .clipShape(.rect(cornerRadius: 25))
                }

                Section("Properties") {
                    Slider(value: $progress)
                    Button("Toggle Actions") {
                        withAnimation(.bouncy(duration: 1, extraBounce: 0.1)) {
                            progress = progress == 0 ? 1 : 0
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Morphing Demo")
        }
    }
}

/// visualEffect view modifier:
/// closures passed to UI modifiers like .visualEffect may be considered isolated, meaning they could run on a different thread
///  -> Any values captured in these closures must conform to Sendable.
@available(iOS 26.0, *)
struct ExpandableHorizontalGlassContainer<Label: View, Content: View>: View, Animatable {
    var placeAtLeading: Bool = false
    var isInteractive: Bool = true
    var size: CGSize = .init(width: 55, height: 55)
    var progress: CGFloat
    @ViewBuilder var label: Label
    @ViewBuilder var content: Content

    /// View Properties
    @State private var labelPosition: CGRect = .zero
    @Namespace private var animation

    var spacing: CGFloat { 10.0 * progress }

    var scaleProgress: CGFloat {
        progress > 0.5 ? (1 - progress) / 0.5 : (progress / 0.5)
    }

    /// progress valur is subtle to animate naturally so need to adopt Animatable protocol to visual the value change
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    nonisolated func offsetX(proxy: GeometryProxy, labelPosition: CGRect) -> CGFloat {
        let minX = labelPosition.minX - proxy.frame(in: .named("Container")).minX
        return minX - (minX * progress)
    }

    var body: some View {
        // Resolve Capture of non-Sendable type 'Content.Type' in an isolated closure; this is an error in the Swift 6 language mode
        let erasedContent = AnyView(content) // Capture outside isolated closure
        let resolvedOffsetX = offsetX // Capture function ref outside

        return GlassEffectContainer(spacing: spacing) {
            HStack(spacing: spacing) {
                if placeAtLeading {
                    labelView()
                }

                /// Extracing view using ForEach subviews and appluing glass effect to each view
                ForEach(subviews: erasedContent) { subview in
                    let unionID = subview.containerValues.unionID
                    let contentPadding = subview.containerValues.contentPadding
                    let width = size.width + (contentPadding * 2)
                    let resolvedLabelPosition = labelPosition

                    subview
                        .blur(radius: 15 * scaleProgress)
                        .opacity(progress)
                        .frame(width: width, height: size.height)
                        /// showing: clear glass Effect
                        .glassEffect(.regular.interactive(isInteractive), in: .capsule)
                        .glassEffectUnion(
                            id: unionID,
                            namespace: animation
                        )
                        .allowsHitTesting(progress == 1)
                        .visualEffect { content, proxy in
                            content
                                .offset(x: resolvedOffsetX(proxy,
                                                           resolvedLabelPosition))
                        }
                        /// Preserve view size
                        .fixedSize()
                        .frame(width: width * progress)
                }

                if !placeAtLeading {
                    labelView()
                }
            }
        }
        .coordinateSpace(.named("Container"))
        .scaleEffect( /// use diff value for customized wobble effect
            x: 1 + (scaleProgress * 0.3),
            y: 1 - (scaleProgress * 0.35),
            anchor: .center
        )
    }

    @ViewBuilder
    private func labelView() -> some View {
        label
            .compositingGroup()
            .blur(radius: 15 * scaleProgress)
            .frame(width: size.width, height: size.height)
            .glassEffect(.regular.interactive(isInteractive), in: .capsule)
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .named("Container"))
            } action: { newValue in
                labelPosition = newValue
            }
    }
}

@available(iOS 26.0, *)
#Preview {
    GlassMorphiOS26ButtonDemo()
}

/// extract subview value
extension ContainerValues {
    @Entry var unionID: String? = nil
    @Entry var contentPadding: CGFloat = 0
}
