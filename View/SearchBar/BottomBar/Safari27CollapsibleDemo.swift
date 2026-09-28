//
//  Safari27CollapsibleDemo.swift
//  animation
//
//  Created on 9/27/26.

import SwiftUI

@available(iOS 26.0, *)
struct Safari27CollapsibleDemo: View {
    @State private var safeArea: EdgeInsets = .init()
    @State private var text: String = ""
    @State private var isMinimized: Bool = false
    @FocusState private var isFocused: Bool
    /// Interactive scroll to minimize/maximize bottom bar properties
    @State private var progress: CGFloat = 0
    @GestureState private var isDragging: Bool = false
    var body: some View {
        ScrollView(.vertical) {
            Rectangle()
                .foregroundStyle(.clear)
                .frame(height: 2000)
        }
        // auto-dismiss keyboard when scroll
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(.rect)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isDragging) { _, out, _ in
                    out = true
                }.onEnded { value in
                    onGestureEnd(value: value)
                }
        )
        .onScrollGeometryChange(for: CGFloat.self) {
            $0.contentOffset.y + $0.contentInsets.top
        } action: { oldValue, newValue in
            guard isDragging else { return }
            handleScroll(oldValue: oldValue, newValue: newValue)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CollapsibleBottomBar27Style(
                safeArea: safeArea,
                text: $text,
                isMinimized: $isMinimized,
                progress: $progress,
                isFocused: $isFocused
            ) {
                SFBAction(symbol: "chevron.left") {}

                SFBAction(symbol: "chevron.right") {}

                SFBAction(symbol: "square.and.arrow.up") {}

                SFBAction(symbol: "bookmark") {}

                SFBAction(symbol: "square.on.square") {}
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .onGeometryChange(for: EdgeInsets.self) {
            $0.safeAreaInsets
        } action: { newValue in
            safeArea = newValue
        }
    }

    private func handleScroll(oldValue: CGFloat, newValue: CGFloat) {
        guard !isFocused else { return }
        let delta = (newValue - oldValue) / transitionDistance
        let progress = max(0, progress + (isMinimized ? -delta : delta))
        if progress >= 1 {
            withAnimation(.iSpring()) {
                isMinimized.toggle()
                self.progress = 0
            }
        } else {
            self.progress = progress
        }
    }

    private func onGestureEnd(value: DragGesture.Value) {
        guard !isFocused else { return }
        let velocity = -value.velocity.height * 0.1
        let velocityProgress = velocity / transitionDistance

        let progress = progress + (isMinimized ? -velocityProgress : velocityProgress)
        withAnimation(.iSpring()) {
            if progress >= 0.5 { // customizable
                isMinimized.toggle()
            }
            self.progress = 0
        }
    }

    /// customizable
    private var transitionDistance: CGFloat {
        120
    }
}

struct SFBAction: Identifiable {
    private(set) var id: String = UUID().uuidString
    var symbol: String
    var action: () -> Void
}

@resultBuilder
struct SFBActionBuilder {
    static func buildBlock(_ actions: SFBAction...) -> [SFBAction] {
        actions
    }
}

@available(iOS 26.0, *)
struct CollapsibleBottomBar27Style: View {
    var safeArea: EdgeInsets
    @Binding var text: String
    @Binding var isMinimized: Bool
    @Binding var progress: CGFloat
    @FocusState.Binding var isFocused: Bool
    @SFBActionBuilder var actions: [SFBAction]
    /// View Properties
    let padding: CGFloat = 18
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        VStack(spacing: isMinimized ? 0 : 10) {
            ZStack {
                if isMinimized {
                    Text(text.isEmpty ? "Search here" : text)
                        .font(isMinimized ? .caption : .body)
                        .foregroundStyle(text.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                        .padding(.horizontal, 20)
                } else {
                    Capsule()
                        .fill(.clear)
                }
            }
            .frame(height: isMinimized ? 35 : 45)

            HStack(spacing: 0) {
                ForEach(actions) { action in
                    actionView(action)
                }
            }
            .compositingGroup()
            .opacity(isMinimized ? 0 : 1)
            .blur(radius: isMinimized ? 10 : 0)
            .frame(
                width: isMinimized ? 0 : nil,
                height: isMinimized ? 0 : nil,
                alignment: .top
            )
            .padding(.horizontal, isMinimized ? 0 : -15)
        }
        .geometryGroup()
        .padding(isMinimized ? 0 : padding)
        .clipShape(.rect(cornerRadius: 30)) // match ConcentricRectangle
        .overlay {
            if isMinimized {
                Rectangle()
                    .foregroundStyle(.clear)
                    .contentShape(.rect)
                    .onTapGesture {
                        isMinimized = false
                    }
                    .transition(.identity)
            }
        }
        .glassEffect(
            .regular.interactive(isMinimized),
            in: ConcentricRectangle(corners: .concentric(minimum: .fixed(30)),
                                    isUniform: true)
        )
        .animation(.iSpring().speed(1.5)) {
            $0.opacity(isFocused ? 0 : 1)
        }
        .overlay(alignment: isFocused ? .bottom : .top) {
            searchBar()
                .padding(isFocused || isMinimized ? 0 : padding)
                .opacity(isMinimized ? 0 : 1)
                .allowsHitTesting(!isMinimized)
        }
        .padding([.horizontal, .bottom], padding)
        .scaleEffect(1 + (isMinimized ? 0.1 : -0.1) * progress, anchor: .bottom)
        .frame(minWidth: isMinimized ? 180 : nil)
        .animation(.iSpring(), value: isMinimized)
    }

    private func searchBar() -> some View {
        ZStack(alignment: .leading) {
            Image(systemName: "magnifyingglass")
                .font(.callout)
                .opacity(isFocused ? 0 : 1)

            TextField("Search here", text: $text)
                .padding(.leading, isFocused ? 0 : 30)
        }
        .padding(.horizontal, 15)
        .frame(height: isMinimized ? 35 : 45)
        .background {
            if colorScheme == .dark {
                Capsule()
                    .fill(.black)
            } else {
                Capsule()
                    .fill(.regularMaterial)
            }
        }
        .tint(Color.white)
        .environment(\.colorScheme, .dark)
        .padding(.trailing, isFocused ? 55 : 0)
        .background(alignment: .trailing) {
            Button {
                isFocused = false
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 20, height: 30)
            }
            .buttonStyle(.glass)
            .animation(.iSpring().speed(2)) {
                $0.opacity(isFocused ? 1 : 0)
            }
        }
        .focused($isFocused)
        // adjust with keyboard
        .offset(y: isFocused ? -safeArea.bottom : 0)
        .animation(.iSpring(), value: isFocused)
    }

    private func actionView(_ item: SFBAction) -> some View {
        Button(action: item.action) {
            Image(systemName: item.symbol)
                .font(.title3)
                .frame(width: 45, height: 45)
                .foregroundStyle(.primary)
                .contentShape(.rect)
        }
        .frame(maxWidth: .infinity)
    }
}

@available(iOS 26.0, *)
#Preview {
    Safari27CollapsibleDemo()
}
