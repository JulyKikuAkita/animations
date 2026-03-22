//
//  ResizableHeaderIOS26View.swift
//  animation
//
//  Created on 3/22/26.
//  Telegram app resizable header
// When create a sticky view with LazyVStack,
// attach the LazyVstack to the safeAreaInset
// to avoid lazyVStack unloads views that move outside its visitbale bounds
// during scrolling or laytout changes
//
import SwiftUI

struct ResizableHeaderDemoView: View {
    @State private var safeAreaTopValue: CGFloat = 0
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Header Scroll Effect") {
                    Group {
                        /// Instead of hiding the default navigation bar,
                        /// we keep it to get the back button + swipe to dismiss feature
                        /// but adjust top inset to hide an additional blank space of the navigation bar
                        if #available(iOS 26, *) {
                            TelegrameHeaderDemoView()
                                .scrollEdgeEffectHidden(true, for: .top)
                        } else {
                            TelegrameHeaderDemoView()
                        }
                    }
                    .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                    .safeAreaPadding(.top, safeAreaTopValue)
                    .ignoresSafeArea(.all, edges: .top)
                }
            }
            .navigationTitle("Telegram")
        }
        .onGeometryChange(for: CGFloat.self) {
            $0.safeAreaInsets.top
        } action: { newValue in
            safeAreaTopValue = newValue
        }
    }
}

struct TelegrameHeaderDemoView: View {
    @State private var isLargeHeader: Bool = false
    @State private var topInset: CGFloat = 0
    @State private var scrollPhase: ScrollPhase = .idle
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack {
                /// Note: do NOT attach ResizableHeaderIOS26View here;  attach to safeAreaInset
                Text("Hello")
            }
            .padding(.bottom, 1000)
            .safeAreaInset(edge: .top, spacing: 0) {
                ResizableHeaderIOS26View(
                    isLargeHeader: $isLargeHeader,
                    topInset: $topInset
                )
            }
        }
        .background(.fill.tertiary)
        /// Reading top inset value
        .onScrollGeometryChange(for: CGFloat.self) {
            $0.contentInsets.top
        } action: { _, newValue in
            topInset = newValue
        }
        /// Activating large header based on scroll offset and scorll interaction type
        .onScrollGeometryChange(for: CGFloat.self) {
            $0.contentOffset.y + $0.contentInsets.top
        } action: { _, newValue in
            if scrollPhase == .interacting {
                withAnimation(.snappy(duration: 0.2, extraBounce: 0)) {
                    // Do NOT use 0, use -10 to trigger large header
                    isLargeHeader = newValue < -10 || (isLargeHeader && newValue < 0)
                }
            }
        }
        .onChange(of: isLargeHeader) { _, newValue in
            print(newValue)
        }
        /// Reading current scroll interaction type
        .onScrollPhaseChange { _, newPhase in
            scrollPhase = newPhase
        }
    }
}

/// Custom Telegram style header
struct ResizableHeaderIOS26View: View {
    @Binding var isLargeHeader: Bool
    @Binding var topInset: CGFloat
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack(spacing: 12) {
            Rectangle()
                .foregroundStyle(.clear)
                .frame(width: 100, height: isLargeHeader ? 300 : 100)
                .clipShape(.circle)

            VStack(spacing: 20) {
                customNavigationBar()
                    .foregroundStyle(isLargeHeader ? .white : .primary)
                headerActions()
                    .foregroundStyle(isLargeHeader ? .white : .blue)
                    .geometryGroup()
            }
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 15)
        .background(alignment: .top) {
            /// Resizable logo view
            GeometryReader {
                let size = $0.size
                let minY = $0.frame(in: .global).minY
                let topOffset = isLargeHeader ? minY : 0

                logoView()
                    .frame(width: size.width, height: size.height + topOffset)
                    .clipShape(.rect(cornerRadius: isLargeHeader ? 0 : 50))
                    .offset(y: -topOffset)
            }
            .frame(width: isLargeHeader ? nil : 100,
                   height: isLargeHeader ? nil : 100)
        }
        .padding(.top, 15)
    }

    private func logoView() -> some View {
        ZStack {
            Rectangle()
                .fill(.black)
            Image(systemName: "apple.logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.white)
                .frame(height: isLargeHeader ? 200 : 55)
                // sum height of (navigation bar + custom actions) / 2 = 70
                .offset(y: isLargeHeader ? -70 : 0)
        }
    }

    private func customNavigationBar() -> some View {
        VStack(alignment: isLargeHeader ? .leading : .center, spacing: 6) {
            Text("Apple Development")
                .font(.title)
                .fontWeight(.semibold)

            Text("133 Members, 13 Online")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: isLargeHeader ? .leading : .center)
        .visualEffect { content, proxy in
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            let progress = max(min(minY / 50, 1), 0)
            return content
                .scaleEffect(0.7 + (0.3 * progress))
                .offset(y: minY < 0 ? -minY : 0)
        }
        .background(customNavigationBarBackground())
        .zIndex(1000)
    }

    private func customNavigationBarBackground() -> some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            let opacity: CGFloat = 1.0 - max(min(minY / 50, 1), 0)
            let tint: Color = colorScheme == .dark ? Color.black : Color.white

            ZStack {
                if #available(iOS 26, *) {
                    Rectangle()
                        .fill(.clear)
                        /// apply glass effect for softer transition
                        .glassEffect(.clear.tint(tint.opacity(0.8)), in: .rect)
                        /// create progress blur effect
                        .mask {
                            LinearGradient(colors: [
                                .black,
                                .black,
                                .black,
                                .black,
                                .black.opacity(0.5),
                                .clear,
                            ], startPoint: .top, endPoint: .bottom)
                        }
                } else {
                    Rectangle()
                        .fill(tint)
                        /// create progress blur effect
                        .mask {
                            LinearGradient(colors: [
                                .black,
                                .black,
                                .black.opacity(0.9),
                                .black.opacity(0.4),
                                .clear,
                            ], startPoint: .top, endPoint: .bottom)
                        }
                }
            }
            .padding(-20)
            .padding(.top, -topInset)
            .offset(y: -minY)
            .opacity(opacity)
        }
        .allowsHitTesting(false)
    }

    private func headerActions() -> some View {
        HStack(spacing: 6) {
            CustomActionButton(isLargeHeader: isLargeHeader, icon: "bell.fill", title: "Mute")
            CustomActionButton(isLargeHeader: isLargeHeader, icon: "magnifyingglass", title: "Search")
            CustomActionButton(isLargeHeader: isLargeHeader, icon: "rectangle.portrait.and.arrow.forward", title: "Leave")
            CustomActionButton(isLargeHeader: isLargeHeader, icon: "ellipsis", title: "More")
        }
    }
}

private struct CustomActionButton: View {
    var isLargeHeader: Bool
    var icon: String
    var title: String
    var onTap: () -> Void = {}
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(height: 30)

                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.background)
                        .opacity(isLargeHeader ? 0 : 1)

                    RoundedRectangle(cornerRadius: 15)
                        .fill(.ultraThinMaterial)
                        .opacity(isLargeHeader ? 0.8 : 0)
                        .environment(\.colorScheme, .dark)
                }
            }
            .contentShape(.rect)
        }
    }
}

#Preview {
    ResizableHeaderDemoView()
}
