//
//  ExpandableNavigationSearchBarView.swift
//  animation
//
//  Learning points / Demo goals:
//  • Build an iOS-Messages-style expandable nav bar: large title that scales on
//    pull-down, a search bar that morphs into a full-width focused input, and a
//    matched-geometry segmented picker.
//  • Pin the bar to the top while searching by cancelling the scroll offset.
//
//  Key SwiftUI APIs / patterns:
//  • `safeAreaInset(edge: .top)` — host a custom navigation bar that participates
//    in scroll layout (instead of `.toolbar`).
//  • `GeometryReader` + `.scrollView(axis:)` coordinate space — drive shrink/scale
//    progress from `minY`.
//  • `matchedGeometryEffect` — animate the active capsule between segmented tabs.
//  • Custom `ScrollTargetBehavior` — snap the header so it never rests mid-collapse.
//  • `contentMargins(.top, _, for: .scrollIndicators)` — keep the iOS scroll
//    indicator from drawing over the floating header.
//
//  Notable trick: the search bar's background uses *negative* paddings driven by
//  `progress` so it can grow to fill the safe-area + nav region when focused.

import SwiftUI

struct ExpandableNavigationSearchBarDemoView: View {
    var body: some View {
        NavigationStack {
            ExpandableNavigationSearchBarView()
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct ExpandableNavigationSearchBarView: View {
    /// View properties
    @State private var searchText: String = ""
    @State private var activeTab: SimpleTabs = .all
    @FocusState private var isSearching: Bool
    @Environment(\.colorScheme) private var scheme
    @Namespace private var animation
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 15) {
                DummyMessagesView(count: 20)
            }
            .safeAreaPadding(15)
            .safeAreaInset(edge: .top, spacing: 0) {
                expandableNavigationBar()
            }
            .animation(
                .snappy(duration: 0.3, extraBounce: 0),
                value: isSearching
            )
        }
        .scrollTargetBehavior(CustomScrollTargetBehavior())
        .background(.gray.opacity(0.15))
        .contentMargins(.top, 190, for: .scrollIndicators) // hide scroll indicator on header
    }

    // swiftlint:disable:next function_body_length
    func expandableNavigationBar(_ title: String = "Messages") -> some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            let scrollViewHeight = proxy.bounds(
                of: .scrollView(axis: .vertical))?.height ?? 0
            // Tip: only scale up on pull-down (minY > 0). Cap at +50% so the title
            // doesn't grow without bound; bottom-out at 1 so push-up never shrinks below 100%.
            let scaleProgress = minY > 0 ? 1 + (
                max(min(minY / scrollViewHeight, 1), 0) * 0.5) : 1
            // Tip: `randomValue` is the scroll distance (in pts) over which the
            // collapse animation completes. Smaller → snappier collapse.
            let randomValue: CGFloat = 70.0
            // When searching, force progress=1 so the bar morphs to the focused state
            // even without scroll input.
            let progress = isSearching ? 1 : max(min(-minY / randomValue, 1), 0)
            VStack(spacing: 10) {
                /// Title
                Text(title)
                    .font(.largeTitle.bold())
                    .scaleEffect(scaleProgress, anchor: .topLeading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 10)

                /// Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)

                    TextField("Search Conversations", text: $searchText)
                        .focused($isSearching)

                    if isSearching {
                        Button(action: {
                            isSearching = false
                        }, label: {
                            Image(systemName: "xmark")
                                .font(.title3)
                        })
                        .transition(
                            .asymmetric(
                                insertion: .push(from: .bottom),
                                removal: .push(from: .top)
                            )
                        )
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 15 - (progress * 15))
                .frame(height: 45)
                .background {
                    RoundedRectangle(cornerRadius: 25 - (progress * 25))
                        .fill(.background)
                        .shadow(color: .gray.opacity(0.25), radius: 5, x: 0, y: 5)
                        .padding(.top, -progress * 190)
                        .padding(.bottom, -progress * 65)
                        .padding(.horizontal, -progress * 15)
                }

                /// Custom Segmented Picker
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(SimpleTabs.allCases, id: \.rawValue) { tab in
                            Button(action: {
                                withAnimation(.snappy) {
                                    activeTab = tab
                                }
                            }) {
                                Text(tab.rawValue)
                                    .font(.callout)
                                    .foregroundStyle(
                                        activeTab == tab ? (
                                            scheme == .dark ? .black
                                                : .white) : Color.primary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 15)
                                    .background {
                                        // Tip: use `matchedGeometryEffect` with a single
                                        // shared id ("ACTIVETAB") so the filled capsule
                                        // appears to slide between tabs instead of
                                        // cross-fading.
                                        if activeTab == tab {
                                            Capsule()
                                                .fill(Color.primary)
                                                .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
                                        } else {
                                            Capsule()
                                                .fill(.background)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: 50)
            }
            .padding(.top, 25)
            .safeAreaPadding(.horizontal, 15)
            .offset(y: (minY < 0 || isSearching) ? -minY : 0) // pin nav bar on top when is searching
            .offset(y: -progress * 65)
        }
        .frame(height: 190) // fixed heights: sum of all navigation bar component
        .padding(.bottom, 10)
        .padding(.bottom, isSearching ? -65 : 0)
    }
}

private struct CustomScrollTargetBehavior: ScrollTargetBehavior {
    /// auto reset scroll animation to either finish or origin state
    /// otherwise the scroll will be state in the half transition view
    func updateTarget(_ target: inout ScrollTarget, context _: TargetContext) {
        if target.rect.minY < 70 {
            if target.rect.minY < 35 {
                target.rect.origin = .zero
            } else {
                target.rect.origin = .init(x: 0, y: 70)
            }
        }
    }
}

#Preview {
    ExpandableNavigationSearchBarDemoView()
}
