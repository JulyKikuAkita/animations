//
//  CustomSwipeActionScrollViewiOS18DemoView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 18+ — uses the native `.swipeActions` modifier on rows
//  inside a custom `ScrollView` (vs. the inside-a-`List` flavour).
//
//  Learning point
//  ──────────────
//  Smallest possible demo of native `.swipeActions` applied to
//  rows in a plain `ScrollView` (not a `List`). Rows are
//  `Rectangle()`s in a `LazyVStack`; each row gets three actions
//  (up, down, trash) with brand tints via the standard
//  `SwipeActionModel` wrapper.
//
//  Reading order
//  ─────────────
//  Read this first as the minimum-viable example, THEN read
//  [[SwipeActionDemoView]] for the bespoke `ScrollView`-based
//  custom-swipe pattern that doesn't rely on `.swipeActions` at
//  all. The two demos answer the question "do I really need to
//  build my own swipe machinery, or is the native modifier enough?"
//
//  Key APIs
//  ────────
//  • Native `.swipeActions` — iOS 18+ on custom scroll content
//    (was List-only earlier).
//  • `SwipeActionModel` — project helper at `Model/ActionModel.swift`;
//    bundles icon/tint/handler.
//
//  How to apply
//  ────────────
//  Reach for this when row actions need to be standard
//  iOS-system-feeling. For full custom drag-reveal mechanics, see
//  [[SwipeActionDemoView]].
//
//  See also
//  ────────
//  • SwipeActionDemoView.swift — bespoke swipe-to-reveal pattern
//    using `scrollTargetBehavior(.viewAligned)` + custom transitions.
//  • Model/ActionModel.swift — the `SwipeActionModel` data type.
//
import SwiftUI

struct CustomSwipeActionScrollViewiOS18DemoView: View {
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack {
                    ForEach(1 ... 100, id: \.self) { _ in
                        Rectangle()
                            .fill(.black.gradient)
                            .frame(height: 50)
                            .swipeActions {
                                SwipeActionModel(
                                    symbolImage: "square.and.arrow.up.fill",
                                    tint: .white,
                                    background: .blue
                                ) { resetPosion in
                                    resetPosion.toggle()
                                }

                                SwipeActionModel(
                                    symbolImage: "square.and.arrow.down.fill",
                                    tint: .white,
                                    background: .purple
                                ) { _ in
                                }

                                SwipeActionModel(
                                    symbolImage: "trash.fill",
                                    tint: .white,
                                    background: .red
                                ) { _ in
                                }
                            }
                    }
                }
                .padding(15)
            }
            .navigationTitle("Custom Swipe Actions")
        }
    }
}

#Preview {
    CustomSwipeActionScrollViewiOS18DemoView()
}
