//
//  SearchExpandable+CustomTabBar+iOS26.swift
//  animation
//
//  Created on 4/9/26.
//  Apple Fitness App
//
import SwiftUI

@available(iOS 26.0, *)
struct SearchExpandableCustomTabBarDemoView: View {
    @State private var select: String = "For You"
    @State private var searchText: String = ""
    @State private var isSearchExpanded: Bool = false
    @State private var isSearchActivated: Bool = false
    var body: some View {
        ScrollView(.vertical) {}
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 15) {
                    if !isSearchActivated {
                        HStack(spacing: 2) {
                            Image(systemName: "apple.logo")
                            Text("Fitness+")
                        }
                        .font(.largeTitle.bold())
                        .padding(.horizontal, 15)
                    }

                    /// custom tab bar
                    SearchExpandableCustomTabBar(
                        items: ["For You", "Explore", "Plans", "Library"],
                        selection: $select,
                        searchText: $searchText,
                        isSearchExpanded: $isSearchExpanded
                    ) { isKeyboardActive in
                        withAnimation(.snappy) {
                            isSearchActivated = isKeyboardActive
                        }
                    }
                }
            }
    }
}

@available(iOS 26.0, *)
struct SearchExpandableCustomTabBar: View {
    var items: [String]
    var searchHint: String = "Workouts, Trainers, Classes, and more..."
    @Binding var selection: String
    @Binding var searchText: String
    @Binding var isSearchExpanded: Bool
    var onSearchActivated: (Bool) -> Void

    /// Properties
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isKeyboardActive: Bool
    @State private var viewSize: CGSize = .zero
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(items, id: \.self) { item in
                    itemView(item)
                }
                expandableSearchBar()
            }
            .padding(.horizontal, 15)
            /// when search bar expanded, center the view
            .visualEffect { [isSearchExpanded, viewSize] content, proxy in
                let rect = proxy.frame(in: .scrollView)
                let maxX = rect.maxX - viewSize.width

                return content.offset(x: isSearchExpanded ? -maxX : 0)
            }
        }
        .frame(height: 50)
        .scrollDisabled(isSearchExpanded)
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .animation(animation, value: selection)
        .animation(animation, value: isKeyboardActive)
        .onChange(of: isKeyboardActive) { _, newValue in
            onSearchActivated(newValue)
        }
        .onGeometryChange(for: CGSize.self) {
            $0.size
        } action: { newValue in
            viewSize = newValue
        }
    }

    private func expandableSearchBar() -> some View {
        let horizontalPadding: CGFloat = 15
        let trailingTabSpacing: CGFloat = 12
        let trailingMinimizeButtonWidth: CGFloat = 60
        // Keep room for the trailing minimize button and the scroll view's horizontal padding
        // so the expanded search bar fills only the remaining visible width.
        let fitSearchBarWidth: CGFloat =
            viewSize.width - ((horizontalPadding * 2) + trailingTabSpacing + trailingMinimizeButtonWidth)
        let keyboardDismissButtonWidth: CGFloat = 45
        let keyboardDismissButtonSpacing: CGFloat = 12

        return ZStack(alignment: .trailing) {
            HStack(spacing: 0) {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .frame(width: isSearchExpanded ? 40 : 60)

                if isSearchExpanded {
                    TextField(searchHint, text: $searchText)
                        .focused($isKeyboardActive)
                }
            }
            .padding(.leading, isSearchExpanded ? 5 : 0)
            .padding(.trailing, isSearchExpanded ? 15 : 0)
            .frame(height: 45)
            .clipShape(.capsule)
            .glassEffect(.regular.interactive(), in: .capsule)
            .contentShape(.capsule)
            .gesture(
                TapGesture(count: 1).onEnded { _ in
                    withAnimation(animation) {
                        isSearchExpanded = true
                    }
                },
                isEnabled: !isSearchExpanded
            )
            .zIndex(1)
            // Reserve space for the trailing dismiss button so the text field does not sit under it.
            .padding(.trailing, isKeyboardActive ? keyboardDismissButtonWidth + keyboardDismissButtonSpacing : 0)

            Image(systemName: "xmark")
                .frame(width: 45, height: 45)
                .glassEffect(.regular.interactive(), in: .circle)
                .contentShape(.circle)
                .onTapGesture {
                    isKeyboardActive = false
                }
                .opacity(isKeyboardActive ? 1 : 0)
                .offset(x: isKeyboardActive ? 0 : 70)
                .zIndex(0)
        }
        .frame(width: isSearchExpanded ? fitSearchBarWidth : nil)
    }

    private func itemView(_ item: String) -> some View {
        let isSelected = selection == item
        let foregroundTint: Color = isSelected ? (colorScheme != .dark ? .white : .black) : .primary
        let backgroundTint: Color = isSelected ? (colorScheme == .dark ? .white : .black) : .clear
        let isLast = items.last == item && isSearchExpanded
        return ZStack {
            if isLast {
                /// minimize button
                Image(systemName: "circle.grid.2x2.fill")
                    .frame(width: 60, height: 45)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .contentShape(.capsule)
                    .onTapGesture {
                        isKeyboardActive = false
                        withAnimation(animation) {
                            isSearchExpanded = false
                        }
                    }
                    .padding(.leading, 12)
            } else {
                Text(item)
                    .padding(.horizontal, 15)
                    .frame(height: 45)
                    .foregroundStyle(foregroundTint)
                    .background(backgroundTint, in: .capsule)
                    .glassEffect(.regular.interactive(!isSearchExpanded), in: .capsule)
                    .contentShape(.capsule)
                    .onTapGesture {
                        selection = item
                    }
                    .disabled(isSearchExpanded)
            }
        }
    }

    private let animation: Animation = .interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0)
}

@available(iOS 26.0, *)
#Preview {
    SearchExpandableCustomTabBarDemoView()
}
