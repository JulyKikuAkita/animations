//
//  AnimatedKeyboard+iOS26.swift
//  animation
//
//  Created on 4/22/26.
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 26+ only — gated by `@available(iOS 26.0, *)`. Hard requirements:
//  Liquid Glass (`.buttonStyle(.glass)`), `ToolbarSpacer`,
//  `.toolbarTitleDisplayMode(.inlineLarge)`, and the project's
//  `ExpandableGlassMenuContainer` helper.
//
//  Note on reading order
//  ─────────────────────
//  This file already has TACTICAL `// Learning:` comments on most
//  lines — read those for the line-by-line walkthrough. The block
//  below is the STRATEGIC summary so you don't have to assemble
//  the picture from individual comments.
//
//  Learning point
//  ──────────────
//  Notes-app-style floating editor toolbar that expands as the
//  keyboard appears. One source of truth (`@FocusState
//  isKeyboardActive`) drives everything: a "Done" toolbar button
//  appears in the nav bar, a circular "compose" button at the
//  bottom-right fades/blurs/shrinks out, and a compact action row
//  morphs into a full horizontally-scrolling formatting toolbar.
//  All synchronised, no manual KVO of keyboard frame.
//
//  Three load-bearing mechanics:
//    1. `.safeAreaInset(edge: .bottom)` — SwiftUI auto-pushes the
//       inset content above the keyboard. Zero keyboard-tracking
//       code; the toolbar "just" stays pinned.
//    2. `ExpandableGlassMenuContainer(progress:labelSize:)` — the
//       project helper that morphs between a 220pt-wide `label`
//       slot (collapsed) and a full-width `content` slot (expanded).
//       Driven by a CGFloat 0→1 derived from the Bool focus state.
//    3. Two distinct animation curves on two distinct values:
//       • `.easeInOut(0.25)` on `isKeyboardActive` — for the
//         conditional "Done" toolbar button fade.
//       • `.interactiveSpring(response: 0.6, dampingFraction: 0.75)`
//         on the safeAreaInset — for the toolbar's layout shift.
//       Picking different curves per-property is the difference
//       between "it animates" and "it feels right."
//
//  Disappear-effect tip (line ~133)
//  ────────────────────────────────
//  The compose button uses opacity + blur + scale TOGETHER to fade
//  out instead of opacity alone. It's a small thing, but blur +
//  scale add motion-vocabulary that opacity can't carry on its own.
//  Worth copying for any "this control no longer applies" hide.
//
//  Key APIs
//  ────────
//  • `@FocusState` + `.focused(_:)` — the canonical pattern; bind
//    once, read/write everywhere.
//  • `.safeAreaInset(edge: .bottom, spacing: 0)` — auto-tracks
//    keyboard avoidance.
//  • `.toolbarTitleDisplayMode(.inlineLarge)` — iOS 26. Large title
//    that collapses inline as the user scrolls (Notes-app behavior).
//  • `ToolbarSpacer(.fixed, placement:)` — iOS 26. Fixed gap between
//    toolbar items; cleaner than a custom Spacer view.
//  • `.buttonStyle(.glass) + .buttonBorderShape(.circle)` — iOS 26
//    Liquid Glass material on a circular button.
//  • `ExpandableGlassMenuContainer` — project helper (defined
//    elsewhere); the actual collapse/expand morph engine.
//
//  How to apply
//  ────────────
//  Use this whenever a TextEditor or TextField has a contextual
//  toolbar — comments, message composers, in-app notes. Keep the
//  tactical `// Learning:` comments style (one short note per
//  non-obvious line) — it works well for demo code that doubles as
//  a teaching example.
//
//  See also
//  ────────
//  • View/Keyboard/* — sibling keyboard-aware demos.
//  • Helpers (search `ExpandableGlassMenuContainer`) — the helper
//    type wrapping the collapse/expand morph.
//
import SwiftUI

@available(iOS 26.0, *)
struct AnimatedKeyboardIOS26DemoView: View {
    @State private var text: String = ""

    // Learning: @FocusState is a two-way binding to a view's keyboard focus.
    // Setting `isKeyboardActive = false` programmatically dismisses the keyboard.
    // Reading it lets you drive animations and conditional UI from focus changes.
    @FocusState private var isKeyboardActive: Bool

    var body: some View {
        NavigationStack {
            TextEditor(text: $text)
                // Learning: .focused(_:) binds this view's focus state to our @FocusState var.
                // When the user taps the editor, `isKeyboardActive` becomes true automatically.
                .focused($isKeyboardActive)
                .scrollContentBackground(.hidden)
                .safeAreaPadding(15)
                .navigationTitle("Notes")
                // Learning: .inlineLarge is an iOS 26 display mode — the title starts large
                // and collapses inline as the user scrolls, similar to the native Notes app.
                .toolbarTitleDisplayMode(.inlineLarge)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Share", systemImage: "square.and.arrow.up") {}
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Options", systemImage: "ellipsis") {}
                    }

                    // Learning: ToolbarSpacer(.fixed, placement:) is new in iOS 26.
                    // It injects a fixed-size gap between toolbar items, useful for
                    // visually separating action groups without a custom spacer view.
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)

                    ToolbarItem(placement: .topBarTrailing) {
                        // Learning: Conditionally show a "Done" button only while the keyboard
                        // is active. The toolbar item slot stays reserved, so other items
                        // don't shift. The parent `.animation` below handles the transition.
                        if isKeyboardActive {
                            Button("Done", systemImage: "checkmark") {
                                isKeyboardActive = false
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.yellow)
                        }
                    }
                }
                // Learning: Value-based animation — SwiftUI re-renders the toolbar
                // with easeInOut whenever `isKeyboardActive` flips. This covers
                // the conditional Done button appearing/disappearing smoothly.
                .animation(.easeInOut(duration: 0.25), value: isKeyboardActive)
                // Learning: .safeAreaInset(edge: .bottom) inserts a view into the
                // safe area below the content. SwiftUI automatically pushes the
                // TextEditor up when the keyboard appears, so this toolbar stays
                // pinned just above the keyboard with zero extra work.
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    ZStack(alignment: .trailing) {
                        // Learning: GeometryReader captures the available width so we
                        // can pass exact dimensions into ExpandableGlassMenuContainer.
                        // Without it the container couldn't fill the full toolbar width.
                        GeometryReader {
                            let size = $0.size

                            // Learning: `progress` converts the Bool focus state into a
                            // 0→1 CGFloat. The container uses this to interpolate its
                            // width and content between collapsed and expanded states.
                            let progress: CGFloat = isKeyboardActive ? 1 : 0

                            // The label (collapsed) shows 220 pt of base action buttons.
                            let labelSize: CGSize = .init(width: 220, height: size.height)

                            // Learning: ExpandableGlassMenuContainer is a custom view that
                            // morphs between a compact `label` slot and a full-width `content`
                            // slot driven by `progress`. At progress=0 the label is shown;
                            // at progress=1 the full editor toolbar is revealed.
                            ExpandableGlassMenuContainer(
                                alignment: .center,
                                progress: progress,
                                labelSize: labelSize
                            ) {
                                // Expanded content: a horizontally scrollable row of editor actions.
                                // Learning: .scrollTargetBehavior(.viewAligned) snaps the scroll
                                // to view boundaries — each swipe reveals a clean set of buttons
                                // rather than stopping at arbitrary offsets.
                                ScrollView(.horizontal) {
                                    HStack(spacing: 30) {
                                        editorActions()
                                    }
                                    .font(.title3)
                                    .foregroundStyle(Color.primary)
                                    .scrollTargetLayout()
                                    .padding(.horizontal, 15)
                                }
                                .scrollTargetBehavior(.viewAligned)
                                .scrollIndicators(.hidden)
                                .frame(width: size.width, height: size.height)
                            } label: {
                                // Collapsed label: a compact row of the most-used actions.
                                HStack(spacing: 20) {
                                    baseActions()
                                }
                                .font(.title3)
                                .foregroundStyle(.primary)
                            }
                            .frame(height: 45)
                        }
                        .frame(height: 45)
                        .zIndex(1)

                        // Learning: Compose three modifiers to create a polished
                        // disappear effect when the keyboard opens:
                        //   .opacity  — fades the button out
                        //   .blur     — adds a soft defocus during the transition
                        //   .scaleEffect — shrinks it toward the center
                        // Together they feel more natural than opacity alone.
                        Button {} label: {
                            Image(systemName: "square.and.pencil")
                                .font(.title3)
                                .frame(width: 25, height: 35)
                        }
                        // Learning: .buttonStyle(.glass) and .buttonBorderShape(.circle)
                        // are iOS 26 Liquid Glass APIs. They render the button with the
                        // translucent, specular material used throughout the system UI.
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .opacity(isKeyboardActive ? 0 : 1)
                        .blur(radius: isKeyboardActive ? 5 : 0)
                        .scaleEffect(isKeyboardActive ? 0.5 : 1)
                    }
                    .padding(.horizontal, 15)
                    // Learning: Conditional bottom padding shifts the toolbar up slightly
                    // when the keyboard is visible, giving it breathing room above the keys.
                    .padding(.bottom, isKeyboardActive ? 10 : 0)
                    // Learning: .interactiveSpring is ideal for UI driven by user gestures
                    // or focus changes. `response` controls how snappy the spring feels;
                    // `dampingFraction` < 1 adds a gentle overshoot for a lively, physical feel.
                    // Use this instead of .easeInOut when the motion involves layout shifts.
                    .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.75), value: isKeyboardActive)
                }
        }
    }

    // Compact toolbar shown when the keyboard is hidden.
    func baseActions() -> some View {
        Group {
            Button("", systemImage: "checklist") {}
            Button("", systemImage: "paperclip") {}
            Button("", systemImage: "pencil.tip.crop.circle") {}
            Button("", systemImage: "apple.intelligence") {}
        }
    }

    // Full editor toolbar revealed when the keyboard is active.
    func editorActions() -> some View {
        Group {
            Button("", systemImage: "textformat.size") {}
            Button("", systemImage: "checklist") {}
            Button("", systemImage: "tablecells") {}
            Button("", systemImage: "paperclip") {}
            Button("", systemImage: "pencil.top.crop.circle") {}
            Button("", systemImage: "apple.intelligence") {}
            Button("", systemImage: "bold") {}
            Button("", systemImage: "italic") {}
            Button("", systemImage: "underline") {}
            Button("", systemImage: "strikethrough") {}
            Button("", systemImage: "pencil.line") {}
            Button("", systemImage: "link") {}
            Button("", systemImage: "increase.indent") {}
            Button("", systemImage: "decrease.indent") {}
            Button("", systemImage: "arrow.up.to.line") {}
            Button("", systemImage: "arrow.down.to.line") {}
        }
    }
}

@available(iOS 26.0, *)
#Preview {
    AnimatedKeyboardIOS26DemoView()
}
