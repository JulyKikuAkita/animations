//
//  ToastView+IOS18.swift
//  animation
//
//  Learning point
//  ──────────────
//  iOS-Notification-Center-style stacked, swipeable toasts.
//  Multiple toasts pile up at the bottom of the screen as a
//  fanned card stack; tap to expand into a vertical list; swipe
//  any individual toast left to dismiss it. Three layers of UI
//  affordance in one composition.
//
//  Three reusable mechanics
//  ────────────────────────
//    1. **`AnyLayout` ZStack ↔ VStack swap on tap** —
//       `let layout = isExpanded ? AnyLayout(VStackLayout(spacing: 10))
//                                 : AnyLayout(ZStackLayout())`
//       The same `layout { ForEach(...) }` block reformats from
//       a stacked-deck (ZStack) into a list (VStack) when tapped.
//       View identities (UUIDs) survive, so SwiftUI animates each
//       card from its stacked position to its list position with
//       the surrounding `.animation(.bouncy, value: isExpanded)`.
//    2. **Stacked-deck via `visualEffect` per-index transforms** —
//       In ZStack mode, each toast applies a scale + offsetY based
//       on its INDEX from the front:
//         scale  = 1 - min(index * 0.1, 1)
//         offsetY = -min(index * 15, 30)  (capped at 2 cards back)
//       Front-most card is full size at the bottom; cards behind
//       are smaller and stacked further up. Capping at 30pt /
//       index=2 prevents tall stacks from looking absurd.
//    3. **Swipe-to-dismiss with velocity boost** —
//       `let xOffset = value.translation.width + (value.velocity.width / 2)`
//       Adding HALF the velocity to the translation means a fast
//       fling counts as more displacement than a slow drag. So a
//       quick flick dismisses earlier than 200pt; a slow drag
//       has to actually reach 200pt. Feels like iOS native swipe.
//
//  The `isDeleting + .zIndex(1000)` trick
//  ──────────────────────────────────────
//      .zIndex(toast.isDeleting ? 1000 : 0)
//
//  When a toast is removed, we set `isDeleting = true` BEFORE
//  the animation fires (in `Binding<[ToastContentView]>.delete`).
//  The high zIndex ensures the OUTGOING toast renders ABOVE all
//  others during its `.transition(.move(edge: .leading))` exit —
//  otherwise it would slide BEHIND remaining cards in the stack
//  and look weird.
//
//  Asymmetric transition: enter from below, exit to leading
//  ────────────────────────────────────────────────────────
//      .transition(.asymmetric(
//          insertion: .offset(y: 100),
//          removal: .move(edge: .leading)))
//
//  New toasts slide UP from below the screen; dismissed toasts
//  slide LEFT off the side (matching the swipe direction). The
//  asymmetry maps to user expectation: things ARRIVE from the
//  bottom (like push notifications) and DEPART in the direction
//  the user swiped them.
//
//  Why a `Binding` extension for delete
//  ────────────────────────────────────
//      extension Binding<[ToastContentView]> {
//          func delete(_ id: String) {
//              if let toast = first(where: { $0.id == id }) {
//                  toast.wrappedValue.isDeleting = true
//              }
//              withAnimation(.bouncy) {
//                  self.wrappedValue.removeAll(where: { $0.id == id })
//              }
//          }
//      }
//
//  Encapsulates the two-step dance (set isDeleting → remove)
//  in one call site. `Binding<[ToastContentView]>` is iOS 17+'s
//  generic-binding-extension syntax; conforming via subscript
//  (`first(where:)` on `Binding<Array>`) preserves bindings to
//  individual elements.
//
//  Key APIs
//  ────────
//  • `AnyLayout(VStackLayout()) / AnyLayout(ZStackLayout())` —
//    runtime layout switching with preserved identities.
//  • `.visualEffect { content, _ in ... }` — per-index scale +
//    offset without GeometryReader.
//  • `.zIndex(_)` — promote outgoing toast above neighbours.
//  • `Binding<[Element]>` extension — operate on a binding to
//    an array (iOS 17+).
//  • `.animation(.bouncy, value: isExpanded)` — single-shot
//    spring driving the stack ↔ list reformat.
//
//  How to apply
//  ────────────
//  Use as the template for any "small notifications stack"
//  pattern: chat reactions, achievement badges, in-app push,
//  background-process status. The
//  `AnyLayout`-swap-with-preserved-identity is the architectural
//  win — each toast moves smoothly between two completely
//  different layouts without re-creation.
//
//  See also
//  ────────
//  • LiquidGlassToastView+IOS26.swift — single-toast iOS 26
//    variant with environment-injected show/dismiss.
//  • InlineToastView.swift — in-flow form-validation toasts
//    (different category entirely).
//

import SwiftUI

struct ToastDemoView: View {
    @State private var toasts: [ToastContentView] = []
    var body: some View {
        NavigationStack {
            List {
                Text("Demo view")
            }
            .navigationTitle("Toasts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Show") {
                        showToast()
                    }
                }
            }
        }
        .interactiveToasts($toasts)
    }

    func showToast() {
        withAnimation(.bouncy) {
            let toast = ToastContentView { id in
                toastView(id)
            }
            toasts.append(toast)
        }
    }

    @ViewBuilder
    func toastView(_ id: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "square.and.arrow.up.fill")

            Text("Hello World!")
                .font(.callout)

            Spacer(minLength: 0)

            Button {
                $toasts.delete(id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
            }
        }
        .foregroundStyle(Color.primary)
        .padding(.vertical, 12)
        .padding(.leading, 15)
        .padding(.trailing, 10)
        .background {
            Capsule()
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 3, x: -1, y: -3)
                .shadow(color: .black.opacity(0.06), radius: 2, x: 1, y: 3)
        }
        .padding(.horizontal, 15)
    }
}

// iOS18
private struct ToastViewiOS18: View {
    @Binding var toasts: [ToastContentView]
    /// View Properties
    @State private var isExpanded: Bool = false
    var body: some View {
        ZStack(alignment: .bottom) {
            if isExpanded { /// toast view will switch from zstack to vstack when tapped thus use is_expanded
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isExpanded = false
                    }
            }

            /// AnyLayout will seamlessly update it's layout and items with animations
            let layout = isExpanded ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(ZStackLayout())
            layout {
                ForEach($toasts) { $toast in
                    // reverse index to show stack of cards effect
                    let index = (toasts.count - 1) - (toasts.firstIndex(where: { $0.id == toast.id }) ?? 0)
                    toast.content
                        .offset(x: toast.offsetX)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let xOffset = value.translation.width < 0 ? value.translation.width : 0
                                    toast.offsetX = xOffset
                                }.onEnded { value in
                                    // Tip: velocity-boosted dismissal threshold.
                                    // `translation + velocity/2` means a fast
                                    // flick counts as more displacement than a
                                    // slow drag — a quick swipe dismisses
                                    // before reaching 200pt; a slow drag must
                                    // actually reach 200pt. Feels like iOS
                                    // native swipe-to-dismiss.
                                    let xOffset = value.translation.width + (
                                        value.velocity
                                            .width / 2)

                                    if -xOffset > 200 {
                                        /// Remove toast
                                        $toasts.delete(toast.id)
                                    } else {
                                        /// Reset toast to it's initial position
                                        withAnimation {
                                            toast.offsetX = 0
                                        }
                                    }
                                }
                        )
                        .visualEffect { [isExpanded] content, _ in
                            content
                                .scaleEffect(isExpanded ? 1 : scale(index), anchor: .bottom)
                                .offset(y: isExpanded ? 0 : offsetY(index))
                        }
                        .zIndex(toast.isDeleting ? 1000 : 0)
                        .frame(maxWidth: .infinity)
                        .transition(
                            .asymmetric(
                                insertion: .offset(y: 100),
                                removal: .move(edge: .leading)
                            )
                        )
                }
            }
            .onTapGesture {
                isExpanded.toggle()
            }
            .padding(.bottom, 15)
        }
        .animation(.bouncy, value: isExpanded)
        .onChange(of: toasts.isEmpty) { _, newValue in
            if newValue {
                isExpanded = false
            }
        }
    }

    nonisolated func offsetY(_ index: Int) -> CGFloat {
        let offset = min(CGFloat(index) * 15, 30) /// 30 CGFloat is 2 toasts height
        return -offset
    }

    nonisolated func scale(_ index: Int) -> CGFloat {
        let scale = min(CGFloat(index) * 0.1, 1)
        return 1 - scale
    }
}

#Preview {
    ToastDemoView()
}

struct ToastContentView: Identifiable {
    /// id: help to remove toast from view
    private(set) var id: String = UUID().uuidString
    var content: AnyView

    /// View Properties
    var offsetX: CGFloat = 0
    var isDeleting: Bool = false // set zindex to avoid push back to stacj

    init(@ViewBuilder content: @escaping (String) -> some View) {
        self.content = .init(content(id))
    }
}

extension View {
    @ViewBuilder
    func interactiveToasts(_ toasts: Binding<[ToastContentView]>) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                ToastViewiOS18(toasts: toasts)
            }
    }
}

/// use binding to trigger animation effect
extension Binding<[ToastContentView]> {
    func delete(_ id: String) {
        if let toast = first(where: { $0.id == id }) {
            toast.wrappedValue.isDeleting = true
        }
        withAnimation(.bouncy) {
            self.wrappedValue.removeAll(where: { $0.id == id })
        }
    }
}
