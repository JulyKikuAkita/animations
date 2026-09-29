//
//  Safari27CollapsibleDemo.swift
//  animation
//
//  Created on 9/27/26.
//
//  Learning points / Demo goals:
//  • Mimic Safari's (iOS 26+) bottom bar: a full bar with search field + action
//    row that collapses into a compact pill on scroll, re-expands on tap, and
//    hands the search field off to the keyboard when focused.
//  • Interactive, *gesture-driven* collapse — not a phase snap. `progress`
//    accumulates scroll deltas / `transitionDistance` and only drives the
//    scaleEffect; the state flip happens when progress crosses a threshold.
//  • Three independent state machines layered on one container:
//    scroll progress (continuous) → isMinimized (discrete) → isFocused
//    (relocates the field). Each owns a disjoint set of modifiers.
//
//  Key APIs / patterns:
//  • `@FocusState.Binding` — the *parent* owns focus even though only the child
//    has the TextField, because `handleScroll`/`onGestureEnd` must `guard
//    !isFocused` (never collapse while the user is typing). A plain
//    `@Binding<Bool>` will not compile against `.focused(_:)`.
//  • `@GestureState private var isDragging` — auto-resets to false on gesture
//    end, so `onScrollGeometryChange` can ignore momentum/decelerating scroll
//    and only integrate progress during an active finger-down drag.
//  • `.overlay(alignment: isFocused ? .bottom : .top)` — the search field is an
//    overlay on the glass container, not a child of it. Flipping alignment is
//    what lets the field visually *detach* and dock above the keyboard while
//    the bar itself fades out underneath.
//  • `.animation(_:body:)` (iOS 17+) — scopes an animation to one property
//    (`$0.opacity(isFocused ? 0 : 1)`) so the bar's fade is independent of the
//    `.animation(_:value: isMinimized)` collapse driving everything else.
//  • `.geometryGroup()` — the VStack changes spacing, padding, and two frames at
//    once; without this each resolves independently and the collapse tears.
//  • `.compositingGroup()` before `.blur`/`.opacity` on the action row — blurs
//    the row as one flattened image instead of five seams.
//  • `frame(width:/height: isMinimized ? 0 : nil)` + `.opacity` rather than
//    `if !isMinimized` — keeps view identity so the row animates to zero
//    instead of popping out of the hierarchy.
//  • `ConcentricRectangle(corners: .concentric(minimum: .fixed(30)))` (iOS 26) —
//    corner radius derived from the enclosing container's curvature, floored at
//    30pt. `.clipShape(.rect(cornerRadius: 30))` is the approximation used for
//    the *clip*, since concentric shapes aren't available there.
//  • `.glassEffect(.regular.interactive(isMinimized))` — interactivity is gated
//    on state so the glass only responds to touch while it's acting as a pill.
//  • `.environment(\.colorScheme, .dark)` + `.tint(.white)` on the field —
//    forces light-on-dark chrome regardless of system appearance.
//
//  Notable:
//  • `isMinimized ? -delta : delta` inverts the gesture's meaning by state: the
//    same upward drag collapses an expanded bar and expands a collapsed one.
//  • `onGestureEnd` projects `velocity * 0.1` into progress space, so a fast
//    flick commits the toggle at 0.5 that a slow drag would not.
//  • `safeArea` is measured in the parent (`onGeometryChange`) and passed down
//    because the parent sets `.ignoresSafeArea(.all, edges: .bottom)` — the
//    child can no longer read a meaningful bottom inset itself, and needs it to
//    offset the field by `-safeArea.bottom`.
//  • The transparent `Rectangle` tap target uses `.transition(.identity)` so the
//    hit-test layer appears instantly rather than fading in with the collapse.
//
//  Gotcha: `SFBAction.id` is a fresh `UUID()` per init, and the result builder
//  re-runs on every parent `body` pass — so `ForEach` sees new identities each
//  render. Harmless for static symbol buttons, but any per-action transition or
//  matched-geometry work would need a stable id first.

import SwiftUI

@available(iOS 26.0, *)
struct Safari27CollapsibleDemo: View {
    @State private var safeArea: EdgeInsets = .init()
    @State private var text: String = ""
    @State private var isMinimized: Bool = false
    @FocusState private var isFocused: Bool
    /// Interactive scroll to minimize/maximize bottom bar properties
    @State private var progress: CGFloat = 0
    @GestureState private var isDragging: Bool = false
    var body: some View {
        ScrollView(.vertical) {
            Rectangle()
                .foregroundStyle(.clear)
                .frame(height: 2000)
        }
        // auto-dismiss keyboard when scroll
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(.rect)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isDragging) { _, out, _ in
                    out = true
                }.onEnded { value in
                    onGestureEnd(value: value)
                }
        )
        .onScrollGeometryChange(for: CGFloat.self) {
            $0.contentOffset.y + $0.contentInsets.top
        } action: { oldValue, newValue in
            guard isDragging else { return }
            handleScroll(oldValue: oldValue, newValue: newValue)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CollapsibleBottomBar27Style(
                safeArea: safeArea,
                text: $text,
                isMinimized: $isMinimized,
                progress: $progress,
                isFocused: $isFocused
            ) {
                SFBAction(symbol: "chevron.left") {}

                SFBAction(symbol: "chevron.right") {}

                SFBAction(symbol: "square.and.arrow.up") {}

                SFBAction(symbol: "bookmark") {}

                SFBAction(symbol: "square.on.square") {}
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .onGeometryChange(for: EdgeInsets.self) {
            $0.safeAreaInsets
        } action: { newValue in
            safeArea = newValue
        }
    }

    private func handleScroll(oldValue: CGFloat, newValue: CGFloat) {
        guard !isFocused else { return }
        let delta = (newValue - oldValue) / transitionDistance
        let progress = max(0, progress + (isMinimized ? -delta : delta))
        if progress >= 1 {
            withAnimation(.iSpring()) {
                isMinimized.toggle()
                self.progress = 0
            }
        } else {
            self.progress = progress
        }
    }

    private func onGestureEnd(value: DragGesture.Value) {
        guard !isFocused else { return }
        let velocity = -value.velocity.height * 0.1
        let velocityProgress = velocity / transitionDistance

        let progress = progress + (isMinimized ? -velocityProgress : velocityProgress)
        withAnimation(.iSpring()) {
            if progress >= 0.5 { // customizable
                isMinimized.toggle()
            }
            self.progress = 0
        }
    }

    /// customizable
    private var transitionDistance: CGFloat {
        120
    }
}

struct SFBAction: Identifiable {
    private(set) var id: String = UUID().uuidString
    var symbol: String
    var action: () -> Void
}

@resultBuilder
struct SFBActionBuilder {
    static func buildBlock(_ actions: SFBAction...) -> [SFBAction] {
        actions
    }
}

@available(iOS 26.0, *)
struct CollapsibleBottomBar27Style: View {
    var safeArea: EdgeInsets
    @Binding var text: String
    @Binding var isMinimized: Bool
    @Binding var progress: CGFloat
    @FocusState.Binding var isFocused: Bool
    @SFBActionBuilder var actions: [SFBAction]
    /// View Properties
    let padding: CGFloat = 18
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        VStack(spacing: isMinimized ? 0 : 10) {
            ZStack {
                if isMinimized {
                    Text(text.isEmpty ? "Search here" : text)
                        .font(isMinimized ? .caption : .body)
                        .foregroundStyle(text.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                        .padding(.horizontal, 20)
                } else {
                    Capsule()
                        .fill(.clear)
                }
            }
            .frame(height: isMinimized ? 35 : 45)

            HStack(spacing: 0) {
                ForEach(actions) { action in
                    actionView(action)
                }
            }
            .compositingGroup()
            .opacity(isMinimized ? 0 : 1)
            .blur(radius: isMinimized ? 10 : 0)
            .frame(
                width: isMinimized ? 0 : nil,
                height: isMinimized ? 0 : nil,
                alignment: .top
            )
            .padding(.horizontal, isMinimized ? 0 : -15)
        }
        .geometryGroup()
        .padding(isMinimized ? 0 : padding)
        .clipShape(.rect(cornerRadius: 30)) // match ConcentricRectangle
        .overlay {
            if isMinimized {
                Rectangle()
                    .foregroundStyle(.clear)
                    .contentShape(.rect)
                    .onTapGesture {
                        isMinimized = false
                    }
                    .transition(.identity)
            }
        }
        .glassEffect(
            .regular.interactive(isMinimized),
            in: ConcentricRectangle(corners: .concentric(minimum: .fixed(30)),
                                    isUniform: true)
        )
        .animation(.iSpring().speed(1.5)) {
            $0.opacity(isFocused ? 0 : 1)
        }
        .overlay(alignment: isFocused ? .bottom : .top) {
            searchBar()
                .padding(isFocused || isMinimized ? 0 : padding)
                .opacity(isMinimized ? 0 : 1)
                .allowsHitTesting(!isMinimized)
        }
        .padding([.horizontal, .bottom], padding)
        .scaleEffect(1 + (isMinimized ? 0.1 : -0.1) * progress, anchor: .bottom)
        .frame(minWidth: isMinimized ? 180 : nil)
        .animation(.iSpring(), value: isMinimized)
    }

    private func searchBar() -> some View {
        ZStack(alignment: .leading) {
            Image(systemName: "magnifyingglass")
                .font(.callout)
                .opacity(isFocused ? 0 : 1)

            TextField("Search here", text: $text)
                .padding(.leading, isFocused ? 0 : 30)
        }
        .padding(.horizontal, 15)
        .frame(height: isMinimized ? 35 : 45)
        .background {
            if colorScheme == .dark {
                Capsule()
                    .fill(.black)
            } else {
                Capsule()
                    .fill(.regularMaterial)
            }
        }
        .tint(Color.white)
        .environment(\.colorScheme, .dark)
        .padding(.trailing, isFocused ? 55 : 0)
        .background(alignment: .trailing) {
            Button {
                isFocused = false
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 20, height: 30)
            }
            .buttonStyle(.glass)
            .animation(.iSpring().speed(2)) {
                $0.opacity(isFocused ? 1 : 0)
            }
        }
        .focused($isFocused)
        // adjust with keyboard
        .offset(y: isFocused ? -safeArea.bottom : 0)
        .animation(.iSpring(), value: isFocused)
    }

    private func actionView(_ item: SFBAction) -> some View {
        Button(action: item.action) {
            Image(systemName: item.symbol)
                .font(.title3)
                .frame(width: 45, height: 45)
                .foregroundStyle(.primary)
                .contentShape(.rect)
        }
        .frame(maxWidth: .infinity)
    }
}

@available(iOS 26.0, *)
#Preview {
    Safari27CollapsibleDemo()
}
