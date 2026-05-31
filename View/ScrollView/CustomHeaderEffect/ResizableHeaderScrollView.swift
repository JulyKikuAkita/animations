//
//  ResizableHeaderScrollView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 18+ — depends on the behaviour change where ScrollView
//  and a custom `DragGesture` recognise SIMULTANEOUSLY. Pre-iOS 18,
//  only one wins. No `@available(iOS 18, *)` gate currently;
//  consider adding one.
//
//  Inline tip (preserved):
//    iOS 18 API: ScrollView and Gesture can work seamlessly;
//    prior to iOS 18, only either one works.
//
//  Learning point
//  ──────────────
//  Header-collapsing scroll view driven by a SIMULTANEOUS
//  `DragGesture(minimumDistance: 10)` riding alongside the scroll's
//  own pan. The gesture translation drives the header's `.offset(y:)`
//  while `onScrollGeometryChange` clamps the offset between full
//  size and collapsed. The user feels one continuous drag even
//  though two gesture systems are firing in parallel.
//
//  Why simultaneous gestures matter
//  ────────────────────────────────
//  A bare `DragGesture` would steal events from the ScrollView's
//  internal pan, freezing scroll. iOS 18's default-simultaneous
//  behaviour for these gestures is what makes the pattern viable.
//
//  Key APIs
//  ────────
//  • `DragGesture(minimumDistance: 10)` simultaneous with scroll
//    — load-bearing.
//  • `onScrollGeometryChange` — canonical scroll offset feed.
//  • `safeAreaInset(edge: .top)` — pins the collapsing header above
//    the content.
//
//  How to apply
//  ────────────
//  Use when the header should COLLAPSE on each drag tick (smooth
//  feel). For snap-on-settle instead, see [[ResizableHeaderIOS26View]].
//
//  See also
//  ────────
//  • ResizableHeaderIOS26View.swift — iOS 26 sibling using
//    `.glassEffect` + snap-on-phase-change.
//  • ResizableHeaderScrollViewiOS26.swift — generic patterns
//    (filename misleads — no iOS 26 APIs).
//  • ScrollToHideHeaderView.swift — minimal hide-on-scroll variant.
//
import SwiftUI

struct ResizableHeaderScrollViewDemo: View {
    @State private var selectedType: OSInfo = .airPod
    @Namespace private var animation
    var body: some View {
        ResizableHeaderScrollView {
            HStack(spacing: 12) {
                Button {} label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }

                Spacer(minLength: 0)

                Button {} label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                }

                Button {} label: {
                    Image(systemName: "bubble")
                        .font(.title3)
                }
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 15)
            .padding(.top, 15)
        } stickyHeader: {
            ScrollView(.horizontal, content: {
                HStack(spacing: 10) {
                    ForEach(OSInfo.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: type.symbolImage)
                                .transition(.blurReplace(.downUp))
//                            Text(type.rawValue)
                        }
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .foregroundStyle(selectedType == type ? .white : .gray)
                        .frame(height: 30)
                        .background {
                            if selectedType == type {
                                Capsule()
                                    .fill(.blue.gradient)
                                    .matchedGeometryEffect(id: "ACTIVEPILL", in: animation)
                            }
                        }
                        .contentShape(.rect)
                        .onTapGesture {
                            withAnimation(.snappy) {
                                selectedType = type
                            }
                        }
                    }
                }
            })
            .scrollIndicators(.hidden)
            .scrollPosition(id: .init(get: {
                selectedType
            }, set: { _ in
            }), anchor: .center)
            .safeAreaPadding(15)
            .padding(.top, 10)
        } headerBackground: {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .bottom) {
                    Divider()
                }
        } content: {
            VStack(spacing: 15) {
                ForEach(1 ... 100, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.gray.opacity(0.35))
                        .frame(height: 50)
                }
            }
            .padding(15)
        }
    }
}

struct ResizableHeaderScrollView<Header: View,
    StickyHeader: View,
    HeaderBackground: View,
    Content: View>: View
{
    var spacing: CGFloat = 10
    @ViewBuilder var header: Header
    @ViewBuilder var stickyHeader: StickyHeader
    @ViewBuilder var headerBackground: HeaderBackground
    @ViewBuilder var content: Content

    /// View Properties
    @State private var currentDragOffset: CGFloat = 0
    @State private var previousDragOffset: CGFloat = 0
    @State private var headerOffset: CGFloat = 0
    @State private var headerSize: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ScrollView(.vertical) {
            content
        }
        .onScrollGeometryChange(for: CGFloat.self, of: {
            $0.contentOffset.y + $0.contentInsets.top
        }, action: { _, newValue in
            scrollOffset = newValue
        })
        .frame(maxWidth: .infinity)
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    /// the offset starts with 0
                    let dragOffset = max(0, abs(value.translation.height) - 50) *
                        (value.translation.height < 0 ? -1 : 1)
                    previousDragOffset = currentDragOffset
                    currentDragOffset = dragOffset
                    let deltaOffset = (currentDragOffset - previousDragOffset).rounded()
                    headerOffset = max(min(headerOffset + deltaOffset, headerSize), 0)
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        /// prevent gap when scroll view interaction stops
                        if headerOffset > (headerSize * 0.5), scrollOffset > headerSize {
                            headerOffset = headerSize
                        } else {
                            headerOffset = 0
                        }
                    }
                    /// reset
                    previousDragOffset = 0
                    currentDragOffset = 0
                }
        )
        .safeAreaInset(edge: .top, spacing: spacing) {
            combinedHeaderView()
        }
    }

    private func combinedHeaderView() -> some View {
        VStack(spacing: spacing) {
            header
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: { newValue in
                    /// spacing is optional
                    headerSize = newValue + spacing
                }

            stickyHeader
        }
        .offset(y: -headerOffset)
        .clipped()
        .background {
            headerBackground
                .ignoresSafeArea()
                .offset(y: -headerOffset)
        }
    }
}

#Preview {
    ResizableHeaderScrollViewDemo()
}
