//
//  PullToSearchTextfieldDemoView.swift
//  animation
//
//  Created on 5/31/25.
//
// How to get offset of the scrollView:
// iOS 17+: onGeomtryChange
// iOS 18+: onScrollGeometryChange
//
// Get notify when Scroll is released?
// use a custom scrollTargetBehavior to serve as a callback to scrollViewWillEndDragging

import SwiftUI

struct PullToSearchTextfieldDemoView: View {
    @State private var offsetY: CGFloat = 0
    @FocusState private var isExpanded: Bool

    /// covert offset Y to progress
    var progress: CGFloat {
        max(min(offsetY / 100, 1), 0)
    }

    var body: some View {
        ScrollView(.vertical) {
            dummyScrollContent()
                .offset(y: isExpanded ? -offsetY : 0)
                /// attch to the root scroll content
                .onGeometryChange(for: CGFloat.self) {
                    $0.frame(in: .scrollView(axis: .vertical)).minY
                } action: { newValue in
                    offsetY = newValue
                }
        }
        .overlay {
            /// blur overlay when search is active
            Rectangle()
                .fill(.ultraThinMaterial)
                .background(.background.opacity(0.25))
                .ignoresSafeArea()
                .overlay {
                    ExpandedSearchResultListView(isExpanded: isExpanded)
                        .offset(y: isExpanded ? 0 : 70)
                        .opacity(isExpanded ? 1 : 0)
                        .allowsHitTesting(isExpanded)
                }
                .opacity(isExpanded ? 1 : progress)
        }
        .safeAreaInset(edge: .top) {
            headerView()
        }
        .scrollTargetBehavior(OnScrollEnd { deltaY in
            if offsetY > 100 || (-deltaY > 1.5 && offsetY > 0) {
                isExpanded = true
            }
        })
        /// try non sprint animation: easeIn out etc
        .animation(.interpolatingSpring(duration: 0.2), value: isExpanded)
    }

    func headerView() -> some View {
        HStack(spacing: 20) {
            if !isExpanded {
                Button {} label: {
                    Image(systemName: "slider.horizontal.below.square.filled.and.square")
                        .font(.title3)
                }
            }

            TextField("Search...", text: .constant(""))
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background {
                    ZStack {
                        Rectangle()
                            .fill(.gray.opacity(0.2))

                        Rectangle()
                            .fill(.ultraThinMaterial)
                    }
                    .clipShape(.rect(cornerRadius: 15))
                }
                .focused($isExpanded)

            Button {} label: {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
            }
            .opacity(isExpanded ? 0 : 1)
            .overlay(alignment: .trailing) {
                Button("Cancel") {
                    isExpanded = false
                }
                .fixedSize()
                .opacity(isExpanded ? 1 : 0)
            }
            .padding(.leading, isExpanded ? 20 : 0)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 15)
        .padding(.top, 10)
        .padding(.bottom, 5)
        .background {
            Rectangle()
                .fill(.background) // same bg as scrollView bg
                .ignoresSafeArea()
                // hiding bk when search bar is expanded
                .opacity(progress == 0 && !isExpanded ? 1 : 0)
        }
    }

    func dummyScrollContent() -> some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.blue.gradient)

                RoundedRectangle(cornerRadius: 15)
                    .fill(.indigo.gradient)

                RoundedRectangle(cornerRadius: 20)
                    .fill(.yellow)

                RoundedRectangle(cornerRadius: 25)
                    .fill(.pink)
            }
            .frame(height: 60)

            VStack(alignment: .leading, spacing: 25) {
                Text("Favotites")
                    .foregroundStyle(.gray)

                Text(dummyDescription)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(.top, 30)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background {
            Rectangle()
                .fill(.indigo.opacity(0.1))
                .opacity(progress == 0 && !isExpanded ? 1 : 0)
        }
    }
}

#Preview {
    PullToSearchTextfieldDemoView()
}

struct OnScrollEnd: ScrollTargetBehavior {
    var onEnd: (CGFloat) -> Void
    func updateTarget(_: inout ScrollTarget, context: TargetContext) {
        let deltaY = context.velocity.dy
        DispatchQueue.main.async {
            onEnd(deltaY)
        }
    }
}

/// error prone when combine List view in if condition + transitinon
/// workaround by only retain the list container but remove the list items
///  to achieve smooth transtion animation effect + also not compromising on performance
struct ExpandedSearchResultListView: View {
    var isExpanded: Bool

    var body: some View {
        List {
            if isExpanded {
                ForEach(sectionData, id: \.color) { section in
                    Section(section.colorName) {
                        ForEach(section.items, id: \.self) { index in
                            HStack(spacing: 10) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(section.colorGradient)
                                    .frame(width: 40, height: 40)

                                Text("Search Item No: \(index)")
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 12, leading: 0, bottom: 12, trailing: 0))
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .clipped()
    }

    // Helper: Define section data
    private var sectionData: [SearchSection] {
        let colors: [Color] = [.pink, .orange, .indigo, .yellow]
        return colors.map { SearchSection(color: $0, items: Array(1 ... 5)) }
    }

    // Data structure
    private struct SearchSection {
        let color: Color
        let items: [Int]

        var colorName: String {
            String(describing: color)
        }

        var colorGradient: LinearGradient {
            LinearGradient(gradient: Gradient(colors: [color, .white]),
                           startPoint: .top,
                           endPoint: .bottom)
        }
    }
}
