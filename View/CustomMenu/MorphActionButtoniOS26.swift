//
//  MorphActionButtoniOS26.swift
//  animation
//
//  Created on 6/24/25.
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  TODO: Filename mismatch
//        The `iOS26` suffix is misleading — this file uses NO
//        iOS 26-only APIs (no `@available(iOS 26.0, *)`, no
//        `.glassEffect`, no `.matchedTransitionSource`). It's
//        iOS 16+ compatible. Either drop the `iOS26` suffix or add
//        iOS 26 enhancements (Liquid Glass surface, zoom transition)
//        to justify the name.
//
//  TODO: Typo in inline comment below — `morthButtonOverlay` should
//        be `morphButtonOverlay`. Internal-only; just fix the
//        comment when convenient.
//
//  Learning point
//  ──────────────
//  FAB → fullscreen morph: tap a small action button and it
//  expands into a fullscreen panel via `.fullScreenCover`. Two
//  innovations on the standard fullscreen-cover pattern:
//
//    1. `MorphingButton(label:content:expandedContent:)` takes
//       THREE ViewBuilders. `content` is the initial sheet content
//       (e.g. a confirmation prompt); `expandedContent` is what's
//       revealed AFTER a follow-up interaction (e.g. a detailed form).
//       Both swap via `.transition(.blurReplace)` for a soft
//       in-cover content swap.
//    2. The cover is opened inside a `Transaction(disablesAnimations: true)`
//       so iOS's default sheet-rise animation is suppressed — the
//       morph from button rect → fullscreen rect is the ONLY motion
//       the user sees.
//
//  Inline comment on the demo: "the morphButtonOverlay works in
//  list, section, overlay" — reminding callers that the trigger
//  button is layout-agnostic. The geometry capture uses
//  `onGeometryChange` + `geometryGroup()` so the morph anchor stays
//  correct even when the source button is inside a List row.
//
//  Key APIs
//  ────────
//  • `.fullScreenCover(isPresented:)` — the presentation surface;
//    deliberately neutered with `Transaction.disablesAnimations`.
//  • `onGeometryChange(for: CGRect.self)` — captures the source
//    button's frame for the morph anchor.
//  • `geometryGroup()` — keeps geometry stable inside the morph;
//    without it, child layouts shift mid-animation.
//  • `.transition(.blurReplace)` — content↔expandedContent swap.
//  • `Transaction(disablesAnimations: true) + withTransaction`
//    — the cover-suppression trick.
//
//  How to apply
//  ────────────
//  Use when an action needs CONFIRMATION + DETAIL on the same
//  surface (delete with confirm-and-form, share with picker, etc.).
//  Stay with the inline-overlay pattern (see [[ExpandableMenuiOS26DemoView]])
//  for lighter-weight cases.
//
//  See also
//  ────────
//  • PopOutMenuView.swift — sibling using `.fullScreenCover` +
//    drag-to-dismiss. Picks the same overlay vs. menu trade-off
//    differently.
//  • AnimatedConfirmationButtonDemoView.swift (View/Button) —
//    same FAB-to-fullscreen morph but uses an `ImageRenderer`
//    snapshot for the source instead of a live geometry frame.
//    Compare for which approach to copy.
//  • ExpandableMenuiOS26DemoView.swift — inline-overlay alternative
//    in the same folder.
//
import SwiftUI

/// the morphButtonOverlay works in list, section, overlay
struct MorphActionButtonDemo: View {
    @State private var showExpandedContent: Bool = false
    var body: some View {
        NavigationStack {
            List {
                Section("Dummy Section") {
                    HStack {
                        morthButtonOverlay()
                        DummyTaskRow(isEmpty: true)
                    }
                }
            }
            .navigationTitle("Morphing Button")
        }
        .overlay(alignment: .bottomTrailing) {
            morthButtonOverlay()
        }
    }

    func morthButtonOverlay() -> some View {
        MorphingButton(
            backgroundColor: .black,
            showExpandedContent: $showExpandedContent
        ) {
            Image(systemName: "plus")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.background)
                .frame(width: 45, height: 45)
        } content: {
            DummyMenuView()
                .onTapGesture {
                    showExpandedContent.toggle()
                }
        } expandedContent: {
            dummyExpandedView()
        }
        .padding(.trailing, 20)
    }

    func dummyExpandedView() -> some View {
        VStack {
            HStack {
                Text("Expanded View")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer(minLength: 0)

                Button {
                    showExpandedContent = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                }
            }
            .padding(.leading, 10)

            Spacer()

            DummyRectangles(color: .indigo, count: 5)
        }
        .foregroundStyle(.background)
        .padding(15)
    }
}

struct MorphingButton<Label: View, Content: View, ExpandedContent: View>: View {
    var backgroundColor: Color
    @Binding var showExpandedContent: Bool
    @ViewBuilder var label: Label
    @ViewBuilder var content: Content
    @ViewBuilder var expandedContent: ExpandedContent

    /// View Properties
    ///  use full screen instead of overlay so that the MorphingButton can apply to any view
    @State private var showFullScreenCover: Bool = false
    @State private var animateContent: Bool = false
    @State private var viewPosition: CGRect = .zero
    var body: some View {
        label
            .background(backgroundColor)
            .clipShape(.circle)
            .contentShape(.circle)
            .onGeometryChange(for: CGRect.self, of: {
                $0.frame(in: .global)
            }, action: { newValue in
                viewPosition = newValue
            })
            .opacity(showFullScreenCover ? 0 : 1)
            .onTapGesture {
                toggleFullScreenCover(false, status: true)
            }
            .fullScreenCover(isPresented: $showFullScreenCover) {
                ZStack(alignment: .topLeading) {
                    if animateContent {
                        ZStack(alignment: .top) {
                            if showExpandedContent {
                                expandedContent
                                    .transition(.blurReplace)
                            } else {
                                content
                                    .transition(.blurReplace)
                            }
                        }
                        .transition(.blurReplace)
                    } else {
                        label
                            .transition(.blurReplace)
                    }
                }
                /// animatino the group view (by default, each leaf view has its animation)
                .geometryGroup()
                .clipShape(.rect(cornerRadius: 30, style: .continuous))
                .background {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(backgroundColor)
                        .ignoresSafeArea()
                }
                .padding(
                    .horizontal,
                    animateContent && !showExpandedContent ? 15 : 0
                )
                .padding(.bottom, animateContent && !showExpandedContent ? 5 : 0)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: animateContent ? .bottom : .topLeading
                )
                .offset(
                    x: animateContent ? 0 : viewPosition.minX,
                    y: animateContent ? 0 : viewPosition.minY
                )
                .ignoresSafeArea(animateContent ? [] : .all)
                .background {
                    Rectangle()
                        .fill(.black.opacity(animateContent ? 0.05 : 0))
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.interpolatingSpring(duration: 0.2, bounce: 0),
                                          completionCriteria: .removed)
                            {
                                animateContent = false
                            } completion: {
                                /// Removing sheet after a little delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    toggleFullScreenCover(false, status: false)
                                }
                            }
                        }
                }
                .task {
                    try? await Task.sleep(for: .seconds(0.05))
                    withAnimation(.interpolatingSpring(duration: 0.2, bounce: 0)) {
                        animateContent = true
                    }
                }
                .animation(
                    .interpolatingSpring(duration: 0.2, bounce: 0),
                    value: showExpandedContent
                )
            }
    }

    /// Transation: adds new view on top of parent view immediately without any animations
    /// the existing full cover sliding animation has been removed
    private func toggleFullScreenCover(_ withAnimation: Bool, status: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = !withAnimation

        withTransaction(transaction) {
            showFullScreenCover = status
        }
    }
}

#Preview {
    MorphActionButtonDemo()
}
