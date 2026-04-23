//
//  AnimatedKeyboard+iOS26.swift
//  animation
//
//  Created on 4/22/26.
//
// Learning: Animate a floating toolbar that expands when the keyboard appears,
// mimicking the Notes app behavior on iOS 26.
// Key techniques:
//   - @FocusState drives all UI transitions from a single source of truth
//   - .safeAreaInset keeps the toolbar pinned above the keyboard automatically
//   - ExpandableGlassMenuContainer morphs between a compact and full-width toolbar
//   - Layered animations (spring for layout, easeInOut for toolbar items)

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
