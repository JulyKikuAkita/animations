//
//  iOS26ResizingSheet.swift
//  animation
//
//  Created on 3/9/26.

// YouTube-style auto-resizing sheet: background content (video) shrinks and moves
// as the sheet slides up, staying fully visible above the sheet at all times.
//
// Problem: onGeometryChange() and GeometryReader report the model layer value —
// the final destination — not the in-flight animated position. So when the sheet
// animates between detents, the content jumps instantly instead of following smoothly.
//
// Solution: CADisplayLink, a frame-synchronized timer,
// + CALayer.presentation() to sample the sheet's real
// on-screen Y origin every frame during animation.
//
import SwiftUI

struct MockYouTubeSortsView: View {
    @State private var showSheet: Bool = false
    var body: some View {
        SheetWithInfo(isPresented: $showSheet) { info in
            dummyYouTubeShortsLayout(info: info)
        } sheet: { _ in
            ScrollView(.vertical) {}
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    dummyCommentBar()
                }
                .presentationDetents([.medium, .large])
                .preferredColorScheme(.dark)
                .presentationBackground(.black)
        }
        .background(.black)
        .ignoresSafeArea()
        .overlay(alignment: .bottom) {
            viewActions()
                .opacity(showSheet ? 0 : 1)
                .animation(.easeInOut(duration: 0.2), value: showSheet)
        }
    }

    func dummyYouTubeShortsLayout(info: SheetInfo) -> some View {
        // originY is nil while the sheet is dismissed — use it as a visibility flag.
        let isVisible = info.originY != nil
        let offset = info.originY ?? 0
        // How much vertical space the sheet currently occupies (distance from sheet top to screen bottom).
        let bottomPadding = max(info.windowSize.height - offset, 0)
        // The sheet height at the .medium detent (50% of screen height).
        let firstDetentHeight = info.windowSize.height * 0.5
        // Scales 0 → safeArea.top as the sheet grows from hidden → medium detent.
        // Nudges the video down so it clears the status bar when the sheet is open.
        // Falls back to 10pt on devices without a bottom safe area (older iPhones without notch).
        let topOffset = min(bottomPadding / firstDetentHeight, 1) * (info.safeArea.top + (info.safeArea.bottom == 0 ? 10 : 0))

        return
            Rectangle()
                .fill(.clear)
                .overlay { /// any demo image
                    Image(.nanachiPaint)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                /// Match the screen's native aspect ratio — the video fills exactly one screen height (Shorts/vertical format).
                .aspectRatio(info.windowSize.width / info.windowSize.height, contentMode: .fit)
                .clipped()
                /// bottomPadding lifts the video above the sheet; topOffset nudges it down from the status bar simultaneously.
                .padding(.bottom, isVisible ? (bottomPadding + topOffset) : 0)
                .offset(y: isVisible ? topOffset : 0)
    }

    func viewActions() -> some View {
        HStack(alignment: .bottom, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text("Mr. Fox")
                        .foregroundStyle(.white)

                    Button("Subscribe") {}
                        .font(.caption)
                        .foregroundStyle(.black)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(.white)
                }
                Text("Excited about new products!")
                    .font(.callout)
                    .foregroundStyle(.white)
            }

            Spacer(minLength: 0)

            VStack(spacing: 30) {
                Button {} label: {
                    Image(systemName: "hand.thumbsup.fill")
                }
                Button {} label: {
                    Image(systemName: "hand.thumbsdown.fill")
                }

                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "text.bubble.fill")
                }

                Button {} label: {
                    Image(systemName: "arrowshape.turn.up.right")
                }

                Button {} label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }

                Button {} label: {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 35, height: 36)
                }
            }
            .font(.title2)
            .foregroundStyle(.white)
        }
        .padding(15)
    }

    func dummyCommentBar() -> some View {
        HStack(spacing: 10) {
            TextField("Comment", text: .constant(""))
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
                .background(.fill, in: .capsule)
        }
        .padding(.horizontal, 15)
        .padding(.top, 10)
        .padding(.bottom, 5)
        .background(.black)
        .overlay(alignment: .top) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(.white.tertiary)
        }
    }
}

struct SheetInfo {
    /// Sheet's top edge Y position in screen coordinates, updated every frame during animation.
    /// nil when the sheet is dismissed — acts as an isVisible flag.
    var originY: CGFloat?
    /// Size of the base content view (the non-sheet background).
    var baseViewSize: CGSize = .zero
    /// Full window size — used for aspect ratio and sheet offset math.
    var windowSize: CGSize = .zero
    var safeArea: UIEdgeInsets = .init()
}

struct SheetWithInfo<Content: View, Sheet: View>: View {
    @Binding var isPresented: Bool
    @ViewBuilder var content: (SheetInfo) -> Content
    @ViewBuilder var sheet: (SheetInfo) -> Sheet
    @State private var info: SheetInfo = .init()
    var body: some View {
        Rectangle()
            .foregroundStyle(.clear)
            .overlay {
                content(info)
            }
            /// Prevents the base layout from shifting when the keyboard appears inside the sheet.
            .ignoresSafeArea(.keyboard, edges: .all)
            .onGeometryChange(for: CGSize.self, of: {
                $0.size
            }, action: { newValue in
                info.baseViewSize = newValue
            })
            .sheet(isPresented: $isPresented) {
                /// Reset on dismiss so isVisible becomes false and the content snaps back to full size.
                info.originY = nil
            } content: {
                sheet(info)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    /// SheetObserver is invisible — it only exists to hook into UIKit's view
                    /// hierarchy and start CADisplayLink tracking of the sheet's Y position.
                    .background(SheetObserver { offset in
                        info.originY = offset
                    })
            }
            .onAppear {
                /// GeometryReader can't reach window-level metrics directly.
                /// Grab window size and safe area once from the key window at appear time.
                if let appWindow = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow {
                    info.windowSize = appWindow.frame.size
                    info.safeArea = appWindow.safeAreaInsets
                }
            }
    }
}

private struct SheetObserver: UIViewRepresentable {
    var minY: (CGFloat) -> Void

    /// Inserts an invisible UIView as the sheet's background solely to gain access
    /// to the UIKit view hierarchy, then walks up to the sheet's container to observe it.
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        /// Deferred to next run loop tick because the view hasn't been inserted into
        /// the hierarchy yet when makeUIView runs — superview is nil at this moment.
        DispatchQueue.main.async {
            /// Walk up two levels out of SwiftUI's hosting wrappers to reach the
            /// actual UIKit sheet container — the view whose position we want to track.
            context.coordinator.startObserving(view.superview?.superview ?? view)
        }
        return view
    }

    func updateUIView(_: UIView, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator {
        var parent: SheetObserver
        init(parent: SheetObserver) {
            self.parent = parent
        }

        /// Stops the display link when this Coordinator is released.
        /// Without invalidate(), CADisplayLink keeps the run loop alive and keeps firing.
        deinit { displayLink?.invalidate() }

        /// Weak so Coordinator doesn't extend the sheet container's lifetime beyond its own.
        weak var observingView: UIView?
        var displayLink: CADisplayLink?

        func startObserving(_ view: UIView) {
            observingView = view
            /// CADisplayLink strongly retains its target — passing `self` directly creates a
            /// retain cycle (displayLink → Coordinator → displayLink), preventing deinit.
            /// WeakObserver is a trampoline that breaks the cycle (see below).
            displayLink = CADisplayLink(target: WeakObserver(target: self),
                                        selector: #selector(WeakObserver.onChange))
            displayLink?.add(to: .current, forMode: .common)
        }

        @MainActor @objc
        func onChange() {
            guard let view = observingView,
                  let presentation = view.layer.presentation()
            else {
                return
            }
            /// layer.presentation() returns the interpolated in-flight position during animation.
            /// view.layer.frame (the model layer) would already be at the final value — useless
            /// for tracking smooth frame-by-frame progress.
            let globalMinY = presentation.convert(presentation.frame, to: nil).origin.y
            parent.minY(globalMinY)
        }
    }

    /// Trampoline that holds a weak reference to Coordinator, breaking the CADisplayLink retain cycle.
    ///
    /// Retain graph:
    ///   CADisplayLink  --(strong)-->  WeakObserver
    ///   WeakObserver   --(weak)  -->  Coordinator  <--(strong)--  Coordinator.displayLink
    ///
    /// When the sheet dismisses and SwiftUI releases Coordinator:
    ///   1. Coordinator.deinit fires → invalidates the display link → stops firing
    ///   2. CADisplayLink releases WeakObserver
    ///   3. WeakObserver.target was weak → nothing retained, full cleanup
    class WeakObserver {
        weak var target: Coordinator?
        init(target: Coordinator? = nil) {
            self.target = target
        }

        @MainActor @objc
        func onChange() {
            target?.onChange()
        }
    }
}

#Preview {
    MockYouTubeSortsView()
}

/**
 # CADisplayLink

 A timer that fires in sync with the screen's refresh rate (60 fps standard, 120 fps on ProMotion).

 ```swift
 displayLink = CADisplayLink(target: someObject, selector: #selector(someMethod))
 displayLink?.add(to: .current, forMode: .common)
 ```

 Every time the screen is about to draw a new frame, the run loop calls the selector on your target.
 You're called ~60–120 times per second, perfectly aligned with the display hardware.

 # Why CADisplayLink instead of a regular Timer

 The sheet's originY must be read from layer.presentation() — the in-flight animation layer,
 not the model layer. This value changes every single frame during a drag or spring animation.

 A regular Timer fires on its own schedule, independent of rendering:
   - Missed frames — timer fires between redraws, values lag behind the screen
   - Wasted work   — timer fires even when nothing is animating

 CADisplayLink fires exactly once per frame draw — the layer position is read at the precise
 moment it's meaningful, no more, no less.

 Alternatives and why they don't work here:
   - Timer                          — wrong cadence, not display-synchronized
   - onGeometryChange / GeometryReader — reports the model layer (final value), not in-flight position
   - withAnimation completion          — only fires when animation ends, not at each intermediate frame

 # model layer vs presentation layer

 When an animation starts, UIKit immediately sets the model layer to its final value.
 layer.presentation() returns a copy reflecting the current on-screen (interpolated) state.
 Without presentation(), every read would snap to the destination, defeating the purpose.

 # CADisplayLink retain cycle — why WeakObserver is needed

 CADisplayLink strongly retains its target — this is unusual; most delegate patterns use weak.

 Naïve approach (creates a cycle):
   displayLink = CADisplayLink(target: self, selector: #selector(onChange))

   CADisplayLink → (strong) → Coordinator
   Coordinator   → (strong) → displayLink   ← cycle, neither can deallocate

 With WeakObserver (cycle broken):
   CADisplayLink → (strong) → WeakObserver
   WeakObserver  → (weak)   → Coordinator  ← (strong) ← Coordinator.displayLink

 WeakObserver has no reference back to displayLink, so there is no cycle.
 When SwiftUI releases Coordinator:
   1. Coordinator.deinit fires → displayLink.invalidate() → display link stops
   2. CADisplayLink releases WeakObserver
   3. WeakObserver.target was weak → fully deallocated, no leaks

 Without WeakObserver, Coordinator.deinit never fires because CADisplayLink holds it alive,
 making invalidate() unreachable — the display link leaks and keeps firing indefinitely.
 */
