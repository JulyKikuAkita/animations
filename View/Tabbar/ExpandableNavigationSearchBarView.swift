//
//  ExpandableNavigationSearchBarView.swift
//  animation

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
                DummyMessagesView()
            }
            .safeAreaPadding(15)
            .safeAreaInset(edge: .top, spacing: 0) {
                ExpandableNavigationBar()
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
    
    /// Expandable Navigation Bar
    @ViewBuilder
    func ExpandableNavigationBar(_ title: String = "Messages") -> some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            let scrollViewHeight = proxy.bounds(
                of: .scrollView(axis: .vertical))?.height ?? 0
            // scale title size
            let scaleProgress = minY > 0 ? 1 + (
                max(min(minY / scrollViewHeight, 1), 0) * 0.5) : 1
            let randomValue:CGFloat = 70.0 // any value, the lower, the faster scrolling animation
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
                        ForEach(SimpleTabs.allCases, id:\.rawValue) { tab in
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
            .offset(y: (minY < 0  || isSearching) ? -minY : 0) // pin nav bar on top when is searching
            .offset(y: -progress * 65)
        }
        .frame(height: 190) // fixed heights: sum of all navigation bar component
        .padding(.bottom, 10)
        .padding(.bottom, isSearching ? -65 : 0)
    }
    
    /// Dummy messages View
    @ViewBuilder
    func DummyMessagesView() -> some View {
        ForEach(0..<20, id: \.self) { _ in
            HStack(spacing: 12) {
                Circle()
                    .frame(width: 55, height: 55)
                
                VStack(alignment: .leading, spacing: 6, content: {
                    Rectangle()
                        .frame(width: 140, height: 8)
                    
                    Rectangle()
                        .frame(height: 8)
                    
                    Rectangle()
                        .frame(width: 80, height: 8)
                })
            }
            .foregroundStyle(.gray.opacity(0.4))
            .padding(.horizontal, 15)
        }
    }
}

struct CustomScrollTargetBehavior: ScrollTargetBehavior {
    /// auto reset scroll animation to either finish or origin state
    /// otherwise the scroll will be state in the half transition view
    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
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
